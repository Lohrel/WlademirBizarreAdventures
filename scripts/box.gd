extends RigidBody2D

var is_thrown = false
var throw_damage = 25.0

func _ready():
	# Habilita monitoramento de contatos para detectar o jogador quando arremessado
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)

func take_damage(_amount: float, _source_pos: Vector2 = Vector2.ZERO, _knockback: float = 0.0):
	# Boxes are destroyed immediately by projectiles or heavy hits
	destroy()

func destroy():
	if is_thrown:
		_explode()
	else:
		# Visual effect for normal destruction
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.finished.connect(queue_free)

func _explode():
	# Visual explosion effect
	var visual = Node2D.new()
	get_parent().add_child(visual)
	visual.global_position = global_position
	
	# Circular explosion visual
	var circle = Polygon2D.new()
	var points = PackedVector2Array()
	var num_points = 16
	for i in range(num_points):
		var angle = i * TAU / num_points
		points.append(Vector2(cos(angle), sin(angle)) * 10)
	circle.polygon = points
	circle.color = Color(0.8, 0.4, 0.1, 0.8) # Brownish orange
	visual.add_child(circle)
	
	var tween = visual.create_tween()
	tween.set_parallel(true)
	tween.tween_property(circle, "scale", Vector2(4.0, 4.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(circle, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(visual.queue_free)
	
	queue_free()

func _create_radial_texture(size: int) -> GradientTexture2D:
	var grad = Gradient.new()
	grad.offsets = [0.0, 0.8]
	grad.colors = [Color.WHITE, Color(1, 1, 1, 0)]
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.use_hdr = true
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5) 
	tex.width = size
	tex.height = size
	return tex

func throw(direction: Vector2, speed: float, damage: float):
	is_thrown = true
	throw_damage = damage
	# Aplica um impulso forte
	apply_central_impulse(direction * speed)
	
	# Auto-destruição após um tempo se não atingir nada
	get_tree().create_timer(2.0).timeout.connect(func(): if is_instance_valid(self): is_thrown = false)

func _on_body_entered(body: Node):
	if is_thrown:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(throw_damage)
			destroy()
		elif not body.is_in_group("boss"): 
			# Se atingir uma parede (Geralmente StaticBody2D ou TileMap) ou outro objeto sólido
			destroy()
