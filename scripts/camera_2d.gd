extends Camera2D

# Velocidade de suavização da câmera
@export var smooth_speed = 10.0

var player = null

func _process(delta):
	# Se ainda não achou o jogador, tenta achar agora
	if player == null:
		player = get_parent().get_node_or_null("Player")
	
	# Se achou, segue ele
	if player:
		position = lerp(position, player.position, smooth_speed * delta)
