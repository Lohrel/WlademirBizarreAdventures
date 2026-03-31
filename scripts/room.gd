extends Node2D

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

# Pré-carregamento dos objetos para a geração procedural
var pillar_scene = preload("res://scenes/pillar.tscn")
var box_scene = preload("res://scenes/box.tscn")

# Variável que guarda se a sala tem teto aberto (usado para movimentar o sol)
var has_open_ceiling = false

func _ready():
	# Criamos texturas de alta definição (512px)
	sunlight.texture = create_safe_radial_texture(512)
	moonlight.texture = create_radial_blue_texture(512)
	firefly_light.texture = create_safe_radial_texture(64)
	
	# Ajusta os tamanhos visuais
	sunlight.texture_scale = 1.2
	moonlight.texture_scale = 1.0
	firefly_light.texture_scale = 1.0

func create_safe_radial_texture(size: int) -> GradientTexture2D:
	var grad = Gradient.new()
	grad.offsets = [0.0, 0.8]
	grad.colors = [Color(1,1,1,1), Color(1,1,1,0)]
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.use_hdr = true
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5) 
	tex.width = size
	tex.height = size
	return tex

func create_radial_blue_texture(size: int) -> GradientTexture2D:
	var grad = Gradient.new()
	grad.offsets = [0.0, 0.8]
	grad.colors = [Color(0.5, 0.7, 1, 1), Color(0.5, 0.7, 1, 0)]
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.use_hdr = true
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5) 
	tex.width = size
	tex.height = size
	return tex

func setup_room(has_north: bool, has_south: bool, has_east: bool, has_west: bool, is_open: bool):
	has_open_ceiling = is_open
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
	
	fireflies.position = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	fireflies.emitting = false 
	
	if global_position != Vector2.ZERO:
		spawn_procedural_objects(is_open)

func spawn_procedural_objects(is_sunlight_room: bool):
	var corners = [Vector2(-140, -140), Vector2(140, -140), Vector2(-140, 140), Vector2(140, 140)]
	corners.shuffle()
	for i in range(randi_range(1, 3)):
		var pos = corners[i]
		var p = pillar_scene.instantiate()
		p.position = pos
		add_child(p)
		if randf() < 0.4:
			p.setup_torch(pos.y < 0)
	
	for i in range(randi_range(3, 8)):
		var b = box_scene.instantiate()
		var rpos = Vector2(randf_range(-160, 160), randf_range(-160, 160))
		if is_sunlight_room and rpos.length() < 80: continue
		b.position = rpos
		add_child(b)

func setup_doors(has_north, has_south, has_east, has_west):
	setup_room(has_north, has_south, has_east, has_west, false)

func _process(_delta):
	if not has_open_ceiling: return
	var gen = get_parent()
	if gen and "sun_time" in gen:
		var st = fmod(gen.sun_time, TAU)
		
		# --- SOL ---
		var s_val = sin(st)
		if s_val > 0.0:
			sunlight.visible = true
			sunlight.position.x = -cos(st) * 120.0
			sunlight.color = Color(1, 0.98, 0.85)
			# Transição suave de energia
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
			
		# --- LUA E VAGALUMES ---
		var m_st = fmod(st + PI, TAU)
		var m_val = sin(m_st)
		if m_val > 0.4:
			moonlight.visible = true
			moonlight.position.x = -cos(m_st) * 120.0
			moonlight.energy = (m_val - 0.4) * 1.5 
			fireflies.emitting = true
			if not moon_audio.playing: moon_audio.play()
			
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
