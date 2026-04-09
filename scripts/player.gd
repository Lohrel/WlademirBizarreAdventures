extends CharacterBody2D

@export var _animation_tree: AnimationTree			
@export var _dash_timer : Timer = null
@export var _cooldown_dash : Timer = null
@export var _attack_timer : Timer = null
@export var _dash_speed: float = 200.0

@export_group("Stats")
@export var max_health: float = 100.0
@export var health: float = 100.0
@export var max_mana: float = 100.0
@export var mana: float = 100.0

@export_group("Skills Config")
@export var dash_mana_cost: float = 25.0
@export var dash_cooldown_time: float = 6.0

var _move_speed: float = 200.0
var _use_dash: bool = true
var _state_machine
var _last_direction := Vector2.RIGHT
var _dash_direction := Vector2.ZERO
var _is_dashing: bool = false
var _is_attacking: bool = false

var _current_room: Node2D = null
var _in_sunlight: bool = false

var blood_scene = preload("res://scenes/blood_particles.tscn")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	print ("ok")
	_state_machine = _animation_tree["parameters/playback"]
	add_to_group("player")
	_update_hud()
	$PlayerLight.texture = _create_light_texture(256)

func _create_light_texture(size: int) -> GradientTexture2D:
	var grad = Gradient.new()
	grad.offsets = [0.0, 0.8]
	grad.colors = [Color(1,1,1,1), Color(1,1,1,0)]
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.use_hdr = true
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5) 
	tex.width = size
	tex.height = size
	return tex

func _update_hud() -> void:
	$HUD/Control/VBoxContainer/HealthBar.max_value = max_health
	$HUD/Control/VBoxContainer/HealthBar.value = health
	$HUD/Control/VBoxContainer/ManaBar.max_value = max_mana
	$HUD/Control/VBoxContainer/ManaBar.value = mana

# INPUT (fullscreen + reset)

func _input(event):
	# F11 → fullscreen
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var mode = DisplayServer.window_get_mode()
		if mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			
	# F5 → reset
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		get_tree().reload_current_scene()



# LOOP PRINCIPAL

func _physics_process(_delta):
	_dash() 
	if _is_dashing:
		velocity = _dash_direction * _dash_speed
	else:
		_move()
		
	_animate()
	move_and_slide()
	_push_objects()
	_attack()
	_check_sunlight()
	
	if _in_sunlight:
		take_damage(15.0 * _delta)

func _check_sunlight() -> void:
	# 1. Localiza a sala atual
	if not _current_room or not _current_room.get_node("DetectionArea").overlaps_body(self):
		_current_room = null
		for node in get_tree().get_nodes_in_group("rooms"):
			var area = node.get_node("DetectionArea")
			if area.overlaps_body(self):
				_current_room = node
				break
	
	if not _current_room or not _current_room.has_open_ceiling:
		_set_in_sunlight(false)
		return

	# 2. Verifica se a luz do sol está ativa na sala e se tem energia suficiente
	var sunlight_node = _current_room.get_node_or_null("Sunlight")
	if not sunlight_node or not sunlight_node.visible or sunlight_node.energy < 0.5:
		_set_in_sunlight(false)
		return
		
	# 3. Raycast em direção à FONTE de luz (o nó Sunlight)
	# Isso garante que se houver uma caixa entre o player e a luz, 
	# o player estará "nas sombras".
	
	# O target_position do Raycast/ShapeCast é relativo ao player.
	# Apontamos para a posição global da luz.
	$SunShapeCast.target_position = to_local(sunlight_node.global_position)
	$SunShapeCast.force_shapecast_update()
	
	# Se colidir com algo (camada 1: obstáculos), o caminho da luz está bloqueado
	_set_in_sunlight(not $SunShapeCast.is_colliding())

func _set_in_sunlight(is_in: bool) -> void:
	if _in_sunlight != is_in:
		_in_sunlight = is_in
		if _in_sunlight:
			$HUD/Control/VBoxContainer/HealthBar.modulate = Color(2, 1, 1) # Feedback visual
			$BurnParticles.emitting = true
		else:
			$HUD/Control/VBoxContainer/HealthBar.modulate = Color(1, 1, 1)
			$BurnParticles.emitting = false

