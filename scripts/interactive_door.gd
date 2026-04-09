extends StaticBody2D

var is_player_near = false
var is_open = false

@onready var animation_player = $AnimationPlayer
@onready var interaction_label = $InteractionLabel
@onready var collision_shape = $CollisionShape2D
@onready var occluder = $LightOccluder2D

func _ready():
	interaction_label.visible = false

func _input(event):
	if is_player_near and not is_open:
		var is_e_pressed = false
		if event is InputEventKey:
			if event.pressed and not event.is_echo() and event.keycode == KEY_E:
				is_e_pressed = true
		
		if is_e_pressed or event.is_action_pressed("interact"):
			open_door()

func open_door():
	is_open = true
	interaction_label.visible = false
	if animation_player.has_animation("open"):
		animation_player.play("open")
	else:
		# Fallback if no animation
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.finished.connect(queue_free)
	
	collision_shape.disabled = true
	occluder.visible = false

func _on_detection_area_body_entered(body):
	if body.is_in_group("player") or body.name.to_lower() == "player":
		is_player_near = true
		if not is_open:
			interaction_label.visible = true

func _on_detection_area_body_exited(body):
	if body.is_in_group("player") or body.name.to_lower() == "player":
		is_player_near = false
		interaction_label.visible = false
