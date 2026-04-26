## Script para gerenciamento de salas individuais.
## Gerencia visuais, ciclos ambientais (sol/lua) e geração de objetos.
class_name Room
extends Node2D

# --- Referências de Nós ---
@onready var tile_map = $TileMap
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
var mumia_scene = preload("res://scenes/mumia.tscn")
var bandido_arma_scene = preload("res://scenes/bandido_arma.tscn")
var bandido_faca_scene = preload("res://scenes/bandido_faca.tscn")
var door_scene = preload("res://scenes/interactive_door.tscn")
var quicksand_scene = preload("res://scenes/quicksand.tscn")
var pressure_plate_scene = preload("res://scenes/pressure_plate.tscn")

# --- Configuração ---
var has_open_ceiling: bool = false
var _disabled_occluders: Array[LightOccluder2D] = []

const TILE_SIZE = 32
const ATLAS_FLOOR = Vector2i(1, 3)
const ATLAS_WALL_TOP = Vector2i(0, 1)
const ATLAS_WALL_INNER = Vector2i(1, 1)

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

## Configura a sala com suporte a tamanhos variáveis e desenho via TileMap.
func setup_room_ext(custom_size: Vector2, has_n: bool, has_s: bool, has_e: bool, has_w: bool, 
		is_open: bool, 
		spawn_n: bool = false, spawn_s: bool = false, spawn_e: bool = false, spawn_w: bool = false,
		min_enemies: int = 0, max_enemies: int = 2):

	# 1. Limpa e desenha o TileMap
	_draw_room_tilemap(custom_size, has_n, has_s, has_e, has_w)

	# 2. Ajusta a Área de Detecção (CollisionShape2D)
	var room_shape = $DetectionArea/CollisionShape2D
	room_shape.shape = room_shape.shape.duplicate()
	room_shape.shape.size = custom_size

	# 3. Reposiciona e Redimensiona as Paredes e Gatilhos de Porta
	var half_w = custom_size.x / 2.0
	var half_h = custom_size.y / 2.0
	var door_width = 64.0 # 2 tiles * 32px

	# Calcula o tamanho que os segmentos de parede devem ter
	var horizontal_wall_len = (custom_size.x - door_width) / 2.0
	var vertical_wall_len = (custom_size.y - door_width) / 2.0

	# Função auxiliar para redimensionar segmentos de parede e OCLUSORES
	var resize_wall = func(node_path: String, new_len: float, thickness: float):
		var wall = get_node(node_path)
		var col = wall.get_node("CollisionShape2D")
		var occ = wall.get_node("LightOccluder2D")
		
		col.shape = col.shape.duplicate()
		occ.occluder = occ.occluder.duplicate()
		
		col.shape.size = Vector2(new_len, thickness)
		
		var half_l = new_len / 2.0
		var half_t = thickness / 2.0
		var points = PackedVector2Array([
			Vector2(-half_l, -half_t), Vector2(half_l, -half_t), 
			Vector2(half_l, half_t), Vector2(-half_l, half_t)
		])
		occ.occluder.polygon = points

	# Função auxiliar para portas estáticas (fillers)
	var resize_filler = func(door_node: StaticBody2D, w: float, h: float, pos: Vector2):
		door_node.position = pos
		var col = door_node.get_node("CollisionShape2D")
		col.shape = col.shape.duplicate()
		col.shape.size = Vector2(w, h)
		
		var occ = door_node.get_node_or_null("LightOccluder2D")
		if occ:
			occ.occluder = occ.occluder.duplicate()
			var half_w_fill = w / 2.0
			var half_h_fill = h / 2.0
			occ.occluder.polygon = PackedVector2Array([
				Vector2(-half_w_fill, -half_h_fill), Vector2(half_w_fill, -half_h_fill),
				Vector2(half_w_fill, half_h_fill), Vector2(-half_w_fill, half_h_fill)
			])

	# Norte (64px thickness)
	resize_wall.call("Walls/WallNorthLeft", horizontal_wall_len, 64.0)
	resize_wall.call("Walls/WallNorthRight", horizontal_wall_len, 64.0)
	$Walls/WallNorthLeft.position = Vector2(-half_w + horizontal_wall_len/2.0, -half_h + 32.0)
	$Walls/WallNorthRight.position = Vector2(half_w - horizontal_wall_len/2.0, -half_h + 32.0)
	resize_filler.call($DoorNorth, 64.0, 64.0, Vector2(0, -half_h + 32.0))

	# Sul (64px thickness)
	resize_wall.call("Walls/WallSouthLeft", horizontal_wall_len, 64.0)
	resize_wall.call("Walls/WallSouthRight", horizontal_wall_len, 64.0)
	$Walls/WallSouthLeft.position = Vector2(-half_w + horizontal_wall_len/2.0, half_h - 32.0)
	$Walls/WallSouthRight.position = Vector2(half_w - horizontal_wall_len/2.0, half_h - 32.0)
	resize_filler.call($DoorSouth, 64.0, 64.0, Vector2(0, half_h - 32.0))

	# Leste (32px thickness)
	resize_wall.call("Walls/WallEastTop", vertical_wall_len, 32.0)
	resize_wall.call("Walls/WallEastBottom", vertical_wall_len, 32.0)
	$Walls/WallEastTop.position = Vector2(half_w - 16.0, -half_h + vertical_wall_len/2.0)
	$Walls/WallEastBottom.position = Vector2(half_w - 16.0, half_h - vertical_wall_len/2.0)
	resize_filler.call($DoorEast, 32.0, 64.0, Vector2(half_w - 16.0, 0))

	# Oeste (32px thickness)
	resize_wall.call("Walls/WallWestTop", vertical_wall_len, 32.0)
	resize_wall.call("Walls/WallWestBottom", vertical_wall_len, 32.0)
	$Walls/WallWestTop.position = Vector2(-half_w + 16.0, -half_h + vertical_wall_len/2.0)
	$Walls/WallWestBottom.position = Vector2(-half_w + 16.0, half_h - vertical_wall_len/2.0)
	resize_filler.call($DoorWest, 32.0, 64.0, Vector2(-half_w + 16.0, 0))

	# 4. Chama o setup original
	setup_room(custom_size, has_n, has_s, has_e, has_w, is_open, spawn_n, spawn_s, spawn_e, spawn_w, min_enemies, max_enemies)
	
	# 5. Ajusta a escala das luzes para o tamanho da sala
	var avg_size = (custom_size.x + custom_size.y) / 2.0
	var scale_factor = avg_size / 400.0
	sunlight.texture_scale = 1.2 * scale_factor
	moonlight.texture_scale = 1.0 * scale_factor

