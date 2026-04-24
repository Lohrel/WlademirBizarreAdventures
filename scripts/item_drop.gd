extends Area2D

@export var item_name: String = "Placeholder Item"
@export var heal_amount: float = 20.0

func _ready() -> void:
	# Conecta o sinal de entrada de corpo
	body_entered.connect(_on_body_entered)
	
	# Pequena animação de flutuar
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 5, 0.6).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect(body)

func _collect(player: Node2D) -> void:
	# Para agora, apenas cura o jogador como exemplo de efeito
	if player.has_method("heal"):
		player.heal(heal_amount)
	elif "health" in player:
		player.health = min(player.health + heal_amount, player.max_health)
		if player.has_method("update_hud"):
			player.update_hud()
	
	# Efeito visual de coleta
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
