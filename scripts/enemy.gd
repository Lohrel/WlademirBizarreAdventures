## Classe base para todos os inimigos no jogo.
## Gerencia estados de IA, movimento, detecção e lógica de combate.
class_name Enemy
extends CharacterBody2D

# --- Sinais ---
signal enemy_died

# --- Enums ---
enum State { IDLE, WANDER, ALERT, AGGRESSIVE, ATTACK }

# --- Atributos Exportados (para serem sobrescritas ou escalonados) ---
@export_group("Base Stats")
@export var health: float = 50.0
@export var attack_damage: float = 15.0
@export var move_speed: float = 80.0
@export var chase_speed: float = 150.0
@export var is_living: bool = true

@export_group("AI Config")
@export var wander_radius: float = 80.0
@export var alert_to_aggro_time: float = 1.5
@export var suspicion_drain_time: float = 8.0
@export var aggro_loss_time: float = 5.0
@export var drop_chance: float = 0.35

# --- Variáveis de Tempo de Execução ---

var current_state: State = State.IDLE
var suspicion: float = 0.0 # 0.0 a 1.0 (Nível de alerta)
var out_of_sight_timer: float = 0.0
var player: CharacterBody2D = null
var last_known_player_pos: Vector2
var target_wander_pos: Vector2
var wander_timer: float = 0.0
var spawn_pos: Vector2
var _is_charging: bool = false
var _last_strafe_dir: Vector2 = Vector2.ZERO

# --- Nós Onready ---
@onready var sprite = $Sprite2D
@onready var anim_player = $AnimationPlayer
@onready var raycast = $RayCast2D
@onready var detection_area = $DetectionArea
@onready var hitbox = $Hitbox
@onready var attack_timer = $AttackTimer

# --- Cenas ---
var bone_scene = preload("res://scenes/bone_particles.tscn")
var item_drop_scene = preload("res://scenes/item_drop.tscn")
var damage_indicator_scene = preload("res://scenes/damage_indicator.tscn")

# --- Ciclo de Vida ---

func _ready():
	# Configuração inicial
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	spawn_pos = global_position
	target_wander_pos = spawn_pos
	
	_find_player()
	_apply_level_scaling()
	
	# Conexões de sinais
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if not player: 
		_find_player()
		return
	
	_process_ai_state(delta)
	
	move_and_slide()
	_handle_collision_avoidance()
	_animate()

# --- Lógica de IA ---

## Escalona vida e dano baseados no nível atual da masmorra.
func _apply_level_scaling():
	var gen = get_tree().root.find_child("LevelGenerator", true, false)
	if gen and "current_level" in gen:
		# Escalona atributos em 15% por nível começando do nível 2
		var mult = pow(1.15, gen.current_level - 1)
		health *= mult
		attack_damage *= mult

## Localiza o nó do jogador no grupo "player".
func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		# O jogador geralmente está dentro de um invólucro, encontre o CharacterBody2D
		if players[0].has_node("player"):
			player = players[0].get_node("player")
		else:
			player = players[0]

## Lógica principal da máquina de estados da IA.
func _process_ai_state(delta: float):
	var in_range = detection_area.overlaps_body(player)
	var has_los = _check_line_of_sight(in_range)
	
	match current_state:
		State.IDLE, State.WANDER:
			if in_range and has_los:
				current_state = State.ALERT
				_visual_jump()
			else:
				_handle_wandering(delta)
		
		State.ALERT:
			_handle_alert(delta, in_range, has_los)

		State.AGGRESSIVE:
			_handle_aggressive(delta, in_range, has_los)

		State.ATTACK:
			# Fica parado enquanto ataca
			velocity = velocity.move_toward(Vector2.ZERO, 10.0)

## Verifica se há obstáculos entre o inimigo e o jogador.
func _check_line_of_sight(in_range: bool) -> bool:
	if not in_range: return false
	
	raycast.target_position = to_local(player.global_position)
	raycast.force_raycast_update()
	
	var has_los = not raycast.is_colliding()
	if has_los:
		last_known_player_pos = player.global_position
		
	return has_los

## Lógica para o estado ALERTA: aumenta gradualmente a suspeita até tornar-se AGRESSIVO.
func _handle_alert(delta: float, in_range: bool, has_los: bool):
	if in_range and has_los:
		suspicion += delta / alert_to_aggro_time
		if suspicion >= 1.0:
			suspicion = 1.0
			current_state = State.AGGRESSIVE
		velocity = velocity.move_toward(Vector2.ZERO, 10.0)
	else:
		# Reduz a suspeita se o jogador for perdido
		suspicion -= delta / suspicion_drain_time
		if suspicion <= 0:
			suspicion = 0
			current_state = State.IDLE
		
		# Move-se em direção à última posição conhecida
		var dist = global_position.distance_to(last_known_player_pos)
		if dist > 15:
			var dir = (last_known_player_pos - global_position).normalized()
			velocity = dir * move_speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 10.0)