func _draw_room_tilemap(custom_size: Vector2, has_n: bool, has_s: bool, has_e: bool, has_w: bool):
	tile_map.clear()
	
	var width_tiles = int(custom_size.x / TILE_SIZE)
	var height_tiles = int(custom_size.y / TILE_SIZE)
	var half_w = width_tiles / 2
	var half_h = height_tiles / 2
	
	# Camada 0: Chão (z_index -2)
	for x in range(-half_w, half_w):
		for y in range(-half_h, half_h):
			tile_map.set_cell(0, Vector2i(x, y), 0, ATLAS_FLOOR)
	
	# Camada 1: Paredes (z_index 0)
	
	# Paredes Norte (2 tiles: Topo e Interna)
	for x in range(-half_w, half_w):
		# Pula o espaço da porta (2 tiles) se houver conexão
		if has_n and (x == -1 or x == 0): continue
		tile_map.set_cell(1, Vector2i(x, -half_h), 0, ATLAS_WALL_TOP)
		tile_map.set_cell(1, Vector2i(x, -half_h + 1), 0, ATLAS_WALL_INNER)
		
	# Paredes Sul (2 tiles)
	for x in range(-half_w, half_w):
		if has_s and (x == -1 or x == 0): continue
		tile_map.set_cell(1, Vector2i(x, half_h - 2), 0, ATLAS_WALL_TOP)
		tile_map.set_cell(1, Vector2i(x, half_h - 1), 0, ATLAS_WALL_INNER)
		
	# Paredes Leste (1 tile)
	for y in range(-half_h, half_h):
		if has_e and (y == -1 or y == 0): continue
		tile_map.set_cell(1, Vector2i(half_w - 1, y), 0, ATLAS_WALL_TOP)
		
	# Paredes Oeste (1 tile)
	for y in range(-half_h, half_h):
		if has_w and (y == -1 or y == 0): continue
		tile_map.set_cell(1, Vector2i(-half_w, y), 0, ATLAS_WALL_TOP)

