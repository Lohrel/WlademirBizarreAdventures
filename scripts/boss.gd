extends CharacterBody2D

enum State { IDLE, WANDER, ALERT, AGGRESSIVE, ATTACK }

# Boss Stats: 3x stronger than skeleton
@export var health: float = 150.0
@export var wander_radius: float = 120.0
@export var move_speed: float = 60.0 # Slightly slower due to size
@export var chase_speed: float = 120.0
@export var attack_damage: float = 45.0

# Timers/Config
var alert_to_aggro_time: float = 1.0 # Quicker to aggro
var suspicion_drain_time: float = 10.0
var aggro_loss_time: float = 8.0

# Runtime Variables
var current_state = State.IDLE
var suspicion: float = 0.0
var out_of_sight_timer: float = 0.0
var player = null
var last_known_player_pos: Vector2
var target_wander_pos: Vector2
var wander_timer: float = 0.0
var spawn_pos: Vector2

@onready var sprite = $Sprite2D
@onready var anim_player = $AnimationPlayer
@onready var raycast = $RayCast2D
@onready var ray_left = $RayLeft
@onready var ray_right = $RayRight
@onready var detection_area = $DetectionArea
@onready var hitbox = $Hitbox
@onready var attack_timer = $AttackTimer

var bone_scene = preload("res://scenes/bone_particles.tscn")

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	spawn_pos = global_position
	target_wander_pos = spawn_pos
	_find_player()
	
	# Connect attack related signals
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Scale is 3x (handled in scene mostly, but ensures logic is consistent)
	add_to_group("boss")

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if not player: 
		_find_player()
		return
	
	_update_avoidance_rays()

	var in_range = detection_area.overlaps_body(player)
	var has_los = false
	
	if in_range:
		raycast.target_position = to_local(player.global_position)
		raycast.force_raycast_update()
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

		State.AGGRESSIVE:
			var dist = global_position.distance_to(player.global_position)
			if dist < 60 and attack_timer.is_stopped(): # Larger attack range
				current_state = State.ATTACK
				_perform_attack()
			else:
				_handle_aggressive(delta, in_range, has_los)

		State.ATTACK:
			velocity = velocity.move_toward(Vector2.ZERO, 10.0)

	move_and_slide()
	_animate()

func _perform_attack():
	var tween = create_tween()
	var target_pos = global_position + (player.global_position - global_position).normalized() * 40.0 # Bigger lunge
	tween.tween_property(self, "global_position", target_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	hitbox.monitoring = true
	await get_tree().create_timer(0.3).timeout
	hitbox.monitoring = false
	
	attack_timer.start()

func _on_attack_timer_timeout():
	if current_state == State.ATTACK:
		current_state = State.AGGRESSIVE

func _on_hitbox_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(attack_damage)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(3, 3, 3), 0.05)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)

func _animate():
	if current_state in [State.ALERT, State.AGGRESSIVE, State.ATTACK] and player:
		var dir_to_player = player.global_position.x - global_position.x
		if dir_to_player != 0:
			sprite.flip_h = dir_to_player < 0
	elif velocity.length() > 5:
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

	if velocity.length() > 5:
		anim_player.play("walk")
	else:
		anim_player.play("idle")

func _update_avoidance_rays():
	if velocity.length() > 0:
		var dir = velocity.normalized()
		ray_left.target_position = dir.rotated(-PI/4) * 60.0 # Longer rays for bigger boss
		ray_right.target_position = dir.rotated(PI/4) * 60.0

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
		suspicion -= delta / suspicion_drain_time
		if suspicion <= 0:
			suspicion = 0
			current_state = State.IDLE
		
		var dist = global_position.distance_to(last_known_player_pos)
		if dist > 20:
			var dir = (last_known_player_pos - global_position).normalized()
			dir = _get_avoidance_dir(dir)
			velocity = dir * move_speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 10.0)

func _handle_aggressive(delta, in_range, has_los):
	if not player: return
	if in_range and has_los:
		out_of_sight_timer = 0
		_chase_player()
	else:
		out_of_sight_timer += delta
		if out_of_sight_timer >= aggro_loss_time:
			current_state = State.ALERT
		_chase_player()

func _handle_wandering(delta):
	suspicion = 0 
	wander_timer -= delta
	if wander_timer <= 0:
		var rand_offset = Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
		target_wander_pos = spawn_pos + rand_offset
		wander_timer = randf_range(2, 5)
		current_state = State.WANDER
	
	if current_state == State.WANDER:
		var dist = global_position.distance_to(target_wander_pos)
		if dist < 20:
			current_state = State.IDLE
			velocity = Vector2.ZERO
		else:
			var dir = (target_wander_pos - global_position).normalized()
			dir = _get_avoidance_dir(dir)
			velocity = dir * move_speed

func _chase_player():
	var dist = global_position.distance_to(player.global_position)
	var target_dir = (player.global_position - global_position).normalized()
	
	if dist < 50:
		var separation_dir = -target_dir
		velocity = velocity.move_toward(separation_dir * move_speed, chase_speed * 0.2)
	elif dist < 70:
		velocity = velocity.move_toward(Vector2.ZERO, chase_speed * 0.1)
	else:
		var dir = _get_avoidance_dir(target_dir)
		velocity = velocity.move_toward(dir * chase_speed, chase_speed * 0.1)

func _visual_jump():
	var tween = create_tween()
	tween.tween_property(sprite, "position:y", -40, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func take_damage(amount: float):
	health -= amount
	current_state = State.AGGRESSIVE
	suspicion = 1.0

	var bone = bone_scene.instantiate()
	get_parent().add_child(bone)
	bone.global_position = global_position
	bone.scale = Vector2(2, 2) # Bigger bones
	bone.emitting = true
	get_tree().create_timer(bone.lifetime).timeout.connect(bone.queue_free)

	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	
	var tween_scale = create_tween()
	var base_scale = Vector2(3.0, 3.0) 
	tween_scale.tween_property(sprite, "scale", base_scale * 1.1, 0.05)
	tween_scale.tween_property(sprite, "scale", base_scale, 0.1)

	if health <= 0:
		die()

func die():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.finished.connect(queue_free)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		take_damage(10.0)
