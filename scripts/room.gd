## Script para gerenciamento de salas individuais.
## Gerencia visuais, ciclos ambientais (sol/lua) e geração de objetos.
class_name Room
extends Node2D

# --- Referências de Nós ---
@onready var door_north = $DoorNorth
@onready var door_south = $DoorSouth
@onready var door_east = $DoorEast
@onready var door_west = $DoorWest
@onready var sunlight = $Sunlight
@onready var sun_audio = $Sunlight/SunlightAudio
@onready var moonlight = $Moonlight
@onready var moon_audio = $Moonlight/MoonlightAudio
@onready var fireflies = $Fireflies
@onready var firefly_light = $Fireflies/FireflyLight

# --- Cenas Pré-carregadas ---
var pillar_scene = preload("res://scenes/pillar.tscn")
var box_scene = preload("res://scenes/box.tscn")
var dummy_scene = preload("res://scenes/dummy.tscn")
var skeleton_scene = preload("res://scenes/skeleton.tscn")
var door_scene = preload("res://scenes/interactive_door.tscn")
var quicksand_scene = preload("res://scenes/quicksand.tscn")
var pressure_plate_scene = preload("res://scenes/pressure_plate.tscn")

# --- Configuração ---
var has_open_ceiling: bool = false

# --- Ciclo de Vida ---

func _ready() -> void:
	add_to_group("rooms")
	
	# Gera texturas procedurais para luzes
	sunlight.texture = _create_radial_texture(512, Color(1, 1, 1, 1))
	moonlight.texture = _create_radial_texture(512, Color(0.5, 0.7, 1, 1))
	firefly_light.texture = _create_radial_texture(64, Color(1, 1, 1, 1))
	
	# Ajustes iniciais de escala
	sunlight.texture_scale = 1.2
	moonlight.texture_scale = 1.0
	firefly_light.texture_scale = 1.0

func _process(_delta: float) -> void:
	if has_open_ceiling:
		_update_environmental_cycle()

# --- Configuração da Sala ---

## Configura a sala com suporte a tamanhos variáveis.
func setup_room_ext(custom_size: Vector2, has_n: bool, has_s: bool, has_e: bool, has_w: bool, 
		is_open: bool, 
		spawn_n: bool = false, spawn_s: bool = false, spawn_e: bool = false, spawn_w: bool = false,
		min_enemies: int = 0, max_enemies: int = 2):

	# 1. Ajusta o Chão (ColorRect)
	var floor_node = $Floor
	floor_node.size = custom_size
	floor_node.position = -custom_size / 2.0

	# 2. Ajusta a Área de Detecção (CollisionShape2D)
	var room_shape = $DetectionArea/CollisionShape2D
	room_shape.shape = room_shape.shape.duplicate()
	room_shape.shape.size = custom_size

	# 3. Reposiciona e Redimensiona as Paredes e Gatilhos de Porta
	var half_w = custom_size.x / 2.0
	var half_h = custom_size.y / 2.0
	var wall_thickness = 10.0
	var door_width = 80.0

	# Calcula o tamanho que os segmentos de parede devem ter
	var horizontal_wall_len = (custom_size.x - door_width) / 2.0
	var vertical_wall_len = (custom_size.y - door_width) / 2.0

	# Função auxiliar para redimensionar segmentos de parede e OCLUSORES
	var resize_wall = func(node_path: String, new_len: float):
		var wall = get_node(node_path)
		var rect = wall.get_node("ColorRect")
		var col = wall.get_node("CollisionShape2D")
		var occ = wall.get_node("LightOccluder2D")
		
		# Duplica recursos para serem únicos
		col.shape = col.shape.duplicate()
		occ.occluder = occ.occluder.duplicate()
		
		# Redimensiona Visual e Colisão (sem overlap para evitar problemas com tiles)
		rect.size = Vector2(new_len, 20)
		rect.position = Vector2(-new_len / 2.0, -10)
		col.shape.size = Vector2(new_len, 20)
		
		# Oclusores extremamente finos (1px) evitam o efeito funnel e bugs de sombra
		var half_l = new_len / 2.0
		var occ_thick = 0.5 
		var points = PackedVector2Array([
			Vector2(-half_l, -occ_thick),
			Vector2(half_l, -occ_thick),
			Vector2(half_l, occ_thick),
			Vector2(-half_l, occ_thick)
		])
		occ.occluder.polygon = points

	# Norte
	var north_y = -half_h + wall_thickness
	door_north.position = Vector2(0, north_y)
	resize_wall.call("Walls/WallNorthLeft", horizontal_wall_len)
	resize_wall.call("Walls/WallNorthRight", horizontal_wall_len)
	$Walls/WallNorthLeft.position = Vector2(-half_w + horizontal_wall_len/2.0, north_y)
	$Walls/WallNorthRight.position = Vector2(half_w - horizontal_wall_len/2.0, north_y)

	# Sul
	var south_y = half_h - wall_thickness
	door_south.position = Vector2(0, south_y)
	resize_wall.call("Walls/WallSouthLeft", horizontal_wall_len)
	resize_wall.call("Walls/WallSouthRight", horizontal_wall_len)
	$Walls/WallSouthLeft.position = Vector2(-half_w + horizontal_wall_len/2.0, south_y)
	$Walls/WallSouthRight.position = Vector2(half_w - horizontal_wall_len/2.0, south_y)

	# Leste
	var east_x = half_w - wall_thickness
	door_east.position = Vector2(east_x, 0)
	resize_wall.call("Walls/WallEastTop", vertical_wall_len)
	resize_wall.call("Walls/WallEastBottom", vertical_wall_len)
	$Walls/WallEastTop.position = Vector2(east_x, -half_h + vertical_wall_len/2.0)
	$Walls/WallEastBottom.position = Vector2(east_x, half_h - vertical_wall_len/2.0)

	# Oeste
	var west_x = -half_w + wall_thickness
	door_west.position = Vector2(west_x, 0)
	resize_wall.call("Walls/WallWestTop", vertical_wall_len)
	resize_wall.call("Walls/WallWestBottom", vertical_wall_len)
	$Walls/WallWestTop.position = Vector2(west_x, -half_h + vertical_wall_len/2.0)
	$Walls/WallWestBottom.position = Vector2(west_x, half_h - vertical_wall_len/2.0)

	# 4. Chama o setup original
	setup_room(has_n, has_s, has_e, has_w, is_open, spawn_n, spawn_s, spawn_e, spawn_w, min_enemies, max_enemies)

