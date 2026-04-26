extends Camera2D

# Velocidade de suavização da câmera
@export var smooth_speed = 10.0

var player = null
var _shake_amount = 0.0

func _ready():
	# Começa com suavização desligada para o snap inicial ser instantâneo
	position_smoothing_enabled = false

func _process(delta):
	if _shake_amount > 0:
		_shake_amount = move_toward(_shake_amount, 0, delta * 20.0)
		offset = Vector2(randf_range(-_shake_amount, _shake_amount), randf_range(-_shake_amount, _shake_amount))
	else:
		offset = Vector2.ZERO

	# Se ainda não achou o jogador, tenta achar agora
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player:
			snap_to_player()
	
	# Se achou, segue ele
	if player:
		global_position = player.global_position

## Força a câmera a ir direto para o jogador sem suavização (útil para mudanças de nível)
func snap_to_player():
	player = get_tree().get_first_node_in_group("player")
	if player:
		# Desativa temporariamente para o snap não ser suavizado (evita o "deslizamento")
		position_smoothing_enabled = false
		global_position = player.global_position
		
		# Espera um frame ou usa um timer para religar a suavização
		# Aqui, apenas religamos; o próximo movimento será suavizado
		await get_tree().process_frame
		position_smoothing_enabled = true

func shake(amount: float):
	_shake_amount = amount