# MOVIMENTO


func _move() -> void:
	if _is_dashing:
		return
	# Input principal (actions)
	var x_input = Input.get_axis("move_left", "move_right")
	var y_input = Input.get_axis("move_up", "move_down")
	
	# fallback WASD manual
	if x_input == 0:
		if Input.is_key_pressed(KEY_A): x_input = -1
		elif Input.is_key_pressed(KEY_D): x_input = 1
	if y_input == 0:
		if Input.is_key_pressed(KEY_W): y_input = -1
		elif Input.is_key_pressed(KEY_S): y_input = 1
	
	var _direction: Vector2 = Vector2(x_input, y_input)

	# Atualiza direção horizontal para animação
	if _direction != Vector2.ZERO:
		if _direction.x != 0:
			_last_direction = Vector2(sign(_direction.x), 0)

		_animation_tree["parameters/walk/blend_position"] = _last_direction
		_animation_tree["parameters/idle/blend_position"] = _last_direction
	# Movimento
	velocity = _direction.normalized() * _move_speed

# ANIMAÇÃO

func _animate() -> void:
		
	if velocity.length() > 1:
		_state_machine.travel("walk")
		return
	
	_state_machine.travel("idle")
	
# EMPURRAR OBJETOS

func _push_objects():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is RigidBody2D:
			# Increased impulse from -10.0 to -35.0 for easier pushing
			collider.apply_central_impulse(collision.get_normal() * -25.0)

# DASH

func _dash() -> void:
	if Input.is_action_just_pressed("dash") and _is_dashing == false and _use_dash:
		if mana < dash_mana_cost:
			return
			
		var x_input = Input.get_axis("move_left", "move_right")
		var y_input = Input.get_axis("move_up", "move_down")
	
		var direction = Vector2(x_input, y_input)
	
		if direction == Vector2.ZERO:
			direction = _last_direction
		_dash_direction = direction.normalized()
		_use_dash = false
		mana -= dash_mana_cost
		_update_hud()
		_cooldown_dash.wait_time = dash_cooldown_time
		_cooldown_dash.start()
		_dash_timer.start()
		_is_dashing = true
		$DashSmoke.emitting = true

func _on_dash_timer_timeout() -> void:
	
	_is_dashing = false
	$DashSmoke.emitting = false

func _on_cooldown_dash_timeout() -> void:
	_use_dash = true

#attack
func _attack() -> void:
	if Input.is_action_just_pressed("attack") and _is_attacking == false:
		_attack_timer.start()
		_is_attacking = true
		$garra_player/hand.distancia = 0 # Inicia exatamente no centro do player
		$garra_player/hand/Hitbox.monitorable = true
		
	if _is_attacking:
		var current_dist = $garra_player/hand.distancia
		$garra_player/hand.distancia = move_toward(current_dist, 60, 350 * get_physics_process_delta_time())
		$garra_player/hand/ShadowTrail.emitting = true
	else:
		$garra_player/hand.distancia = move_toward($garra_player/hand.distancia, 25, 200 * get_physics_process_delta_time())
		$garra_player/hand/ShadowTrail.emitting = false
		$garra_player/hand/Hitbox.monitorable = false
		
	
func take_damage(amount: float) -> void:
	health -= amount
	health = max(0, health)
	_update_hud()
	
	if amount > 0.5:
		# Visual feedback (flash red) for bigger hits
		var tween = create_tween()
		tween.tween_property($Sprite2D, "modulate", Color(5, 0.5, 0.5), 0.1)
		tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1), 0.1)
		
		# Blood particles
		var blood = blood_scene.instantiate()
		get_parent().add_child(blood)
		blood.global_position = global_position
		blood.emitting = true
		get_tree().create_timer(blood.lifetime).timeout.connect(blood.queue_free)
	
	if health <= 0:
		# Morte do player
		get_tree().reload_current_scene()

func _on_attack_timer_timeout() -> void:
	_is_attacking = false
	$garra_player/hand/Hitbox.monitorable = false
