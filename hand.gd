extends Sprite2D

@export var distancia := 20

func _physics_process(delta: float) -> void:
	var player = get_parent().get_parent()
	
	var dir = (get_global_mouse_position() - player.global_position).normalized()
	
	global_position = player.global_position + dir * distancia
	
	look_at(get_global_mouse_position())
	
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	
	if not player._is_attacking:
		if rotation_degrees > 90 and rotation_degrees < 270:
			scale.y = -1
		else:
			scale.y = 1
