extends CharacterBody2D

@export var speed = 120.0

func _input(event):
	# Alternar Fullscreen com F11 (Apenas um clique por vez)
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var mode = DisplayServer.window_get_mode()
		if mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			
	# Resetar o Level com F5 (Apenas um clique por vez)
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		get_tree().reload_current_scene()

func _physics_process(_delta):
	# Captura a direção (Setas + WASD)
	var x_input = Input.get_axis("ui_left", "ui_right")
	var y_input = Input.get_axis("ui_up", "ui_down")
	
	# Se as setas não estão sendo usadas, tenta o WASD manualmente
	if x_input == 0:
		if Input.is_key_pressed(KEY_A): x_input = -1
		elif Input.is_key_pressed(KEY_D): x_input = 1
	if y_input == 0:
		if Input.is_key_pressed(KEY_W): y_input = -1
		elif Input.is_key_pressed(KEY_S): y_input = 1
	
	var direction = Vector2(x_input, y_input).normalized()
	
	# Aplica a velocidade
	velocity = direction * speed
	
	# Move o personagem
	move_and_slide()
	
	# Lógica para empurrar caixas (objetos RigidBody2D)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is RigidBody2D:
			collider.apply_central_impulse(collision.get_normal() * -10.0)
