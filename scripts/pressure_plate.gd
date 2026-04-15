extends Area2D

@export var dart_scene = preload("res://scenes/venom_dart.tscn")
@export var cooldown: float = 2.0
@export var dart_speed: float = 350.0

var _can_fire: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Quase a cor do chão (um pouco mais escuro)
	$BaseVisual.color = Color(0.55, 0.43, 0.3, 1)

func _on_body_entered(body: Node2D) -> void:
	if _can_fire and body.has_method("take_damage"):
		_trigger_trap()

func _trigger_trap() -> void:
	_can_fire = false

	# Feedback visual: placa afunda (fica mais escura)
	$BaseVisual.color = Color(0.45, 0.35, 0.2, 1)

	
	# Atira dardos em 4 direções
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for dir in directions:
		_fire_dart(dir)
	
	# Cooldown para reativar
	get_tree().create_timer(cooldown).timeout.connect(_reset_trap)

func _fire_dart(dir: Vector2) -> void:
	var dart = dart_scene.instantiate()
	dart.direction = dir
	dart.speed = dart_speed
	# Define a posição relativa ao pai antes de adicionar
	dart.position = get_parent().to_local(global_position)
	# Adiciona ao pai (Room) de forma diferida para evitar erros de física
	get_parent().add_child.call_deferred(dart)

func _reset_trap() -> void:
	_can_fire = true
	$BaseVisual.color = Color(0.55, 0.43, 0.3, 1)
