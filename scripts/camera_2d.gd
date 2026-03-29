extends Camera2D

# Velocidade de suavização da câmera
@export var smooth_speed = 10.0

var player = null

func _process(delta):
	# Se ainda não achou o jogador, tenta achar agora
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	# Se achou, segue ele
	if player:
		position = lerp(position, player.position, smooth_speed * delta).round()
