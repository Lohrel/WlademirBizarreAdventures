extends StaticBody2D

@export var health: float = 50.0

@onready var sprite = $Sprite2D

var blood_scene = preload("res://scenes/blood_particles.tscn")

func take_damage(amount: float):
	# health -= amount # Comentado para testes (imortal)
	
	# Blood effect
	var blood = blood_scene.instantiate()
	get_parent().add_child(blood)
	blood.global_position = global_position
	blood.emitting = true
	# Limpa o node de partículas depois que terminar
	get_tree().create_timer(blood.lifetime).timeout.connect(blood.queue_free)

	# Efeito visual de tremor
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	
	# Pequeno pulo/escala (agora relativo à escala original de 0.15)
	var tween_scale = create_tween()
	var base_scale = Vector2(0.15, 0.15)
	tween_scale.tween_property(sprite, "scale", base_scale * 1.2, 0.05)
	tween_scale.tween_property(sprite, "scale", base_scale, 0.1)
	
	# if health <= 0:
	#	die()

func die():
	# Efeito de morte simples
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		take_damage(10.0)
