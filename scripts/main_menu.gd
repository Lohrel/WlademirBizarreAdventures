extends Control

func _ready() -> void:
	# Tenta focar o botão Play ao iniciar para navegação por teclado/controle
	var play_btn = get_node_or_null("VBoxContainer/PlayButton")
	if play_btn:
		play_btn.grab_focus()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_generator.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
