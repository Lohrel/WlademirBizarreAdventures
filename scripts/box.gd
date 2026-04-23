extends RigidBody2D

func take_damage(_amount: float, _source_pos: Vector2 = Vector2.ZERO, _knockback: float = 0.0):
	# Boxes are destroyed immediately by projectiles or heavy hits
	destroy()

func destroy():
	# Visual effect (optional: could spawn particles here)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.finished.connect(queue_free)
