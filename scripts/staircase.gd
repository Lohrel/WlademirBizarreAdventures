## Uma escada que leva o jogador para o próximo andar.
## Só aparece ou torna-se interativa após a derrota do chefe.
class_name Staircase
extends StaticBody2D

# --- Variáveis de Estado ---
var is_player_near: bool = false

# --- Referências ---
@onready var interaction_label = $InteractionLabel

func _ready() -> void:
	interaction_label.visible = false
	add_to_group("staircase")

func _input(event: InputEvent) -> void:
	if is_player_near:
		if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
			_go_to_next_level()

func _go_to_next_level() -> void:
	var gen = get_tree().root.find_child("LevelGenerator", true, false)
	if gen and gen.has_method("generate_new_level"):
		# Feedback visual antes de trocar
		var player_root = get_tree().get_first_node_in_group("player")
		if player_root:
			var p_char = player_root.get_node_or_null("player")
			if p_char:
				var tween = create_tween()
				tween.tween_property(p_char, "modulate:a", 0.0, 0.5)
				var sprite = p_char.get_node_or_null("Sprite2D")
				if sprite:
					var tween_s = create_tween()
					tween_s.tween_property(sprite, "modulate:a", 0.0, 0.5)
		
		await get_tree().create_timer(0.6).timeout
		gen.generate_new_level()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name.to_lower() == "player":
		is_player_near = true
		interaction_label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name.to_lower() == "player":
		is_player_near = false
		interaction_label.visible = false