## Configura o layout, portas e ambiente da sala.
func setup_room(has_n: bool, has_s: bool, has_e: bool, has_w: bool, 
		is_open: bool, 
		spawn_n: bool = false, spawn_s: bool = false, spawn_e: bool = false, spawn_w: bool = false,
		min_enemies: int = 0, max_enemies: int = 2):

	has_open_ceiling = is_open

	# Função para alternar visibilidade e oclusores de portas estáticas
	var toggle_door = func(door_node: Node2D, exists: bool):
		door_node.visible = !exists
		door_node.get_node("CollisionShape2D").disabled = exists
		var occ = door_node.get_node_or_null("LightOccluder2D")
		if occ: 
			occ.visible = !exists
			# Também afina o oclusor da porta estática
			if !exists:
				occ.occluder = occ.occluder.duplicate()
				var points = PackedVector2Array([
					Vector2(-40, -0.5), Vector2(40, -0.5), Vector2(40, 0.5), Vector2(-40, 0.5)
				])
				occ.occluder.polygon = points

	toggle_door.call(door_north, has_n)
	toggle_door.call(door_south, has_s)
	toggle_door.call(door_east, has_e)
	toggle_door.call(door_west, has_w)

	sunlight.visible = is_open
	moonlight.visible = is_open

	fireflies.position = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	fireflies.emitting = false 

	# Gera conteúdo procedural
	if global_position != Vector2.ZERO:
		_spawn_procedural_content(is_open, min_enemies, max_enemies)

	# Gera Portas Interativas
	var current_size = $Floor.size
	var half_w = current_size.x / 2.0
	var half_h = current_size.y / 2.0
	var offset = 10.0

	if spawn_n: _spawn_interactive_door(Vector2(0, -half_h + offset), 0)
	if spawn_s: _spawn_interactive_door(Vector2(0, half_h - offset), 0)
	if spawn_e: _spawn_interactive_door(Vector2(half_w - offset, 0), PI/2)
	if spawn_w: _spawn_interactive_door(Vector2(-half_w + offset, 0), PI/2)


# --- Geração Procedural ---

