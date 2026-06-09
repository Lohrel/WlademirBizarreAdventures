extends CanvasLayer

@onready var sky = $Sky
@onready var nebula = $NebulaGlow
@onready var stars = $Stars
@onready var twinkling_stars = $TwinklingStars

# Cores para o ciclo
var night_color = Color(0.02, 0.02, 0.05, 1.0)
var day_color = Color(0.4, 0.6, 0.9, 1.0) # Azul claro

func _process(_delta: float) -> void:
	var gen = get_tree().root.find_child("LevelGenerator", true, false)
	if not gen or not "sun_time" in gen: return
	
	var st = fmod(gen.sun_time, TAU)
	var s_val = sin(st) # > 0 é dia, < 0 é noite
	
	# Mapeia s_val (-1 a 1) para um fator de dia (0 a 1)
	var day_factor = (s_val + 1.0) / 2.0
	
	# Interpola a cor do céu
	sky.color = night_color.lerp(day_color, day_factor)
	
	# Esconde estrelas e nebulosa durante o dia
	var night_factor = 1.0 - day_factor
	nebula.modulate.a = 0.15 * night_factor
	stars.modulate.a = night_factor
	twinkling_stars.modulate.a = night_factor
	
	# Otimização: desativa partículas se estiverem totalmente invisíveis
	stars.emitting = night_factor > 0.1
	twinkling_stars.emitting = night_factor > 0.1
