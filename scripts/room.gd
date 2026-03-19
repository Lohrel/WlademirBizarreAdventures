extends Node2D

@onready var door_north = $DoorNorth
@onready var door_south = $DoorSouth
@onready var door_east = $DoorEast
@onready var door_west = $DoorWest
@onready var sunlight = $Sunlight

# Pré-carregamento dos objetos para a geração procedural
var pillar_scene = preload("res://scenes/pillar.tscn")
var box_scene = preload("res://scenes/box.tscn")

# Variável que guarda se a sala tem teto aberto (usado para movimentar o sol)
var has_open_ceiling = false

func setup_room(has_north: bool, has_south: bool, has_east: bool, has_west: bool, is_open: bool):
	# Salva se a sala tem teto aberto
	has_open_ceiling = is_open
	
	# Se tem vizinho (has_north = true), a porta fica INVISÍVEL e SEM COLISÃO (aberta)
	# Se não tem vizinho, a porta fica VISÍVEL e COM COLISÃO (parede fechada)
	door_north.visible = !has_north
	door_north.get_node("CollisionShape2D").disabled = has_north
	
	door_south.visible = !has_south
	door_south.get_node("CollisionShape2D").disabled = has_south
	
	door_east.visible = !has_east
	door_east.get_node("CollisionShape2D").disabled = has_east
	
	door_west.visible = !has_west
	door_west.get_node("CollisionShape2D").disabled = has_west
	
	sunlight.visible = is_open
	
	# Só gera objetos se a sala NÃO for a inicial (0,0) para não prender o player
	if global_position != Vector2.ZERO:
		spawn_procedural_objects(is_open)

func spawn_procedural_objects(is_sunlight_room: bool):
	# Tenta spawnar entre 1 e 3 pilastras em cantos aleatórios
	var corner_positions = [
		Vector2(-60, -60), Vector2(60, -60),
		Vector2(-60, 60), Vector2(60, 60)
	]
	corner_positions.shuffle()
	
	for i in range(randi_range(1, 3)):
		var p = pillar_scene.instantiate()
		p.position = corner_positions[i]
		add_child(p)
	
	# Tenta spawnar caixas em posições aleatórias (mas não no centro se tiver sol)
	for i in range(randi_range(2, 5)):
		var b = box_scene.instantiate()
		var random_pos = Vector2(randf_range(-70, 70), randf_range(-70, 70))
		
		# Se a sala tem sol, evita colocar caixas no meio (onde o sol bate)
		if is_sunlight_room and random_pos.length() < 50:
			continue
			
		b.position = random_pos
		add_child(b)

func setup_doors(has_north, has_south, has_east, has_west):
	setup_room(has_north, has_south, has_east, has_west, false)

func _process(_delta):
	# Se a sala NÃO tem teto aberto, não fazemos nada
	if not has_open_ceiling:
		return
		
	# Pega o tempo do sol no LevelGenerator (pai)
	var generator = get_parent()
	if generator and "sun_time" in generator:
		var st = generator.sun_time
		
		# Cálculo da ELIPSE (60 pixels de largura, 40 de altura)
		var tx = cos(st) * 60.0
		var ty = sin(st) * 40.0
		
		# Posiciona o nó de luz
		sunlight.position = Vector2(tx, ty)
		
		# Noite (se o Y for muito negativo, o sol "some")
		if ty < -30:
			sunlight.modulate.a = lerp(sunlight.modulate.a, 0.0, 0.05)
		else:
			sunlight.modulate.a = lerp(sunlight.modulate.a, 1.0, 0.05)
