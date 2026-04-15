## Gerador de nível procedural para Wlademir's Bizarre Adventures.
## Gerencia o layout das salas, posicionamento de chefes e construção do mundo.
class_name LevelGenerator
extends Node2D

# --- Cenas Exportadas ---
@export_group("Scenes")
@export var room_scene: PackedScene
@export var player_scene: PackedScene
@export var boss_scene: PackedScene 
@export var upgrade_screen_scene: PackedScene

# --- Configuração ---
@export_group("Level Config")
@export var max_rooms: int = 15 
@export var day_speed: float = 0.15 
const ROOM_SIZE = Vector2(400, 400)

# --- Variáveis de Tempo de Execução ---
var map_data = {} # Chave: Vector2i (pos. da grade), Valor: Dictionary (tipo e tamanho)
var current_level: int = 1
var sun_time: float = 0.0
var player_node: Node2D = null

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
	
	# Limpa as salas existentes
	for child in get_children():
		if child.name.begins_with("Room"):
			child.queue_free()
	
	map_data.clear()
	col_widths.clear()
	row_heights.clear()
	
	# Gera o layout do andar e constrói o visual
	_generate_map_layout()
	_build_world_visuals()
	
	# Redefine o jogador para a posição inicial
	_spawn_or_reset_player()

## Usa um algoritmo de "random walk" para gerar o layout das salas.
func _generate_map_layout() -> void:
	var current_position = Vector2i(0, 0)
	
	map_data[current_position] = {"type": "start"}
	
	var rooms_created = 1
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	while rooms_created < max_rooms:
		var dir = directions.pick_random()
		current_position += dir
		
		if not map_data.has(current_position):
			map_data[current_position] = {"type": "normal"}
			rooms_created += 1
	
	# Designa a sala mais distante como a sala do Chefe
	var furthest_pos = Vector2i.ZERO
	var max_dist = 0
	for pos in map_data.keys():
		var dist = abs(pos.x) + abs(pos.y)
		if dist > max_dist:
			max_dist = dist
			furthest_pos = pos
	
	map_data[furthest_pos]["type"] = "boss"
	
	# Atribui larguras para colunas e alturas para linhas baseadas nas salas
	for pos in map_data.keys():
		if not col_widths.has(pos.x):
			col_widths[pos.x] = [300, 400, 600, 800].pick_random()
		if not row_heights.has(pos.y):
			row_heights[pos.y] = [300, 400, 600, 800].pick_random()
		
		# Salva o tamanho final na sala
		map_data[pos]["size"] = Vector2(col_widths[pos.x], row_heights[pos.y])

## Instancia as cenas das salas e as conecta.
func _build_world_visuals() -> void:
	var spawned_doors = {} # Rastreia conexões únicas para evitar portas duplicadas
	
	for grid_pos in map_data.keys():
		var room_info = map_data[grid_pos]
		var room_instance = room_scene.instantiate()
		
		# Calcula a posição física acumulando larguras/alturas
		room_instance.position = _get_physical_position(grid_pos)
		add_child(room_instance)
		
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
		# Nível 1: 0-2 inimigos, Nível 2: 1-3, etc.
		var min_enemies = clampi(current_level - 1, 0, 5)
		var max_enemies = clampi(current_level + 1, 1, 8)

		# Configura o tamanho, visuais, conexões e inimigos da sala
		room_instance.setup_room_ext(room_info["size"], has_n, has_s, has_e, has_w, is_open, 
				spawn_n, spawn_s, spawn_e, spawn_w, min_enemies, max_enemies)

		
		# Gerencia a configuração específica da sala do Chefe
		if room_info["type"] == "boss":
			room_instance.modulate = Color(1, 0.5, 0.5) # Dica visual para o Chefe
			if boss_scene:
				var boss = boss_scene.instantiate()
				boss.position = room_instance.position
				boss.boss_died.connect(_on_boss_died)
				add_child(boss)

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
	
	if not record.has(key):
		# 35% de chance de colocar uma porta se ela ainda não existir
		var spawn = randf() < 0.35
		record[key] = spawn
		return spawn
	
	return false

# --- Gerenciamento do Jogador ---

func _spawn_or_reset_player() -> void:
	if player_node == null:
		player_node = player_scene.instantiate()
		player_node.name = "Player"
		add_child(player_node)
	
	# Redefine a posição raiz
	player_node.position = Vector2.ZERO
	
	# Redefine a posição interna do CharacterBody2D
	if player_node.has_node("player"):
		player_node.get_node("player").position = Vector2.ZERO

# --- Manipuladores de Sinais ---

func _on_boss_died() -> void:
	# Breve pausa cinematográfica antes de mostrar a tela de upgrade
	await get_tree().create_timer(1.5).timeout
	
	if upgrade_screen_scene:
		var screen = upgrade_screen_scene.instantiate()
		add_child(screen)
		
		# Configura a lógica de upgrade
		var control = screen.get_node("Control")
		control.setup(player_node, self)