## Lógica para o estado AGGRESSIVE: persegue o jogador ou permanece agressivo por um tempo.
func _handle_aggressive(delta: float, in_range: bool, has_los: bool):
	var dist = global_position.distance_to(player.global_position)
	
	# Ataca se estiver ao alcance, o cooldown tiver acabado e tiver linha de visão
	var attack_range = _get_attack_range()
	if dist < attack_range and has_los and attack_timer.is_stopped() and not _is_charging:
		current_state = State.ATTACK
		_perform_attack()
		return

	if in_range and has_los:
		out_of_sight_timer = 0
		_chase_player()
	else:
		out_of_sight_timer += delta
		if out_of_sight_timer >= aggro_loss_time:
			current_state = State.ALERT
		
		if not has_los and in_range:
			_strafe_for_los(delta)
		else:
			_chase_player()

## Tenta contornar obstáculos quando perde a visão do jogador.
func _strafe_for_los(_delta: float):
	if raycast.is_colliding():
		var normal = raycast.get_collision_normal()
		# Direção perpendicular à colisão para "espiar" na esquina
		var strafe_dir = Vector2(-normal.y, normal.x)
		
		# Mantém a direção de strafe anterior se for similar para evitar oscilação
		if _last_strafe_dir != Vector2.ZERO and strafe_dir.dot(_last_strafe_dir) < 0:
			strafe_dir = -strafe_dir
			
		_last_strafe_dir = strafe_dir
		velocity = velocity.move_toward(strafe_dir * chase_speed, chase_speed * 0.1)
	else:
		# Se o raio não está colidindo mas não temos LoS (ex: fora do alcance do raio),
		# move-se para a última posição conhecida.
		var dir = (last_known_player_pos - global_position).normalized()
		velocity = velocity.move_toward(dir * chase_speed, chase_speed * 0.1)

## Lógica para os estados IDLE/WANDER: move-se aleatoriamente ao redor do ponto de spawn.
func _handle_wandering(delta: float):
	suspicion = 0 
	wander_timer -= delta
	
	if wander_timer <= 0:
		# Escolhe um novo destino aleatório
		var rand_offset = Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
		target_wander_pos = spawn_pos + rand_offset
		wander_timer = randf_range(2, 5)
		current_state = State.WANDER
	
	if current_state == State.WANDER:
		var dist = global_position.distance_to(target_wander_pos)
		if dist < 10:
			current_state = State.IDLE
			velocity = Vector2.ZERO
		else:
			var dir = (target_wander_pos - global_position).normalized()
			velocity = dir * move_speed

## Persegue o jogador mantendo uma pequena distância.
func _chase_player():
	_last_strafe_dir = Vector2.ZERO
	var dist = global_position.distance_to(player.global_position)
	var target_dir = (player.global_position - global_position).normalized()
	
	var min_dist = _get_min_chase_dist()
	
	if dist < min_dist:
		# Mantém distância
		var separation_dir = -target_dir
		velocity = velocity.move_toward(separation_dir * move_speed, chase_speed * 0.2)
	elif dist < min_dist + 10:
		# No alcance ideal
		velocity = velocity.move_toward(Vector2.ZERO, chase_speed * 0.1)
	else:
		# Aproxima-se
		velocity = velocity.move_toward(target_dir * chase_speed, chase_speed * 0.1)

# --- Visuais e Animações ---

func _animate():
	# Inverte o sprite baseado no movimento ou na posição do jogador
	if current_state in [State.ALERT, State.AGGRESSIVE, State.ATTACK] and player:
		var dir_to_player = player.global_position.x - global_position.x
		if dir_to_player != 0:
			sprite.flip_h = dir_to_player < 0
	elif velocity.length() > 5:
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

	# Reproduz animações
	if current_state == State.ATTACK and anim_player.has_animation("attack"):
		anim_player.play("attack")
	elif velocity.length() > 5:
		anim_player.play("walk")
	else:
		anim_player.play("idle")