## Configura o layout, portas e ambiente da sala.
func setup_room(room_size: Vector2, has_n: bool, has_s: bool, has_e: bool, has_w: bool, 
		is_open: bool, 
		spawn_n: bool = false, spawn_s: bool = false, spawn_e: bool = false, spawn_w: bool = false,
		min_enemies: int = 0, max_enemies: int = 2):

	has_open_ceiling = is_open

	# Função para alternar colisões de portas estáticas
	var toggle_door = func(door_node: StaticBody2D, exists: bool):
		door_node.get_node("CollisionShape2D").disabled = exists
		var occ = door_node.get_node_or_null("LightOccluder2D")
		if occ:
			occ.visible = !exists

	toggle_door.call($DoorNorth, has_n)
	toggle_door.call($DoorSouth, has_s)
	toggle_door.call($DoorEast, has_e)
	toggle_door.call($DoorWest, has_w)

	sunlight.visible = is_open
	moonlight.visible = is_open

	fireflies.position = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	fireflies.emitting = false 

	# Gera conteúdo procedural
	if global_position != Vector2.ZERO:
		_spawn_procedural_content(room_size, is_open, min_enemies, max_enemies)

	# Gera Portas Interativas
	var half_w = room_size.x / 2.0
	var half_h = room_size.y / 2.0
	
	if spawn_n: _spawn_interactive_door(Vector2(0, -half_h + 32.0), 0)
	if spawn_s: _spawn_interactive_door(Vector2(0, half_h - 32.0), 0)
	if spawn_e: _spawn_interactive_door(Vector2(half_w - 16.0, 0), PI/2)
	if spawn_w: _spawn_interactive_door(Vector2(-half_w + 16.0, 0), PI/2)


# --- Geração Procedural ---

