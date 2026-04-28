## Gerador de nível procedural para Wlademir's Bizarre Adventures.
## Gerencia o layout das salas, posicionamento de chefes e construção do mundo.
class_name LevelGenerator
extends Node2D

# --- Sinais ---
signal map_updated

# --- Cenas Exportadas ---
@export_group("Scenes")
@export var room_scene: PackedScene
@export var player_scene: PackedScene
@export var boss_scene: PackedScene 
@export var boss_padre_scene: PackedScene
@export var upgrade_screen_scene: PackedScene
@export var staircase_scene: PackedScene

# --- Configuração ---
@export_group("Level Config")
@export var max_rooms: int = 15 
@export var day_speed: float = 0.05
const ROOM_SIZE = Vector2(400, 400)

# --- Variáveis de Tempo de Execução ---
var map_data = {} # Chave: Vector2i (pos. da grade), Valor: Dictionary (tipo e tamanho)
var current_level: int = 1
var sun_time: float = 0.0
var player_node: Node2D = null
var locked_exit_doors: Array[Node2D] = []
var map_container: Node2D = null
var player_grid_pos: Vector2i = Vector2i.ZERO

# Armazena as dimensões de cada coluna e linha para manter a grade alinhada
var col_widths = {}
var row_heights = {}

# --- Ciclo de Vida ---

func _ready() -> void:
	generate_new_level()

func _process(delta: float) -> void:
	# Atualiza o ciclo solar do mundo
	sun_time += delta * day_speed

# --- Geração de Nível ---

## Gera um andar completamente novo, limpando o anterior.
func generate_new_level() -> void:
	# Incrementa o contador de nível (se não for a primeira geração)
	if map_data.size() > 0:
		current_level += 1
	
	# 1. Limpeza Robusta: Deleta tudo que não for o Jogador, Câmera ou Background
	if map_container:
		map_container.queue_free()
		remove_child(map_container)
		map_container = null
	
	# Fallback para garantir que nada sobrou (especialmente nós orfãos com nomes Room ou @Room)
	for drop in get_tree().get_nodes_in_group("drops"):
		drop.queue_free()
		
	for child in get_children():
		if child.name.begins_with("Room") or "@Room" in child.name or child is Enemy or child is Staircase:
			child.queue_free()
	
	# 2. Cria novo container
	map_container = Node2D.new()
	map_container.name = "MapContainer"
	add_child(map_container)
	
	map_data.clear()
	col_widths.clear()
	row_heights.clear()
	locked_exit_doors.clear()
	
	# 3. Gera novo layout e visuais
	_generate_map_layout()
	_build_world_visuals()
	
	# 4. Posiciona Jogador
	_spawn_or_reset_player()
	
	# 5. Reset TOTAL de visibilidade (várias camadas para garantir)
	if player_node:
		player_node.modulate = Color(1, 1, 1, 1)
		var p_char = player_node.get_node_or_null("player")
		if p_char:
			p_char.modulate = Color(1, 1, 1, 1)
			var sprite = p_char.get_node_or_null("Sprite2D")
			if sprite:
				sprite.modulate = Color(1, 1, 1, 1)
			if p_char.has_method("update_hud"):
				p_char.update_hud()

