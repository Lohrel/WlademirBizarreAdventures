extends CharacterBody2D

@export var speed = 100.0

func _physics_process(_delta):
	# Alternar Fullscreen com F11
	if Input.is_key_pressed(KEY_F11):
		var mode = DisplayServer.window_get_mode()
		if mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# Captura a direção das teclas (setas ou WASD)
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Aplica a velocidade
	velocity = direction * speed
	
	# Move_and_slide faz o personagem andar e deslizar em paredes
	move_and_slide()
	
	# Lógica para empurrar caixas (objetos RigidBody2D)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Se colidir com algo que pode ser empurrado
		if collider is RigidBody2D:
			# Aplica uma força menor para sentirmos a massa do objeto
			collider.apply_central_impulse(collision.get_normal() * -10.0)