## Popula a sala com pilares, caixas, inimigos e armadilhas com segurança de colisão.
func _spawn_procedural_content(room_size: Vector2, is_sunlight_room: bool, min_enemies: int, max_enemies: int) -> void:
	var is_corridor = room_size.x <= 160 or room_size.y <= 224
	
	var half_w = room_size.x / 2.0
	var half_h = room_size.y / 2.0
	
	# Zonas seguras reforçadas
	var wall_e_w = 32.0 # Espessura visual
	var wall_n_s = 64.0 # Espessura visual
	var obj_radius = 25.0 # Raio de segurança para o centro dos objetos
	
	var margin_x = wall_e_w + obj_radius
	var margin_y = wall_n_s + obj_radius
	
	var min_x = -half_w + margin_x
	var max_x =  half_w - margin_x
	var min_y = -half_h + margin_y
	var max_y =  half_h - margin_y
	
	# Garante que min < max para o randf_range
	if min_x >= max_x: min_x = 0; max_x = 0
	if min_y >= max_y: min_y = 0; max_y = 0
	
	var occupied_positions = []
	var min_dist_between_objects = 55.0

	# 1. Pilares (Apenas salas, corners 2 tiles away)
	if not is_corridor:
		var p_margin_x = 32.0 + 64.0 # Parede + 2 tiles
		var p_margin_y = 64.0 + 64.0
		
		var corners = [
			Vector2(-half_w + p_margin_x, -half_h + p_margin_y), 
			Vector2(half_w - p_margin_x, -half_h + p_margin_y), 
			Vector2(-half_w + p_margin_x, half_h - p_margin_y), 
			Vector2(half_w - p_margin_x, half_h - p_margin_y)
		]
		corners.shuffle()
		for i in range(randi_range(1, 3)):
			var p = pillar_scene.instantiate()
			p.position = corners[i]
			add_child(p)
			occupied_positions.append(p.position)
			if randf() < 0.4: p.setup_torch(corners[i].y < 0)
	
	# 2. Caixas (Pulado em corredores)
	var num_boxes = 0 if is_corridor else randi_range(3, 8)
	for i in range(num_boxes):
		var b = box_scene.instantiate()
		var spawn_pos = Vector2.ZERO
		var valid_pos = false
		for attempt in range(15): # Mais tentativas para salas menores
			var rpos = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
			if is_sunlight_room and rpos.length() < 80: continue
			var too_close = false
			for pos in occupied_positions:
				if rpos.distance_to(pos) < min_dist_between_objects:
					too_close = true; break
			if not too_close:
				spawn_pos = rpos; valid_pos = true; break
		if valid_pos:
			b.position = spawn_pos
			add_child(b)
			occupied_positions.append(spawn_pos)
		else: b.queue_free()
		
	# 3. Inimigos
	var num_enemies = randi_range(min_enemies, max_enemies)
	for i in range(num_enemies):
		var enemy_roll = randf()
		var enemy_scene = skeleton_scene
		if enemy_roll < 0.15: enemy_scene = bandido_faca_scene
		elif enemy_roll < 0.35: enemy_scene = bandido_arma_scene
		elif enemy_roll < 0.65: enemy_scene = mumia_scene
			
		var enemy = enemy_scene.instantiate()
		var spawn_pos = Vector2.ZERO
		var valid_pos = false
		for attempt in range(15):
			var rpos = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
			var too_close = false
			for pos in occupied_positions:
				if rpos.distance_to(pos) < 50.0:
					too_close = true; break
			if not too_close:
				spawn_pos = rpos; valid_pos = true; break
		if valid_pos:
			enemy.position = spawn_pos
			add_child(enemy)
			occupied_positions.append(spawn_pos)
		else: enemy.queue_free()
		
	# 4. Armadilhas de Areia Movediça (Pulado em corredores)
	if not is_corridor and randf() < 0.40:
		for i in range(randi_range(1, 3)):
			var qs = quicksand_scene.instantiate()
			qs.position = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
			add_child(qs)

	# 5. Placas de Pressão (Pulado em corredores)
	if not is_corridor and randf() < 0.3:
		for i in range(randi_range(1, 3)):
			var pp = pressure_plate_scene.instantiate()
			var spawn_pos = Vector2.ZERO
			var valid_pos = false
			for attempt in range(15):
				var rpos = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
				var too_close = false
				for pos in occupied_positions:
					if rpos.distance_to(pos) < 70.0:
						too_close = true; break
				if not too_close:
					spawn_pos = rpos; valid_pos = true; break
			if valid_pos:
				pp.position = spawn_pos
				add_child(pp)
				occupied_positions.append(spawn_pos)
			else: pp.queue_free()

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
	
	# Restaura oclusores desativados no passo anterior
	for occ in _disabled_occluders:
		if is_instance_valid(occ):
			occ.visible = true
	_disabled_occluders.clear()
	
	var st = fmod(gen.sun_time, TAU)
	
	# Atualiza o Sol
	var s_val = sin(st)
	var current_size = Vector2(tile_map.get_used_rect().size) * TILE_SIZE
	var move_range = current_size.x * 0.3 # Move 30% da largura da sala
	
	if s_val > 0.0:
		sunlight.visible = true
		sunlight.position.x = -cos(st) * move_range
		sunlight.color = Color(1, 0.98, 0.85)
		var target_energy = clamp((s_val - 0.2) * 2.5, 0.0, 2.0)
		sunlight.energy = lerp(sunlight.energy, target_energy, 0.1)
		
		if sunlight.energy > 0.1:
			if not sun_audio.playing: sun_audio.play()
			_check_light_collision(sunlight)
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
		moonlight.position.x = -cos(m_st) * move_range
		moonlight.energy = (m_val - 0.4) * 1.5 
		fireflies.emitting = true
		if not moon_audio.playing: moon_audio.play()
		_check_light_collision(moonlight)
		
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

func _check_light_collision(light: PointLight2D) -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = light.global_position
	query.collision_mask = 1 # Camada de caixas e pilares
	
	var results = space_state.intersect_point(query)
	for result in results:
		var body = result.collider
		var occ = body.get_node_or_null("LightOccluder2D")
		if occ:
			occ.visible = false
			_disabled_occluders.append(occ)

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
