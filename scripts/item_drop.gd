extends Area2D

@export var item_name: String = "Placeholder Item"
@export var heal_amount: float = 20.0
@export var equipment_data: Equipment = null

var _player_in_range: Node2D = null

func _ready() -> void:
	if equipment_data:
		item_name = equipment_data.name
		_setup_rarity_visuals()
		print("DEBUG: Spawned equipment drop: ", item_name)
		if equipment_data.icon:
			$Sprite2D.texture = equipment_data.icon
	
	# Conecta os sinais de entrada e saída
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Pequena animação de flutuar
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 5, 0.6).set_trans(Tween.TRANS_SINE)

func _setup_rarity_visuals() -> void:
	var rarity_colors = {
		Equipment.Rarity.COMMON: Color(1, 1, 1),
		Equipment.Rarity.UNCOMMON: Color(0.2, 1, 0.2),
		Equipment.Rarity.RARE: Color(0.2, 0.4, 1),
		Equipment.Rarity.EPIC: Color(0.8, 0.2, 1),
		Equipment.Rarity.LEGENDARY: Color(1, 0.8, 0.2)
	}
	var color = rarity_colors[equipment_data.rarity]
	self_modulate = color * 1.5 # Brilho HDR
	
	# Adiciona uma luz com a cor da raridade
	var light = PointLight2D.new()
	light.color = color
	light.energy = 0.6
	light.texture_scale = 0.4
	light.texture = _create_light_texture(128)
	add_child(light)

func _process(_delta: float) -> void:
	if _player_in_range and equipment_data:
		if Input.is_action_just_pressed("interact"):
			_collect(_player_in_range)

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
		if equipment_data:
			_player_in_range = body
			# Tooltip será mostrado aqui na Fase 3
		else:
			# Auto-collect para itens de cura
			_collect(body)

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null

func _collect(player: Node2D) -> void:
	if equipment_data:
		if player.has_method("equip_item"):
			player.equip_item(equipment_data)
	else:
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
