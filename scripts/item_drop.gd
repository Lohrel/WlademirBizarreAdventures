extends Area2D

@export var item_name: String = "Placeholder Item"
@export var heal_amount: float = 20.0
@export var equipment_data: Equipment = null

func _ready() -> void:
	if equipment_data:
		item_name = equipment_data.name
		self_modulate = Color(1.5, 0.2, 2.5) # Roxo vibrante (HDR)
		
		# Adiciona uma luz púrpura pequena se for equipamento
		var light = PointLight2D.new()
		light.color = Color(0.8, 0.2, 1.0)
		light.energy = 0.5
		light.texture_scale = 0.3
		light.texture = _create_light_texture(64)
		add_child(light)
		
		print("DEBUG: Spawned equipment drop: ", item_name)
		if equipment_data.icon:
			$Sprite2D.texture = equipment_data.icon

	# Conecta o sinal de entrada de corpo
	body_entered.connect(_on_body_entered)
	
	# Pequena animação de flutuar
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 5, 0.6).set_trans(Tween.TRANS_SINE)

func _create_light_texture(size: int) -> GradientTexture2D:
	var grad = Gradient.new()
	grad.offsets = [0.0, 1.0]
	grad.colors = [Color(1,1,1,1), Color(1,1,1,0)]
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = size
	tex.height = size
	return tex

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect(body)

func _collect(player: Node2D) -> void:
	if equipment_data:
		if player.has_method("equip_item"):
			player.equip_item(equipment_data)
	else:
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