## Usa um algoritmo de "Corridor Skeleton" para gerar o layout.
## Corredores formam uma rede (em coordenadas ímpares) e salas surgem como "apêndices" (dead ends).
func _generate_map_layout() -> void:
	var current_hub = Vector2i(1, 1) # Começa em coordenada ímpar (hub)
	map_data[current_hub] = {"type": "corridor"}
	
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	# 1. Gera o Esqueleto de Corredores (Random Walk entre Hubs)
	var skeleton_steps = max_rooms * 2
	for i in range(skeleton_steps):
		var dir = directions.pick_random()
		var connector = current_hub + dir
		var next_hub = current_hub + dir * 2
		
		# Marca o conector e o próximo hub como corredores
		map_data[connector] = {"type": "corridor"}
		map_data[next_hub] = {"type": "corridor"}
		current_hub = next_hub
	
	# 2. Anexa Salas ao Esqueleto
	var rooms_created = 0
	var corridor_keys = map_data.keys()
	corridor_keys.shuffle()
	
	for pos in corridor_keys:
		if rooms_created >= max_rooms: break
		
		var neighbors = directions.duplicate()
		neighbors.shuffle()
		
		for dir in neighbors:
			var room_pos = pos + dir
			# Regra: Salas apenas em (par, par) para manter o grid limpo
			if abs(room_pos.x) % 2 == 0 and abs(room_pos.y) % 2 == 0:
				if not map_data.has(room_pos):
					map_data[room_pos] = {"type": "normal"}
					rooms_created += 1
					if rooms_created >= max_rooms: break
	
	# 3. Garante salas mínimas (Início e Chefe)
	if rooms_created < 2:
		# Fallback: Tenta converter qualquer spot válido
		for x in range(-10, 11, 2):
			for y in range(-10, 11, 2):
				var p = Vector2i(x, y)
				if not map_data.has(p):
					map_data[p] = {"type": "normal"}
					rooms_created += 1
					# Conecta ao esqueleto
					for d in directions:
						map_data[p+d] = {"type": "corridor"}
				if rooms_created >= 2: break
			if rooms_created >= 2: break

	# 4. Designa Início e Chefe
	var room_positions = []
	for pos in map_data.keys():
		if map_data[pos]["type"] == "normal":
			room_positions.append(pos)
	
	# Início: a primeira sala encontrada
	var start_pos = room_positions[0]
	map_data[start_pos]["type"] = "start"
	
	# Chefe: a sala mais distante do início
	var furthest_pos = start_pos
	var max_dist = 0
	for pos in room_positions:
		var dist = (pos - start_pos).length_squared()
		if dist > max_dist:
			max_dist = dist
			furthest_pos = pos
	map_data[furthest_pos]["type"] = "boss"
	
	# 5. Adiciona sala de Saída conectada ao Chefe
	var exit_pos = Vector2i.ZERO
	for d in directions:
		var p = furthest_pos + d * 2
		if not map_data.has(p):
			# Cria corredor e sala de saída
			map_data[furthest_pos + d] = {"type": "corridor"}
			map_data[p] = {"type": "exit"}
			exit_pos = p
			break
	
	# Se não achou espaço, força em algum lugar
	if exit_pos == Vector2i.ZERO:
		for d in directions:
			var p = furthest_pos + d * 2
			map_data[furthest_pos + d] = {"type": "corridor"}
			map_data[p] = {"type": "exit"}
			exit_pos = p
			break

	# 6. Define dimensões dinâmicas baseadas na presença de salas
	var room_cols = {}
	var room_rows = {}
	var min_x = 0
	var max_x = 0
	var min_y = 0
	var max_y = 0
	
	for pos in map_data.keys():
		if map_data[pos]["type"] != "corridor":
			room_cols[pos.x] = true
			room_rows[pos.y] = true
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
	
	# Preenche todas as colunas e linhas no intervalo (incluindo 0)
	for x in range(min_x, max_x + 1):
		col_widths[x] = 12 * 32 if room_cols.has(x) else 4 * 32
	
	for y in range(min_y, max_y + 1):
		if room_rows.has(y):
			row_heights[y] = [12, 18, 24].pick_random() * 32
		else:
			row_heights[y] = 6 * 32
			
	# Atualiza o tamanho em map_data usando os valores finais
	for pos in map_data.keys():
		map_data[pos]["size"] = Vector2(col_widths[pos.x], row_heights[pos.y])