func _visual_jump():
	var jump_height = _get_jump_height()
	var tween = create_tween()
	tween.tween_property(sprite, "position:y", -jump_height, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

# --- Métodos de Combate (para serem sobrescritas para comportamentos específicos) ---

func _perform_attack():
	# Ataque de investida padrão
	var lunge_dist = _get_lunge_dist()
	var tween = create_tween()
	var target_pos = global_position + (player.global_position - global_position).normalized() * lunge_dist
	tween.tween_property(self, "global_position", target_pos, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	hitbox.monitoring = true
	await get_tree().create_timer(0.2).timeout
	hitbox.monitoring = false
	
	attack_timer.start()

func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO, knockback_strength: float = 300.0, is_crit: bool = false):
	if amount > 0:
		var indicator = damage_indicator_scene.instantiate()
		get_parent().add_child(indicator)
		indicator.global_position = global_position + Vector2(0, -20)
		
		var color = Color(1, 1, 0.4) # Amarelo padrão
		if is_crit:
			color = Color(1, 0.5, 0.1) # Laranja para crítico
			indicator.scale = Vector2(1.5, 1.5)
			
		indicator.setup(str(int(amount)), color)
	
	health -= amount
	if current_state != State.ATTACK:
		current_state = State.AGGRESSIVE
	suspicion = 1.0
	
	# Aplica knockback se uma posição de origem for fornecida
	if source_pos != Vector2.ZERO:
		var knock_dir = (global_position - source_pos).normalized()
		velocity = knock_dir * knockback_strength

	# Feedback de partículas
	var bone = bone_scene.instantiate()
	get_parent().add_child(bone)
	bone.global_position = global_position
	bone.scale = _get_bone_particle_scale()
	bone.emitting = true
	get_tree().create_timer(bone.lifetime).timeout.connect(bone.queue_free)

	# Feedback de flash
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	
	# Feedback de impacto na escala
	var tween_scale = create_tween()
	var base_scale = sprite.scale
	tween_scale.tween_property(sprite, "scale", base_scale * 1.2, 0.05)
	tween_scale.tween_property(sprite, "scale", base_scale, 0.1)

	if health <= 0:
		die()

func die():
	enemy_died.emit()
	
	if randf() < drop_chance:
		call_deferred("_spawn_drop")
		
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.finished.connect(queue_free)

func _spawn_drop():
	var drop = item_drop_scene.instantiate()

	# 50% chance for equipment, 50% for health potion
	if randf() < 0.5:
		var gen = get_tree().root.find_child("LevelGenerator", true, false)
		var level = 1
		if gen and "current_level" in gen:
			level = gen.current_level

		# Usa o método estático para gerar o item
		var EquipmentGeneratorScript = load("res://scripts/equipment_generator.gd")
		var item = EquipmentGeneratorScript.generate_item(level)
		drop.equipment_data = item
	else:
		# Health potion is the default when equipment_data is null
		drop.equipment_data = null
		drop.heal_amount = 25.0

	get_parent().add_child(drop)
	drop.global_position = global_position

	var jump_target = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))

	# Animação de pulo que respeita colisões
	var tween = drop.create_tween()
	# Arco de altura (Y relativo ao sprite para não interferir na física global_position)
	var sprite = drop.get_node("Sprite2D")
	tween.tween_property(sprite, "position:y", -20, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Movimento horizontal/vertical com colisão
	var move_tween = drop.create_tween()
	var total_time = 0.3
	var start_pos = drop.global_position
	move_tween.tween_method(func(t): 
		if is_instance_valid(drop):
			var target = start_pos.lerp(jump_target, t)
			var diff = target - drop.global_position
			drop.move_and_collide(diff)
	, 0.0, 1.0, total_time)

# --- Métodos Virtuais para Customização ---

func _get_attack_range() -> float: return 25.0
func _get_min_chase_dist() -> float: return 20.0
func _get_jump_height() -> float: return 20.0
func _get_lunge_dist() -> float: return 15.0
func _get_bone_particle_scale() -> Vector2: return Vector2(1, 1)

# --- Desvio de Obstáculos ---

func _handle_collision_avoidance():
	if get_slide_collision_count() > 0:
		var col = get_slide_collision(0)
		var normal = col.get_normal()
		
		# Empurra levemente para longe da colisão
		velocity += normal * 10.0
		
		# Se estiver vagando e bater em algo, muda o destino imediatamente
		if current_state == State.WANDER:
			wander_timer = 0

# --- Manipuladores de Sinais ---

func _on_attack_timer_timeout():
	if current_state == State.ATTACK:
		current_state = State.AGGRESSIVE

func _on_hitbox_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(attack_damage)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(2, 2, 2), 0.05)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
