## Script para gerenciar a tela de fim de jogo.
## Gerencia o reinício do nível ou o fechamento do jogo.
class_name DeathScreen
extends Control

# --- Ciclo de Vida ---

func _ready() -> void:
	# Garante que a interação funcione enquanto o jogo está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# --- Lógica de Interação ---

func _on_restart_button_pressed() -> void:
	# Despausa antes de recarregar
	get_tree().paused = false
	get_tree().reload_current_scene()
	
	# Limpa a tela de morte
	get_parent().queue_free()

func _on_quit_button_pressed() -> void:
	# Fecha o aplicativo
	get_tree().quit()
