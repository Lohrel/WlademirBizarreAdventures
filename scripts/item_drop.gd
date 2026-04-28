class_name ItemDrop
extends CharacterBody2D

@export var item_name: String = "Placeholder Item"
@export var heal_amount: float = 25.0
@export var equipment_data: Equipment = null

const HEAL_ICON = preload("res://assets/itens/item_pocao_cura.png")

var _player_in_range: Node2D = null

func _ready() -> void:
	if equipment_data:
		item_name = equipment_data.name
		_setup_rarity_visuals()
		_setup_tooltip()
		if equipment_data.icon:
			$Sprite2D.texture = equipment_data.icon
			if $Sprite2D.has_node("ColorRect"):
				$Sprite2D/ColorRect.hide()
	else:
		item_name = "Healing Potion"
		$Sprite2D.texture = HEAL_ICON
		if $Sprite2D.has_node("ColorRect"):
			$Sprite2D/ColorRect.hide()
		
		# Garante que a poção também seja visível no escuro
		if not $Sprite2D.material:
			var mat = CanvasItemMaterial.new()
			mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
			$Sprite2D.material = mat
		
		# Adiciona luz vermelha para a poção
		_setup_potion_visuals()
		_setup_potion_tooltip()
	
	# Conecta os sinais de entrada e saída da área de pickup
	$PickupArea.body_entered.connect(_on_body_entered)
	$PickupArea.body_exited.connect(_on_body_exited)
	
	# Pequena animação de flutuar
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 5, 0.6).set_trans(Tween.TRANS_SINE)
	
	# Garante que não spawne dentro de paredes
	_push_out_of_walls()

func _push_out_of_walls():
	for i in range(4):
		var collision = move_and_collide(Vector2.ZERO, true)
		if collision:
			var push_dir = collision.get_normal()
			global_position += push_dir * 2.0
		else:
			break

func _setup_rarity_visuals() -> void:
	var rarity_colors = {
		Equipment.Rarity.COMMON: Color(1, 1, 1),
		Equipment.Rarity.UNCOMMON: Color(0.2, 1, 0.2),
		Equipment.Rarity.RARE: Color(0.2, 0.4, 1),
		Equipment.Rarity.EPIC: Color(0.8, 0.2, 1),
		Equipment.Rarity.LEGENDARY: Color(1, 0.8, 0.2)
	}
	var color = rarity_colors[equipment_data.rarity]
	
	# Faz o sprite ignorar a iluminação global (CanvasModulate) para ficar sempre visível
	if not $Sprite2D.material:
		var mat = CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		$Sprite2D.material = mat
	
	# Aplica o filtro de cor ao sprite para combinar com a raridade
	$Sprite2D.modulate = color * 1.2
	
	var light = PointLight2D.new()
	light.color = color
	light.energy = 0.6
	light.texture_scale = 0.4
	light.texture = _create_light_texture(128)
	add_child(light)

func _setup_tooltip() -> void:
	%NameLabel.text = equipment_data.name
	
	var rarity_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	%RarityLabel.text = rarity_names[equipment_data.rarity]
	
	var rarity_colors = {
		Equipment.Rarity.COMMON: Color(1, 1, 1),
		Equipment.Rarity.UNCOMMON: Color(0.4, 1, 0.4),
		Equipment.Rarity.RARE: Color(0.4, 0.6, 1),
		Equipment.Rarity.EPIC: Color(0.9, 0.4, 1),
		Equipment.Rarity.LEGENDARY: Color(1, 0.9, 0.4)
	}
	%RarityLabel.add_theme_color_override("font_color", rarity_colors[equipment_data.rarity])
	
	var stats_text = "[center]"
	for stat in equipment_data.stats:
		var val = equipment_data.stats[stat]
		var percent = int(val * 100)
		stats_text += "[color=green]+%d%%[/color] [color=gray]%s[/color]\n" % [percent, stat.replace("_", " ").capitalize()]
	
	%StatsLabel.text = stats_text.strip_edges() + "[/center]"

func _setup_potion_visuals() -> void:
	var color = Color(1, 0.2, 0.2) # Vermelho para poção
	var light = PointLight2D.new()
	light.color = color
	light.energy = 0.6
	light.texture_scale = 0.4
	light.texture = _create_light_texture(128)
	add_child(light)

func _setup_potion_tooltip() -> void:
	if has_node("Tooltip"):
		%NameLabel.text = "Healing Potion"
		%RarityLabel.text = "Consumable"
		%RarityLabel.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		%StatsLabel.text = "[center][color=red]+25 HP[/color][/center]"

func _process(_delta: float) -> void:
	if _player_in_range:
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
		_player_in_range = body
		if has_node("Tooltip"):
			$Tooltip.show()

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if has_node("Tooltip"):
			$Tooltip.hide()

func _collect(player: Node2D) -> void:
	if equipment_data:
		if player.has_method("equip_item"):
			if player.equip_item(equipment_data):
				# Sucesso ao equipar
				pass
			else:
				# Slot cheio - Mostra mensagem
				_show_full_message(player)
				return
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

func _show_full_message(player: Node2D) -> void:
	if "damage_indicator_scene" in player:
		var indicator = player.damage_indicator_scene.instantiate()
		player.get_parent().add_child(indicator)
		indicator.global_position = player.global_position + Vector2(0, -30)
		indicator.setup("INVENTORY FULL", Color(1, 0.5, 0))
	
	# Feedback visual no item
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(2, 0, 0), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
