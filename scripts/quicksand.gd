extends Area2D

@export var slowdown_multiplier = 0.25

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_generate_random_shape()

func _generate_random_shape():
	var points = PackedVector2Array()
	var num_points = randi_range(5, 8)
	var base_radius = randf_range(40, 80)
	
	for i in range(num_points):
		var angle = (float(i) / num_points) * TAU
		var r = base_radius * randf_range(0.6, 1.2)
		points.append(Vector2(cos(angle), sin(angle)) * r)
	
	$Polygon2D.polygon = points
	$CollisionPolygon2D.polygon = points

func _on_body_entered(body):
	if body.is_in_group("player") or body.name.to_lower() == "player":
		body.speed_multiplier = slowdown_multiplier

func _on_body_exited(body):
	if body.is_in_group("player") or body.name.to_lower() == "player":
		body.speed_multiplier = 1.0
