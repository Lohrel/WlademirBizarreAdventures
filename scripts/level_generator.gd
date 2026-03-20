extends Node2D

@export var room_scene: PackedScene # Onde vamos arrastar o Room.tscn no Inspector
@export var player_scene: PackedScene # Onde vamos arrastar o Player.tscn
const ROOM_SIZE = Vector2(400, 400) # O tamanho/espaçamento entre as salas

var map_data = {} 
var max_rooms = 15 
var current_level = 1 # Nível atual da dungeon (1 a 3)

# Variável que controla o ciclo do dia (0.0 a 2*PI)
var sun_time = 0.0
# Velocidade do dia
@export var day_speed = 0.15 

# Referência para o jogador para não deletá-lo entre níveis
var player_node = null

func _ready():
	generate_new_level()

func _process(delta):
	sun_time += delta * day_speed

func generate_new_level():
	# 1. Limpa salas antigas (se houver)
	for child in get_children():
		if child.name.begins_with("Room"):
			child.queue_free()
	
	# 2. Reseta os dados do mapa
	map_data.clear()
	
	# 3. Gera a lógica matemática do novo andar
	generate_map_data()
	
	# 4. Constrói o visual
	build_world()
	
	# 5. Garante que o jogador existe e está na entrada
	spawn_or_reset_player()

func generate_map_data():
	var current_position = Vector2i(0, 0)
	map_data[current_position] = "start" # Sala de entrada
	
	var rooms_created = 1
	while rooms_created < max_rooms:
		var direction = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].pick_random()
		current_position += direction
		
		if not map_data.has(current_position):
			map_data[current_position] = "normal"
			rooms_created += 1
	
	# Identifica a sala mais distante para ser o BOSS
	var furthest_pos = Vector2i.ZERO
	var max_dist = 0
	for pos in map_data.keys():
		var dist = abs(pos.x) + abs(pos.y)
		if dist > max_dist:
			max_dist = dist
			furthest_pos = pos
	map_data[furthest_pos] = "boss"

func build_world():
	for grid_pos in map_data.keys():
		var room_instance = room_scene.instantiate()
		room_instance.position = Vector2(grid_pos.x * ROOM_SIZE.x, grid_pos.y * ROOM_SIZE.y)
		
		var has_north = map_data.has(grid_pos + Vector2i.UP)
		var has_south = map_data.has(grid_pos + Vector2i.DOWN)
		var has_east = map_data.has(grid_pos + Vector2i.RIGHT)
		var has_west = map_data.has(grid_pos + Vector2i.LEFT)
		
		add_child(room_instance)

		# Regra de Sol: Boss e Start nunca têm sol. Outras têm 30% de chance.
		var is_open = false
		if map_data[grid_pos] == "normal":
			is_open = randf() < 0.3
		
		# Passa o tipo da sala para o setup
		room_instance.setup_room(has_north, has_south, has_east, has_west, is_open)
		# Vamos adicionar um marcador visual para o Boss para teste
		if map_data[grid_pos] == "boss":
			room_instance.modulate = Color(1, 0.5, 0.5) # Sala do Boss fica avermelhada

func spawn_or_reset_player():
	if player_node == null:
		player_node = player_scene.instantiate()
		player_node.name = "Player"
		add_child(player_node)
	
	player_node.position = Vector2.ZERO
