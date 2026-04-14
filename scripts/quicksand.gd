## Uma armadilha ambiental que desacelera o jogador.
## Gera uma forma aleatória e gerencia modificadores de velocidade.
class_name Quicksand
extends Area2D

# --- Atributos Exportados ---
@export var slowdown_multiplier: float = 0.25

# --- Ciclo de Vida ---

func _ready() -> void:
	# Conexões de sinais
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Geração de forma procedural
	_generate_random_shape()

# --- Lógica Procedural ---

## Gera uma forma de polígono aleatória para o poço de areia.
func _generate_random_shape() -> void:
	var points = PackedVector2Array()
	var num_points = randi_range(5, 8)
	var base_radius = randf_range(60, 120) # Aumentado de 40-80 para 60-120
	
	for i in range(num_points):
		var angle = (float(i) / num_points) * TAU
		# Aleatoriza cada ponto levemente para um visual irregular
		var r = base_radius * randf_range(0.6, 1.2)
		points.append(Vector2(cos(angle), sin(angle)) * r)
	
	# Atualiza os polígonos visual e de colisão
	$Polygon2D.polygon = points
	$CollisionPolygon2D.polygon = points

# --- Manipuladores de Sinais ---

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name.to_lower() == "player":
		# Garante que estamos modificando o nó do script PlayerController
		if "speed_multiplier" in body:
			body.speed_multiplier = slowdown_multiplier

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name.to_lower() == "player":
		# Redefine para a velocidade normal
		if "speed_multiplier" in body:
			body.speed_multiplier = 1.0
