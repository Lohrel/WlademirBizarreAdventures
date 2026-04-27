## Componente de UI para o Minimapa.
## Desenha o layout com estética circular e tons de cinza.
extends Control

@export var cell_size: float = 12.0
@export var padding: float = 4.0

# Cores em Tons de Cinza (mais escuro e menos intrusivo)
const COLOR_BG = Color(0.1, 0.1, 0.1, 0.7) 
const COLOR_ROOM = Color(0.4, 0.4, 0.4, 0.8) 
const COLOR_START = Color(0.2, 0.8, 0.2, 0.9) 
const COLOR_BOSS = Color(0.8, 0.2, 0.2, 0.9) 
const COLOR_EXIT = Color(0.2, 0.2, 0.8, 0.9) 
const COLOR_CORRIDOR = Color(0.2, 0.2, 0.2, 0.7) 
const COLOR_BORDER = Color(1.0, 1.0, 1.0, 0.5) # Borda branca translúcida

var map_data: Dictionary = {}
var player_pos: Vector2i = Vector2i.ZERO

func _ready() -> void:
	var gen = get_tree().root.find_child("LevelGenerator", true, false)
	if gen:
		gen.map_updated.connect(_on_map_updated)
		_sync_data(gen)

func _sync_data(gen: Node) -> void:
	map_data = gen.map_data
	player_pos = gen.player_grid_pos
	queue_redraw()

func _on_map_updated() -> void:
	var gen = get_tree().root.find_child("LevelGenerator", true, false)
	if gen:
		_sync_data(gen)

func _draw() -> void:
	var center = size / 2.0
	var radius = size.x / 2.0
	
	# 1. Desenha o fundo circular (Cinza Escuro)
	draw_circle(center, radius, COLOR_BG)
	
	if map_data.is_empty(): return
	
	# 2. Desenha as salas filtrando pelo raio circular
	for pos in map_data.keys():
		var info = map_data[pos]
		if not info.get("visited", false): continue
		
		var relative_x = (pos.x - player_pos.x) * (cell_size + padding)
		var relative_y = (pos.y - player_pos.y) * (cell_size + padding)
		
		var draw_pos = center + Vector2(relative_x, relative_y)
		
		if draw_pos.distance_to(center) > radius - cell_size/2.0:
			continue
		
		var rect = Rect2(draw_pos - Vector2(cell_size, cell_size) / 2.0, Vector2(cell_size, cell_size))
		var color = COLOR_ROOM
		
		match info["type"]:
			"start": color = COLOR_START
			"boss": color = COLOR_BOSS
			"exit": color = COLOR_EXIT
			"corridor": 
				color = COLOR_CORRIDOR
				var c_size = cell_size * 0.7
				rect = Rect2(draw_pos - Vector2(c_size, c_size) / 2.0, Vector2(c_size, c_size))
			
		draw_rect(rect, color)
		draw_rect(rect, Color(1, 1, 1, 0.1), false, 1.0)
		
	# 3. Desenha o ícone do Wlademir (Ponto Branco central)
	draw_circle(center, 3.0, Color.WHITE)
	
	# 4. Borda "Pixelada"
	_draw_pixel_border(center, radius)

func _draw_pixel_border(center: Vector2, radius: float) -> void:
	var points = 32
	var step = TAU / points
	for i in range(points):
		var angle_a = i * step
		var angle_b = (i + 1) * step
		var pa = center + Vector2(cos(angle_a), sin(angle_a)) * radius
		var pb = center + Vector2(cos(angle_b), sin(angle_b)) * radius
		draw_line(pa, pb, COLOR_BORDER, 2.0)
