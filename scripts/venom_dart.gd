extends Area2D

@export var speed: float = 400.0
@export var damage: float = 10.0
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
		# Se for o jogador, podemos adicionar um efeito de veneno futuramente
		if body.is_in_group("player"):
			_apply_venom_effect(body)
	
	# Desaparece ao atingir qualquer corpo (exceto se ignorarmos o atirador)
	queue_free()

func _apply_venom_effect(player: Node2D) -> void:
	# Efeito visual simples de veneno
	var tween = player.create_tween()
	player.modulate = Color(0.5, 1.0, 0.5) # Esverdeado
	tween.tween_property(player, "modulate", Color(1, 1, 1), 1.0)
	
	# Dano extra ao longo do tempo (DOT)
	for i in range(3):
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(player):
			player.take_damage(2.0)
