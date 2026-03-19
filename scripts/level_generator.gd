extends Node2D

@export var room_scene: PackedScene # Onde vamos arrastar o Room.tscn no Inspector
@export var player_scene: PackedScene # Onde vamos arrastar o Player.tscn
const ROOM_SIZE = Vector2(200, 200) # O tamanho/espaçamento entre as salas

var map_data = {} 
var max_rooms = 15 

# Variável que controla o ciclo do dia (0.0 a 2*PI)
var sun_time = 0.0
# Velocidade do dia (aumente para o dia passar mais rápido)
@export var day_speed = 0.15 

func _ready():
	# Quando o jogo começa, ele gera a matemática e depois constrói o visual
	generate_map_data()
	build_world()
	spawn_player()

func _process(delta):
	# Incrementa o tempo do sol
	sun_time += delta * day_speed

func generate_map_data():
	var current_position = Vector2i(0, 0)
	map_data[current_position] = true 
	
	var rooms_created = 1
	
	while rooms_created < max_rooms:
		var direction = get_random_direction()
		current_position += direction
		
		if not map_data.has(current_position):
			map_data[current_position] = true
			rooms_created += 1

func get_random_direction() -> Vector2i:
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	return directions.pick_random()

func build_world():
	# Lê o Dicionário e cria uma sala para cada coordenada
	for grid_pos in map_data.keys():
		var room_instance = room_scene.instantiate()
		
		# Posiciona a sala no mundo multiplicando a coordenada da grid pelo tamanho da sala
		room_instance.position = Vector2(grid_pos.x * ROOM_SIZE.x, grid_pos.y * ROOM_SIZE.y)
		
		# Verifica quem são os vizinhos dessa sala específica na Grid
		var has_north = map_data.has(grid_pos + Vector2i.UP)
		var has_south = map_data.has(grid_pos + Vector2i.DOWN)
		var has_east = map_data.has(grid_pos + Vector2i.RIGHT)
		var has_west = map_data.has(grid_pos + Vector2i.LEFT)
		
		# Adiciona a sala na tela primeiro para que os nós internos sejam inicializados (@onready)
		add_child(room_instance)

		# Gera uma chance de 30% da sala ter teto aberto
		var is_open = randf() < 0.3
		
		# Envia a instrução para a sala abrir as portas e o teto
		room_instance.setup_room(has_north, has_south, has_east, has_west, is_open)

func spawn_player():
	var player = player_scene.instantiate()
	player.position = Vector2.ZERO # Inicia na sala central (0,0)
	# Definimos o nome do nó como "Player" para facilitar a câmera achá-lo
	player.name = "Player" 
	add_child(player)