## Instancia as cenas das salas e as conecta.
func _build_world_visuals() -> void:
	var spawned_doors = {} # Rastreia conexões únicas para evitar portas duplicadas
	
	for grid_pos in map_data.keys():
		var room_info = map_data[grid_pos]
		room_info["visited"] = false # Inicializa Fog of War
		
		# Marca a sala inicial como visitada imediatamente
		if room_info["type"] == "start":
			room_info["visited"] = true
			
		var room_instance = room_scene.instantiate()
		room_instance.grid_pos = grid_pos # Informa a sala sua posição na grade
		
		# Calcula a posição física acumulando larguras/alturas
		room_instance.position = _get_physical_position(grid_pos)
		map_container.add_child(room_instance)
		
		# Verificação de vizinhos
		var n_pos = grid_pos + Vector2i.UP
		var s_pos = grid_pos + Vector2i.DOWN
		var e_pos = grid_pos + Vector2i.RIGHT
		var w_pos = grid_pos + Vector2i.LEFT
		
		var has_n = map_data.has(n_pos)
		var has_s = map_data.has(s_pos)
		var has_e = map_data.has(e_pos)
		var has_w = map_data.has(w_pos)
		
		# Lógica de conexão para portas interativas
		var spawn_n = _should_spawn_door(grid_pos, n_pos, has_n, spawned_doors)
		var spawn_s = _should_spawn_door(grid_pos, s_pos, has_s, spawned_doors)
		var spawn_e = _should_spawn_door(grid_pos, e_pos, has_e, spawned_doors)
		var spawn_w = _should_spawn_door(grid_pos, w_pos, has_w, spawned_doors)

		# Iluminação: Salas normais têm 30% de chance de teto aberto
		var is_open = false
		if room_info["type"] == "normal":
			is_open = randf() < 0.3

		# Calcula a quantidade modular de inimigos baseada no nível
		var min_enemies = 0
		var max_enemies = 0
		
		# Salas de início e corredores (opcional) não devem ter inimigos ou ter quantidade reduzida
		if room_info["type"] == "normal" or room_info["type"] == "boss":
			min_enemies = clampi(current_level, 1, 10)
			max_enemies = clampi(current_level + 2, 2, 15)
		elif room_info["type"] == "corridor":
			min_enemies = 0
			max_enemies = 1 # Lightly populated corridors
		elif room_info["type"] == "start" or room_info["type"] == "exit":
			min_enemies = 0
			max_enemies = 0 # No enemies in start/exit room

		# Configura o tamanho, visuais, conexões e inimigos da sala
		room_instance.setup_room_ext(room_info["size"], has_n, has_s, has_e, has_w, is_open, 
				spawn_n, spawn_s, spawn_e, spawn_w, min_enemies, max_enemies)

		# Se for uma porta de saída (conectada à sala de saída), rastreia para trancar
		_track_exit_doors(room_instance, grid_pos)
		
		# Gerencia a configuração específica da sala do Chefe
		if room_info["type"] == "boss":
			room_instance.modulate = Color(1, 0.5, 0.5) # Dica visual para o Chefe
			
			var selected_boss_scene = boss_scene
			if current_level == 2 and boss_padre_scene:
				selected_boss_scene = boss_padre_scene
				
			if selected_boss_scene:
				var boss = selected_boss_scene.instantiate()
				boss.position = room_instance.position
				if boss.has_signal("boss_died"):
					boss.boss_died.connect(_on_boss_died)
				elif boss.has_signal("enemy_died"):
					boss.enemy_died.connect(_on_boss_died)
				map_container.add_child(boss)
				
		# Gerencia a configuração específica da sala de Saída
		if room_info["type"] == "exit":
			room_instance.modulate = Color(0.5, 1, 0.5) # Dica visual para a Saída
			if staircase_scene:
				var stairs = staircase_scene.instantiate()
				stairs.position = room_instance.position
				map_container.add_child(stairs)

func _track_exit_doors(room_instance: Room, grid_pos: Vector2i) -> void:
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var current_type = map_data[grid_pos]["type"]
	
	for d in directions:
		var neighbor_pos = grid_pos + d
		if map_data.has(neighbor_pos):
			var neighbor_type = map_data[neighbor_pos]["type"]
			# Tranca se a porta leva para uma saída OU se estamos na saída e leva para uma sala normal/chefe
			if neighbor_type == "exit" or (current_type == "exit" and neighbor_type != "corridor"):
				for child in room_instance.get_children():
					if child is InteractiveDoor:
						# Se a porta está na direção do vizinho relevante, tranca
						var to_door = child.position.normalized()
						var to_neighbor = Vector2(d).normalized()
						if to_door.dot(to_neighbor) > 0.8:
							child.lock()
							locked_exit_doors.append(child)

