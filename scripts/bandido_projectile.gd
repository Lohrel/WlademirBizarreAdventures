extends Area2D

@export var speed: float = 450.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var source: Node2D = null

func _ready() -> void:
	# Garante que o visual está correto
	var sprite = get_node_or_null("Sprite2D")
	if sprite and sprite.texture == null:
		sprite.texture = preload("res://assets/sprites/bandido_arma/projetil_bandido.png")
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# Auto-destruction after some time
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	# Rotate to movement direction
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body == source:
		return
	
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
	
	_impact_visual()
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.owner == source:
		return
	
	if area.name == "Hurtbox":
		if area.owner.is_in_group("player") and area.owner.has_method("take_damage"):
			area.owner.take_damage(damage)
		_impact_visual()
		queue_free()
	elif area.is_in_group("destructible"):
		# Impact visual but don't damage (don't break boxes)
		_impact_visual()
		queue_free()

func _impact_visual():
	# Simple spark or flash at impact point
	var spark = Node2D.new()
	var sprite = Sprite2D.new()
	# Using icon as a placeholder for spark
	sprite.texture = preload("res://assets/sprites/icon.svg")
	sprite.scale = Vector2(0.05, 0.05)
	spark.add_child(sprite)
	get_parent().add_child(spark)
	spark.global_position = global_position
	
	# Create tween bound to the spark node so it survives bullet deletion
	var tween = spark.create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.1)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
	tween.finished.connect(spark.queue_free)
