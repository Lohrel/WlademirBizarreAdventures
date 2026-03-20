extends Node2D

@onready var door_north = $DoorNorth
@onready var door_south = $DoorSouth
@onready var door_east = $DoorEast
@onready var door_west = $DoorWest
@onready var sunlight = $Sunlight
@onready var moonlight = $Moonlight
@onready var fireflies = $Fireflies
@onready var firefly_light = $Fireflies/FireflyLight

# Pré-carregamento dos objetos para a geração procedural
var pillar_scene = preload("res://scenes/pillar.tscn")
var box_scene = preload("res://scenes/box.tscn")

# Variável que guarda se a sala tem teto aberto (usado para movimentar o sol)
var has_open_ceiling = false

func _ready():
	# Força a luz dos vagalumes a ser circular e suave (conserta o bug do quadrado)
	var grad = Gradient.new()
	grad.offsets = [0.0, 0.8]
	grad.colors = [Color(1,1,1,1), Color(1,1,1,0)]
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 64
	tex.height = 64
	
	firefly_light.texture = tex

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
	moonlight.visible = is_open
	
	# Posiciona os vagalumes em um lugar central da sala (longe das paredes)
	fireflies.position = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	fireflies.emitting = false # Começam desligados
	
	# Só gera objetos se a sala NÃO for a inicial (0,0) para não prender o player
	if global_position != Vector2.ZERO:
		spawn_procedural_objects(is_open)

func spawn_procedural_objects(is_sunlight_room: bool):
	# Tenta spawnar entre 1 e 3 pilastras em cantos aleatórios (Dobrados para 140)
	var corner_positions = [
		Vector2(-140, -140), Vector2(140, -140),
		Vector2(-140, 140), Vector2(140, 140)
	]
	corner_positions.shuffle()
	
	for i in range(randi_range(1, 3)):
		var p = pillar_scene.instantiate()
		p.position = corner_positions[i]
		add_child(p)
	
	# Tenta spawnar caixas em posições aleatórias (área maior de 160)
	for i in range(randi_range(3, 8)):
		var b = box_scene.instantiate()
		var random_pos = Vector2(randf_range(-160, 160), randf_range(-160, 160))
		
		# Se a sala tem sol, evita colocar caixas no meio (onde o sol bate)
		if is_sunlight_room and random_pos.length() < 80:
			continue
			
		b.position = random_pos
		add_child(b)

func setup_doors(has_north, has_south, has_east, has_west):
	setup_room(has_north, has_south, has_east, has_west, false)

func _process(_delta):
	if not has_open_ceiling:
		return
		
	var generator = get_parent()
	if generator and "sun_time" in generator:
		# O st vai de 0 até 2*PI (aprox 6.28)
		# Vamos usar o fmod para garantir que o tempo resete corretamente
		var st = fmod(generator.sun_time, TAU) 
		
		# --- CICLO DO SOL (Brilha entre 0.5 e 2.6) ---
		var sun_val = sin(st)
		if sun_val > 0.3: # Só liga se o sol estiver "alto"
			sunlight.visible = true
			sunlight.position.x = -cos(st) * 120.0
			sunlight.energy = (sun_val - 0.3) * 3.0
		else:
			sunlight.visible = false
		
		# --- CICLO DA LUA (Brilha entre 3.6 e 5.8) ---
		# A lua é o oposto (st + PI)
		var moon_st = fmod(st + PI, TAU)
		var moon_val = sin(moon_st)
		
		if moon_val > 0.4: # Só liga se a lua estiver "alta"
			moonlight.visible = true
			moonlight.position.x = -cos(moon_st) * 120.0
			moonlight.energy = (moon_val - 0.4) * 1.8
			fireflies.emitting = true
			
			# --- MÁSCARA DE LUZ ---
			# Verifica a distância entre os vagalumes e a posição da LUA
			var dist = abs(fireflies.position.x - moonlight.position.x)
			if dist < 80: # Se estiver dentro do feixe (largura aproximada de 80px)
				firefly_light.visible = true
				firefly_light.energy = (0.3 + randf() * 0.3) * (1.0 - dist/80.0)
			else:
				firefly_light.visible = false
		else:
			moonlight.visible = false
			fireflies.emitting = false
			firefly_light.visible = false