## Calcula a posição física baseada na soma das larguras e alturas da grade.
func _get_physical_position(grid_pos: Vector2i) -> Vector2:
	var px = 0.0
	var py = 0.0
	
	# Soma larguras para X (do 0 até pos.x)
	if grid_pos.x > 0:
		for i in range(grid_pos.x):
			px += (col_widths[i] + col_widths[i+1]) / 2.0
	elif grid_pos.x < 0:
		for i in range(0, grid_pos.x, -1):
			px -= (col_widths[i] + col_widths[i-1]) / 2.0
			
	# Soma alturas para Y (do 0 até pos.y)
	if grid_pos.y > 0:
		for i in range(grid_pos.y):
			py += (row_heights[i] + row_heights[i+1]) / 2.0
	elif grid_pos.y < 0:
		for i in range(0, grid_pos.y, -1):
			py -= (row_heights[i] + row_heights[i-1]) / 2.0
			
	return Vector2(px, py)

## Auxiliar para determinar se uma porta interativa deve ser gerada em uma conexão.
func _should_spawn_door(pos_a: Vector2i, pos_b: Vector2i, exists: bool, record: Dictionary) -> bool:
	if not exists: return false
	
	# Cria uma chave única para esta conexão
	var connection = [pos_a, pos_b]
	connection.sort()
	var key = str(connection)
	
	# Se já decidimos sobre esta conexão (por um vizinho), não spawna outra porta duplicada
	if record.has(key):
		return false

	# Regra: Sempre gera porta se uma das salas for a Saída (Exit)
	if map_data[pos_a]["type"] == "exit" or map_data[pos_b]["type"] == "exit":
		record[key] = true
		return true
	
	# 35% de chance de colocar uma porta para outras salas
	var spawn = randf() < 0.35
	record[key] = spawn
	return spawn

# --- Gerenciamento do Jogador ---

func _spawn_or_reset_player() -> void:
	if player_node == null:
		player_node = player_scene.instantiate()
		player_node.name = "Player"
		add_child(player_node)
	
	# Encontra a posição física da sala "start"
	var start_grid_pos = Vector2i.ZERO
	for pos in map_data.keys():
		if map_data[pos]["type"] == "start":
			start_grid_pos = pos
			break
			
	var world_pos = _get_physical_position(start_grid_pos)
	
	# Redefine a posição raiz
	player_node.position = world_pos
	
	# Redefine a posição interna do CharacterBody2D
	if player_node.has_node("player"):
		player_node.get_node("player").position = Vector2.ZERO
		# Garante que o jogador esteja visível (caso tenha vindo de uma transição de nível)
		player_node.get_node("player").modulate.a = 1.0
		
	# Avisa a câmera para dar "snap" e evitar o deslizamento inicial
	var cam = get_node_or_null("Camera2D")
	if cam and cam.has_method("snap_to_player"):
		cam.snap_to_player()

# --- Manipuladores de Sinais ---

func _on_boss_died() -> void:
	# Desbloqueia as portas para a saída
	for door in locked_exit_doors:
		if is_instance_valid(door):
			door.unlock()
	
	# Breve pausa cinematográfica antes de mostrar a tela de upgrade
	await get_tree().create_timer(1.5).timeout
	
	if upgrade_screen_scene:
		var screen = upgrade_screen_scene.instantiate()
		add_child(screen)
		
		# Configura a lógica de upgrade
		var control = screen.get_node("Control")
		control.setup(player_node, self)

func mark_room_visited(grid_pos: Vector2i) -> void:
	if map_data.has(grid_pos) and not map_data[grid_pos].get("visited", false):
		map_data[grid_pos]["visited"] = true
		map_updated.emit()

func notify_player_moved(grid_pos: Vector2i) -> void:
	if player_grid_pos != grid_pos:
		player_grid_pos = grid_pos
		map_updated.emit()
