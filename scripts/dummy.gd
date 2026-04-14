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

@onready var sprite = $Sprite2D
@onready var raycast = $RayCast2D
@onready var ray_left = $RayLeft
@onready var ray_right = $RayRight
@onready var detection_area = $DetectionArea

var blood_scene = preload("res://scenes/blood_particles.tscn")

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
	
	# Precisamos atualizar as direções dos raios de desvio
	_update_avoidance_rays()

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
	
	# DEBUG: Mostrar se está vendo o player
	# if in_range: print("In Range! LoS: ", has_los)

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

func _update_avoidance_rays():
	if velocity.length() > 0:
		var dir = velocity.normalized()
		# Ajusta os raios para apontar para a frente e lados da velocidade
		ray_left.target_position = dir.rotated(-PI/4) * 30.0
		ray_right.target_position = dir.rotated(PI/4) * 30.0

func _get_avoidance_dir(base_dir: Vector2) -> Vector2:
	var avoidance_dir = base_dir
	if ray_left.is_colliding():
		avoidance_dir += ray_left.get_collision_normal() * 0.5
	if ray_right.is_colliding():
		avoidance_dir += ray_right.get_collision_normal() * 0.5
	return avoidance_dir.normalized()

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
			dir = _get_avoidance_dir(dir)
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
		_chase_player()

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
			dir = _get_avoidance_dir(dir) # Desvia de paredes
			velocity = dir * move_speed

func _chase_player():
	var dir = (player.global_position - global_position).normalized()
	dir = _get_avoidance_dir(dir) # Desvia de paredes
	velocity = dir * chase_speed

func _visual_jump():
	var tween = create_tween()
	# Pula 20 pixels pra cima e volta
	tween.tween_property(sprite, "position:y", -20, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _update_visual_alert():
	# Muda a cor baseado na suspeita (fica mais vermelho/vibrante)
	sprite.modulate = Color(0.8 + (suspicion * 0.2), 0.4 - (suspicion * 0.4), 0.4 - (suspicion * 0.4))

func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO, knockback_strength: float = 300.0):
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

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		take_damage(10.0, area.global_position)
