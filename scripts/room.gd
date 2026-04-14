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

## Configura o layout da sala, portas e ambiente.
func setup_room(has_n: bool, has_s: bool, has_e: bool, has_w: bool, 
		is_open: bool, 
		spawn_n: bool = false, spawn_s: bool = false, spawn_e: bool = false, spawn_w: bool = false):
	
	has_open_ceiling = is_open
	
	# Visuais de Paredes/Portas Estáticas: visível se NÃO houver vizinho
	door_north.visible = !has_n
	door_north.get_node("CollisionShape2D").disabled = has_n
	
	door_south.visible = !has_s
	door_south.get_node("CollisionShape2D").disabled = has_s
	
	door_east.visible = !has_e
	door_east.get_node("CollisionShape2D").disabled = has_e
	
	door_west.visible = !has_w
	door_west.get_node("CollisionShape2D").disabled = has_w
	
	# Visibilidade da Luz Solar/Luz Lunar
	sunlight.visible = is_open
	moonlight.visible = is_open
	
	# Detalhes ambientais aleatórios
	fireflies.position = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	fireflies.emitting = false 
	
	# Gera objetos procedurais (a menos que seja a primeiríssima sala)
	if global_position != Vector2.ZERO:
		_spawn_procedural_content(is_open)
	
	# Gera Portas Interativas se solicitado pelo LevelGenerator
	if spawn_n: _spawn_interactive_door(Vector2(0, -190), 0)
	if spawn_s: _spawn_interactive_door(Vector2(0, 190), 0)
	if spawn_e: _spawn_interactive_door(Vector2(190, 0), PI/2)
	if spawn_w: _spawn_interactive_door(Vector2(-190, 0), PI/2)

# --- Geração Procedural ---

## Popula a sala com pilares, caixas, inimigos e armadilhas.
func _spawn_procedural_content(is_sunlight_room: bool) -> void:
	# 1. Pilares nos cantos
	var corners = [Vector2(-140, -140), Vector2(140, -140), Vector2(-140, 140), Vector2(140, 140)]
	corners.shuffle()
	for i in range(randi_range(1, 3)):
		var p = pillar_scene.instantiate()
		p.position = corners[i]
		add_child(p)
		if randf() < 0.4:
			p.setup_torch(corners[i].y < 0)
	
	# 2. Caixas Aleatórias
	for i in range(randi_range(3, 8)):
		var b = box_scene.instantiate()
		var rpos = Vector2(randf_range(-160, 160), randf_range(-160, 160))
		# Evita gerar no centro se for uma sala com luz solar
		if is_sunlight_room and rpos.length() < 80: continue
		b.position = rpos
		add_child(b)
		
	# 3. Inimigos (40% de chance)
	if randf() < 0.4:
		var enemy = skeleton_scene.instantiate()
		enemy.position = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		add_child(enemy)
		
	# 4. Armadilhas de Areia Movediça (15% de chance)
	if randf() < 0.15:
		var qs = quicksand_scene.instantiate()
		qs.position = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		add_child(qs)

func _spawn_interactive_door(pos: Vector2, rot: float) -> void:
	var d = door_scene.instantiate()
	d.position = pos
	d.rotation = rot
	add_child(d)

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
