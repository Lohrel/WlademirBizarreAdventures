extends CharacterBody2D

enum State { IDLE, WANDER, ALERT, AGGRESSIVE }

@export var health: float = 50.0
@export var wander_radius: float = 80.0
@export var move_speed: float = 80.0
@export var chase_speed: float = 120.0

# Timers/Config
var alert_to_aggro_time: float = 3.0
var suspicion_drain_time: float = 8.0
var aggro_loss_time: float = 5.0

# Runtime Variables
var current_state = State.IDLE
var suspicion: float = 0.0 # 0.0 to 1.0
var out_of_sight_timer: float = 0.0
var player = null
var last_known_player_pos: Vector2
var target_wander_pos: Vector2
var wander_timer: float = 0.0
var spawn_pos: Vector2
var _last_strafe_dir: Vector2 = Vector2.ZERO

@onready var sprite = $Sprite2D
@onready var raycast = $RayCast2D
@onready var detection_area = $DetectionArea

var blood_scene = preload("res://scenes/blood_particles.tscn")
var damage_indicator_scene = preload("res://scenes/damage_indicator.tscn")

func _ready():
	spawn_pos = global_position
	target_wander_pos = spawn_pos
	_find_player()

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if not player: 
		_find_player()
		return

	var in_range = detection_area.overlaps_body(player)
	var has_los = false
	
	if in_range:
		# IMPORTANTE: O target_position deve ser RELATIVO ao dummy
		raycast.target_position = to_local(player.global_position)
		raycast.force_raycast_update()
		# Se colidiu com algo (camada 1: paredes), não tem LoS.
		has_los = not raycast.is_colliding()
		
		if has_los:
			last_known_player_pos = player.global_position

	match current_state:
		State.IDLE, State.WANDER:
			if in_range and has_los:
				current_state = State.ALERT
				_visual_jump()
			else:
				_handle_wandering(delta)
		
		State.ALERT:
			_handle_alert(delta, in_range, has_los)
			_update_visual_alert()

		State.AGGRESSIVE:
			_handle_aggressive(delta, in_range, has_los)

	move_and_slide()
	_handle_collision_avoidance()
	_animate()

func _handle_collision_avoidance():
	if get_slide_collision_count() > 0:
		var col = get_slide_collision(0)
		var normal = col.get_normal()
		
		# Empurra levemente para longe da colisão
		velocity += normal * 10.0
		
		# Se estiver vagando e bater em algo, muda o destino imediatamente
		if current_state == State.WANDER:
			wander_timer = 0

func _handle_alert(delta, in_range, has_los):
	if in_range and has_los:
		suspicion += delta / alert_to_aggro_time
		if suspicion >= 1.0:
			suspicion = 1.0
			current_state = State.AGGRESSIVE
		velocity = velocity.move_toward(Vector2.ZERO, 10.0)
	else:
		# Se perdeu de vista mas ainda está em alerta, caminha até a última posição conhecida
		suspicion -= delta / suspicion_drain_time
		if suspicion <= 0:
			suspicion = 0
			current_state = State.IDLE
		
		var dist = global_position.distance_to(last_known_player_pos)
		if dist > 10:
			var dir = (last_known_player_pos - global_position).normalized()
			velocity = dir * move_speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 10.0)

func _handle_aggressive(delta, in_range, has_los):
	if in_range and has_los:
		out_of_sight_timer = 0
		_chase_player()
	else:
		# Se o player sumiu mas já estava AGRESSIVO, continua agressivo por um tempo
		out_of_sight_timer += delta
		if out_of_sight_timer >= aggro_loss_time:
			current_state = State.ALERT
		
		if not has_los and in_range:
			_strafe_for_los(delta)
		else:
			_chase_player()

func _strafe_for_los(_delta):
	if raycast.is_colliding():
		var normal = raycast.get_collision_normal()
		var strafe_dir = Vector2(-normal.y, normal.x)
		
		if _last_strafe_dir != Vector2.ZERO and strafe_dir.dot(_last_strafe_dir) < 0:
			strafe_dir = -strafe_dir
			
		_last_strafe_dir = strafe_dir
		velocity = velocity.move_toward(strafe_dir * chase_speed, chase_speed * 0.1)
	else:
		var dir = (last_known_player_pos - global_position).normalized()
		velocity = velocity.move_toward(dir * chase_speed, chase_speed * 0.1)

func _handle_wandering(delta):
	# Se estiver vagando (sem alerta), a suspeita deve estar em 0
	suspicion = 0 
	wander_timer -= delta
	if wander_timer <= 0:
		# Escolhe nova posição aleatória perto do spawn original
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

func _chase_player():
	_last_strafe_dir = Vector2.ZERO
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * chase_speed

func _animate():
	# Inverte o sprite baseado no movimento ou na posição do jogador
	if current_state in [State.ALERT, State.AGGRESSIVE] and player:
		var dir_to_player = player.global_position.x - global_position.x
		if dir_to_player != 0:
			sprite.flip_h = dir_to_player < 0
	elif velocity.length() > 5:
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

func _visual_jump():
	var tween = create_tween()
	# Pula 20 pixels pra cima e volta
	tween.tween_property(sprite, "position:y", -20, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _update_visual_alert():
	# Muda a cor baseado na suspeita (fica mais vermelho/vibrante)
	sprite.modulate = Color(0.8 + (suspicion * 0.2), 0.4 - (suspicion * 0.4), 0.4 - (suspicion * 0.4))

func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO, knockback_strength: float = 300.0):
	if amount > 0:
		var indicator = damage_indicator_scene.instantiate()
		get_parent().add_child(indicator)
		indicator.global_position = global_position + Vector2(0, -20)
		indicator.setup(str(int(amount)), Color(1, 1, 0.4))
	
	# health -= amount # Comentado para testes
	
	# Ao ser atacado, fica agressivo na hora
	current_state = State.AGGRESSIVE
	suspicion = 1.0

	if source_pos != Vector2.ZERO:
		var knock_dir = (global_position - source_pos).normalized()
		velocity = knock_dir * knockback_strength

	var blood = blood_scene.instantiate()
	get_parent().add_child(blood)
	blood.global_position = global_position
	blood.emitting = true
	get_tree().create_timer(blood.lifetime).timeout.connect(blood.queue_free)

	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	
	var tween_scale = create_tween()
	var base_scale = Vector2(0.15, 0.15)
	tween_scale.tween_property(sprite, "scale", base_scale * 1.2, 0.05)
	tween_scale.tween_property(sprite, "scale", base_scale, 0.1)

func die():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)
