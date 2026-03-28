extends CharacterBody2D

@export var _animation_tree: AnimationTree
@export var _attack_timer : Timer = null				
@export var _dash_timer : Timer = null
@export var _dash_speed: float = 200.0

var _state_machine
var _move_speed: float = 120.0
var _is_attacking: bool = false
var _last_direction := Vector2.RIGHT
var _dash_direction := Vector2.ZERO
var _is_dashing: bool = false

func _ready() -> void:
	_state_machine = _animation_tree["parameters/playback"]


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
		
	_attack()
	_animate()
	move_and_slide()
	_push_objects()
	


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
		_animation_tree["parameters/attack/blend_position"] = _last_direction
	
	# Movimento
	velocity = _direction.normalized() * _move_speed

# ATAQUE

func _attack() -> void:
	if _is_dashing:
		return
	if Input.is_action_just_pressed("attack") and _is_attacking == false:
		#set_physics_process(false)  # trava o player
		_attack_timer.start()
		_is_attacking = true

# ANIMAÇÃO

func _animate() -> void:
	if _is_attacking:
		_state_machine.travel("attack")
		return
		
	if velocity.length() > 1:
		_state_machine.travel("walk")
		return
	
	_state_machine.travel("idle")

# FIM DO ATAQUE

func _on_attack_timer_timeout() -> void:
	#set_physics_process(true) #destrava o player
	_is_attacking = false
	
	
# EMPURRAR OBJETOS

func _push_objects():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is RigidBody2D:
			collider.apply_central_impulse(collision.get_normal() * -10.0)

# DASH

func _dash() -> void:
	if Input.is_action_just_pressed("dash") and _is_dashing == false:
		
		var x_input = Input.get_axis("move_left", "move_right")
		var y_input = Input.get_axis("move_up", "move_down")
	
		var direction = Vector2(x_input, y_input)
	
		if direction == Vector2.ZERO:
			direction = _last_direction
		_dash_direction = direction.normalized()
		_dash_timer.start()
		_is_dashing = true

func _on_dash_timer_timeout() -> void:
	
	_is_dashing = false
