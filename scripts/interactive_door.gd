## Uma porta que pode ser interagida pelo jogador.
## Permanece fechada até que o jogador se aproxime e pressione a tecla de interação.
class_name InteractiveDoor
extends StaticBody2D

# --- Variáveis de Estado ---
var is_player_near: bool = false
var is_open: bool = false
var is_locked: bool = false

# --- Nós Onready ---
@onready var animation_player = $AnimationPlayer
@onready var interaction_label = $InteractionLabel
@onready var collision_shape = $CollisionShape2D
@onready var occluder = $LightOccluder2D

# --- Ciclo de Vida ---

func _ready() -> void:
	interaction_label.visible = false
	
	# Verifica se o jogador já está dentro da área ao surgir (adiado para garantir que os nós estejam prontos)
	call_deferred("_check_initial_overlap")

func _input(event: InputEvent) -> void:
	# Só processa a entrada se o jogador estiver perto e a porta estiver fechada
	if is_player_near and not is_open:
		var is_interact_pressed = false
		if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_E):
			is_interact_pressed = true
			
		if is_interact_pressed:
			if is_locked:
				_show_locked_message()
			else:
				_open_door()

# --- Lógica de Interação ---

func lock() -> void:
	is_locked = true
	modulate = Color(0.5, 0.5, 0.5)

func unlock() -> void:
	is_locked = false
	modulate = Color(1, 1, 1)
	if is_player_near:
		interaction_label.text = "[E] Open"
		interaction_label.visible = true

func _show_locked_message() -> void:
	interaction_label.text = "Locked"
	interaction_label.visible = true
	var tween = create_tween()
	tween.tween_property(interaction_label, "modulate", Color(1, 0, 0), 0.1)
	tween.tween_property(interaction_label, "modulate", Color(1, 1, 1), 0.1)

## Verifica se o jogador já está sobreposto à área de detecção no início.
func _check_initial_overlap() -> void:
	var bodies = $DetectionArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") or body.name.to_lower() == "player":
			is_player_near = true
			if not is_open:
				interaction_label.visible = true
			break

## Gerencia a sequência de abertura da porta.
func _open_door() -> void:
	is_open = true
	interaction_label.visible = false
	
	if animation_player.has_animation("open"):
		animation_player.play("open")
	else:
		# Fallback simples de fade-out
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.finished.connect(queue_free)
	
	# Desativa física e oclusão de luz uma vez aberta
	collision_shape.disabled = true
	occluder.visible = false

# --- Manipuladores de Sinais ---

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name.to_lower() == "player":
		is_player_near = true
		if not is_open:
			interaction_label.text = "Locked" if is_locked else "[E] Open"
			interaction_label.visible = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name.to_lower() == "player":
		is_player_near = false
		interaction_label.visible = false
