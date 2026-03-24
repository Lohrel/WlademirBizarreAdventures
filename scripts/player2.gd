extends CharacterBody2D

@export var _animation_tree: AnimationTree
@export var _attack_timer : Timer = null				


var _state_machine
var _move_speed: float = 64.0
var _is_attacking: bool = false


func _ready() -> void:
	_state_machine = _animation_tree["parameters/playback"]

func _physics_process(_delta: float) -> void:
	_move()
	_attack()
	_animate()
	move_and_slide()




func _move() -> void:
	var _direction: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	if _direction != Vector2.ZERO:
		_animation_tree["parameters/idle/blend_position"] = _direction
		_animation_tree["parameters/walk/blend_position"] = _direction
		_animation_tree["parameters/attack/blend_position"] = _direction
	
	velocity = _direction.normalized() * _move_speed

func _attack() -> void:
	if Input.is_action_just_pressed("attack") and _is_attacking == false:
		set_physics_process(false)
		_attack_timer.start()
		_is_attacking = true

func _animate() -> void:
	if _is_attacking:
		_state_machine.travel("attack")
		return
		
	if velocity.length() > 1:
		_state_machine.travel("walk")
		return
	
	_state_machine.travel("idle")


func _on_attack_timer_timeout() -> void:
	set_physics_process(true)
	_is_attacking = false 
	