## Popula a sala com pilares, caixas, inimigos e armadilhas.
func _spawn_procedural_content(is_sunlight_room: bool, min_enemies: int, max_enemies: int) -> void:
	var current_size = $Floor.size
	var margin = 60.0
	var half_w = current_size.x / 2.0
	var half_h = current_size.y / 2.0
	
	var occupied_positions = []
	var min_dist_between_objects = 50.0

	# 1. Pilares
	var corners = [
		Vector2(-half_w + margin, -half_h + margin), 
		Vector2(half_w - margin, -half_h + margin), 
		Vector2(-half_w + margin, half_h - margin), 
		Vector2(half_w - margin, half_h - margin)
	]
	corners.shuffle()
	for i in range(randi_range(1, 3)):
		var p = pillar_scene.instantiate()
		p.position = corners[i]
		add_child(p)
		occupied_positions.append(p.position)
		if randf() < 0.4:
			p.setup_torch(corners[i].y < 0)
	
	# 2. Caixas
	for i in range(randi_range(3, 8)):
		var b = box_scene.instantiate()
		var spawn_pos = Vector2.ZERO
		var valid_pos = false
		for attempt in range(10):
			var rpos = Vector2(randf_range(-half_w + 40, half_w - 40), randf_range(-half_h + 40, half_h - 40))
			if is_sunlight_room and rpos.length() < 80: continue
			var too_close = false
			for pos in occupied_positions:
				if rpos.distance_to(pos) < min_dist_between_objects:
					too_close = true
					break
			if not too_close:
				spawn_pos = rpos
				valid_pos = true
				break
		if valid_pos:
			b.position = spawn_pos
			add_child(b)
			occupied_positions.append(spawn_pos)
		else:
			b.queue_free()
		
	# 3. Inimigos (Modular)
	var num_enemies = randi_range(min_enemies, max_enemies)
	for i in range(num_enemies):
		var enemy = skeleton_scene.instantiate()
		var spawn_pos = Vector2.ZERO
		var valid_pos = false
		for attempt in range(10):
			var rpos = Vector2(randf_range(-half_w + 80, half_w - 80), randf_range(-half_h + 80, half_h - 80))
			var too_close = false
			for pos in occupied_positions:
				if rpos.distance_to(pos) < 40.0:
					too_close = true
					break
			if not too_close:
				spawn_pos = rpos
				valid_pos = true
				break
		if valid_pos:
			enemy.position = spawn_pos
			add_child(enemy)
			occupied_positions.append(spawn_pos)
		else:
			enemy.queue_free()
		
	# 4. Armadilhas de Areia Movediça
	if randf() < 0.15:
		var qs = quicksand_scene.instantiate()
		qs.position = Vector2(randf_range(-half_w + 80, half_w - 80), randf_range(-half_h + 80, half_h - 80))
		add_child(qs)

	# 5. Placas de Pressão (Dardos de Veneno)
	if randf() < 0.3:
		for i in range(randi_range(1, 3)):
			var pp = pressure_plate_scene.instantiate()
			var spawn_pos = Vector2.ZERO
			var valid_pos = false
			for attempt in range(10):
				var rpos = Vector2(randf_range(-half_w + 100, half_w - 100), randf_range(-half_h + 100, half_h - 100))
				var too_close = false
				for pos in occupied_positions:
					if rpos.distance_to(pos) < 60.0:
						too_close = true
						break
				if not too_close:
					spawn_pos = rpos
					valid_pos = true
					break
			if valid_pos:
				pp.position = spawn_pos
				add_child(pp)
				occupied_positions.append(spawn_pos)
			else:
				pp.queue_free()

func _spawn_interactive_door(pos: Vector2, rot: float) -> void:
	var d = door_scene.instantiate()
	d.position = pos
	d.rotation = rot
	add_child(d)
	
	# Afina o oclusor da porta interativa para deixar a luz passar melhor
	var occ = d.get_node_or_null("LightOccluder2D")
	if occ and occ.occluder:
		occ.occluder = occ.occluder.duplicate()
		var points = PackedVector2Array([
			Vector2(-40, -0.5), Vector2(40, -0.5), Vector2(40, 0.5), Vector2(-40, 0.5)
		])
		occ.occluder.polygon = points

# --- Lógica de Ambiente ---

## Atualiza os ciclos de sol/lua baseados no temporizador do LevelGenerator.
func _update_environmental_cycle() -> void:
	var gen = get_parent()
	if not gen or not "sun_time" in gen: return
	
	var st = fmod(gen.sun_time, TAU)
	
	# Atualiza o Sol
	var s_val = sin(st)
	if s_val > 0.0:
		sunlight.visible = true
		sunlight.position.x = -cos(st) * 120.0
		sunlight.color = Color(1, 0.98, 0.85)
		var target_energy = clamp((s_val - 0.2) * 2.5, 0.0, 2.0)
		sunlight.energy = lerp(sunlight.energy, target_energy, 0.1)
		
		if sunlight.energy > 0.1:
			if not sun_audio.playing: sun_audio.play()
		else:
			if sun_audio.playing: sun_audio.stop()
	else:
		sunlight.visible = false
		sunlight.energy = 0
		if sun_audio.playing: sun_audio.stop()
			
	# Atualiza a Lua e os Vaga-lumes
	var m_st = fmod(st + PI, TAU)
	var m_val = sin(m_st)
	if m_val > 0.4:
		moonlight.visible = true
		moonlight.position.x = -cos(m_st) * 120.0
		moonlight.energy = (m_val - 0.4) * 1.5 
		fireflies.emitting = true
		if not moon_audio.playing: moon_audio.play()
		
		# Iluminação de vaga-lumes baseada em proximidade
		var d = abs(fireflies.position.x - moonlight.position.x)
		if d < 100:
			firefly_light.visible = true
			firefly_light.energy = (0.2 + randf() * 0.2) * (1.0 - d/100.0)
		else:
			firefly_light.visible = false
	else:
		moonlight.visible = false
		fireflies.emitting = false
		firefly_light.visible = false
		if moon_audio.playing: moon_audio.stop()

# --- Utilitários ---

func _create_radial_texture(size: int, main_color: Color) -> GradientTexture2D:
	var grad = Gradient.new()
	grad.offsets = [0.0, 0.8]
	grad.colors = [main_color, Color(main_color.r, main_color.g, main_color.b, 0)]
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.use_hdr = true
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5) 
	tex.width = size
	tex.height = size
	return tex
