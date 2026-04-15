extends Area2D

@export var speed: float = 400.0
@export var damage: float = 10.0
@export var poison_duration: float = 5.0
@export var poison_percent: float = 0.25 # 25% da vida máxima
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Auto-destruição após um tempo
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
		# Aplica veneno se for o jogador
		if body.is_in_group("player") and body.has_method("apply_poison"):
			var poison_damage = body.max_health * poison_percent
			body.apply_poison(poison_damage, poison_duration)
	
	# Desaparece ao atingir qualquer corpo
	queue_free()
