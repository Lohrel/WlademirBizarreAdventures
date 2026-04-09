extends Control

func _ready():
	# Ensure the screen is visible and handles input
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pause the game when death screen appears
	get_tree().paused = true
	# Make sure mouse is visible if it was hidden
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
	get_parent().queue_free()

func _on_quit_button_pressed():
	get_tree().quit()
