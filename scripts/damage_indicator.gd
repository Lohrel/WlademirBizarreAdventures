extends Node2D

func setup(text: String, color: Color = Color.WHITE):
	var label = $Label
	label.text = text
	label.modulate = color
	
	# Randomize direction a bit
	var direction = Vector2(randf_range(-20, 20), -40)
	var final_pos = position + direction
	
	var tween = create_tween()
	tween.set_parallel(true)
	# Godot 4 Tween constants: TRANS_CUBIC, EASE_OUT
	tween.tween_property(self, "position", final_pos, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.2)
	
	# Simple pop effect
	scale = Vector2(0.5, 0.5)
	var pop_tween = create_tween()
	pop_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	pop_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	tween.finished.connect(queue_free)
