## Controla a mão/garra do jogador.
## Responsável pelo posicionamento em relação ao mouse e detecção de ataques.
extends Sprite2D

# --- Atributos ---
@export var distancia: int = 25
@export var max_grab_distance: float = 100.0
@export var attack_damage: float = 10.0

var visual_scale: float = 1.0

# --- Referências ---
@onready var hitbox = $Hitbox
@onready var _attack_audio: AudioStreamPlayer2D = $AttackAudio

var _already_hit_areas: Array[Area2D] = []
var _grabbed_box: RigidBody2D = null

# --- Ciclo de Vida ---

func _ready() -> void:
	# Conecta o sinal de colisão para causar dano
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
		hitbox.monitoring = false
		hitbox.monitorable = false

func _physics_process(_delta: float) -> void:
	var player = get_parent().get_parent()
	if not player: return
	
	var target_pos = get_global_mouse_position()
	
	# Lógica de agarrar e mover caixas
	var is_hovering_box = false
	if not is_instance_valid(_grabbed_box):
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = global_position
		var results = space_state.intersect_point(query)
		for result in results:
			var collider = result.collider
			if collider is RigidBody2D and collider.is_in_group("destructible"):
				is_hovering_box = true
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					_grabbed_box = collider
					_grabbed_box.freeze = true
					_grabbed_box.add_collision_exception_with(player)
				break
				
	if is_instance_valid(_grabbed_box) or is_hovering_box:
		frame = 1
	else:
		frame = 0

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if is_instance_valid(_grabbed_box):
			_grabbed_box.freeze = false
			_grabbed_box.remove_collision_exception_with(player)
			_grabbed_box = null

	# Faz a garra seguir a direção do mouse
	if is_instance_valid(_grabbed_box):
		var distance = player.global_position.distance_to(target_pos)
		var desired_pos = target_pos
		if distance > max_grab_distance:
			var dir_to_target = (target_pos - player.global_position).normalized()
			desired_pos = player.global_position + dir_to_target * max_grab_distance
			
		# Usa move_and_collide para impedir que a caixa atravesse paredes e empurre os inimigos sem atravessá-los
		var motion = desired_pos - _grabbed_box.global_position
		var collision = _grabbed_box.move_and_collide(motion)
		
		if collision:
			var collider = collision.get_collider()
			# Checa se é um inimigo (tem take_damage, não é o player, e é CharacterBody2D)
			if collider is CharacterBody2D and collider != player and collider.has_method("take_damage"):
				# Fator de resistência: 0.2 significa que a caixa empurra o inimigo com apenas 20% da velocidade
				var resistance_factor = 0.2
				var push_vector = collision.get_remainder() * resistance_factor
				
				# Empurra o inimigo
				collider.move_and_collide(push_vector)
				# Move a caixa acompanhando o empurrão
				_grabbed_box.move_and_collide(push_vector)
		
		# A garra fica na mesma posição da caixa
		global_position = _grabbed_box.global_position
	else:
		var dir = (target_pos - player.global_position).normalized()
		global_position = player.global_position + dir * distancia
		
	# Apenas dá look_at se não estiver perfeitamente em cima do alvo para evitar erros
	if global_position.distance_to(target_pos) > 0.1:
		look_at(target_pos)
	elif is_instance_valid(_grabbed_box):
		# Opcional: faz a garra apontar para o player se estiver livre pelo mouse
		var dir_to_player = (player.global_position - global_position).normalized()
		rotation = dir_to_player.angle() + PI # Aponta no sentido inverso ao player, pra frente

	# Aplica escala base
	scale.x = visual_scale
	
	# Corrige a orientação vertical (flip) para não ficar de cabeça para baixo
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -visual_scale
	else:
		scale.y = visual_scale

# --- Lógica de Ataque ---

func start_attack() -> void:
	distancia = 0
	_already_hit_areas.clear()
	if _attack_audio:
		_attack_audio.stop()
		_attack_audio.play()
	if hitbox:
		hitbox.monitoring = true
		hitbox.monitorable = true
		# Verifica imediatamente quem já está dentro da hitbox
		# Isso resolve o problema de inimigos colados no player
		_check_initial_overlaps()

func stop_attack() -> void:
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false
	_already_hit_areas.clear()

func _check_initial_overlaps() -> void:
	if not hitbox or not hitbox.is_inside_tree(): return
	
	var overlapping_areas = hitbox.get_overlapping_areas()
	for area in overlapping_areas:
		_on_hitbox_area_entered(area)

# --- Sinais ---

func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area in _already_hit_areas:
		# Se atingir a área de dano de um inimigo
		if area.name == "Hurtbox" and area.owner.has_method("take_damage"):
			_already_hit_areas.append(area)
			
			var damage_to_deal = attack_damage
			var is_crit = false
			
			var player = get_parent().get_parent()
			if player and "crit_chance" in player:
				if randf() < player.crit_chance:
					is_crit = true
					damage_to_deal *= player.crit_multiplier
			
			# Aplica dano e knockback usando a posição da garra
			var knockback = player.knockback_strength if player and "knockback_strength" in player else 300.0
			area.owner.take_damage(damage_to_deal, global_position, knockback, is_crit)
			
			# Lógica de Roubo de Vida (apenas em inimigos vivos)
			if player and "life_steal" in player and player.life_steal > 0:
				var enemy = area.owner
				if enemy.get("is_living") == true:
					var heal_amount = damage_to_deal * player.life_steal
					player.health = min(player.health + heal_amount, player.max_health)
					player.update_hud()
			
			# Feedback visual na garra
			var tween = create_tween()
			var base_visual_scale = visual_scale
			var scale_mult = 2.0 if is_crit else 1.5
			tween.tween_property(self, "visual_scale", base_visual_scale * scale_mult, 0.05)
			tween.tween_property(self, "visual_scale", base_visual_scale, 0.1)
			
			# Shake da câmera
			var cam = get_viewport().get_camera_2d()
			if cam and cam.has_method("shake"):
				var shake_intensity = 6.0 if is_crit else 3.0
				cam.shake(shake_intensity)
				
			# Hit Stop (Freeze frame)
			var stop_time = 0.1 if is_crit else 0.05
			Engine.time_scale = 0.05
			await get_tree().create_timer(stop_time, true, false, true).timeout
			Engine.time_scale = 1.0
