extends Camera2D

# Velocidade de suavização da câmera
@export var smooth_speed = 10.0

var player = null
var _shake_amount = 0.0

func _process(delta):
	# Se ainda não achou o jogador, tenta achar agora
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	# Se achou, segue ele
	if player:
		var target_pos = player.position
		if _shake_amount > 0:
			target_pos += Vector2(randf_range(-_shake_amount, _shake_amount), randf_range(-_shake_amount, _shake_amount))
			_shake_amount = move_toward(_shake_amount, 0, delta * 20.0)
			
		position = lerp(position, target_pos, smooth_speed * delta).round()

func shake(amount: float):
	_shake_amount = amount
