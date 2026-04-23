extends Area2D

@export var speed: float = 250.0
@export var damage: float = 20.0
@export var explosion_radius: float = 40.0
@export var lifetime: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var source: Node2D = null
var animation_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# Auto-destruction after some time
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	# Rotate the sprite to face movement direction
	rotation = direction.angle()
	
	# Simple frame animation
	animation_timer += delta * 10.0
	var total_frames = $Sprite2D.hframes * $Sprite2D.vframes
	$Sprite2D.frame = int(animation_timer) % total_frames

func _on_body_entered(body: Node2D) -> void:
	if body == source:
		return
	_explode()

func _on_area_entered(area: Area2D) -> void:
	if area.owner == source:
		return
	# Ignore own mummy's hitbox/hurtbox if necessary
	# But generally projectiles explode on impact with obstacles
	if area.is_in_group("destructible"):
		_explode()

func _explode():
	# Create a visual explosion effect
	_create_explosion_effect()
	
	# Detect entities in range using an Area2D-like approach but manually
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 3 # Player (2) + Wall/Box (1)
	
	var space_state = get_world_2d().direct_space_state
	var results = space_state.intersect_shape(query)
	
	var hit_bodies = []
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and not body in hit_bodies:
			# Special case: boxes are destroyed immediately
			if body.name.begins_with("Box"):
				if body.has_method("destroy"):
					body.destroy()
				else:
					body.queue_free()
			else:
				body.take_damage(damage)
			hit_bodies.append(body)
			
	# Stop movement while exploding
	set_physics_process(false)
	hide()
	
	# Wait for the visual effect to finish before freeing
	await get_tree().create_timer(0.4).timeout
	queue_free()

func _create_explosion_effect():
	# Simple visual feedback using a circle that expands and fades
	var visual = Node2D.new()
	get_parent().add_child(visual)
	visual.global_position = global_position
	
	# Circular explosion visual using a Polygon2D
	var circle = Polygon2D.new()
	var points = PackedVector2Array()
	var num_points = 16
	for i in range(num_points):
		var angle = i * TAU / num_points
		points.append(Vector2(cos(angle), sin(angle)) * 10)
	circle.polygon = points
	circle.color = Color(1.0, 0.4, 0.0, 0.8) # Bright Orange
	visual.add_child(circle)
	
	# Add a temporary light for the explosion
	var light = PointLight2D.new()
	light.color = Color(1.0, 0.6, 0.2) # Warm sun-like color
	light.energy = 2.0
	light.texture = _create_radial_texture(256)
	light.texture_scale = 0.5
	visual.add_child(light)
	
	var tween = create_tween()
	tween.set_parallel(true)
	# Expand the circle and the light
	tween.tween_property(circle, "scale", Vector2(explosion_radius/10.0, explosion_radius/10.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(light, "texture_scale", explosion_radius/64.0, 0.3)
	
	# Fade out
	tween.tween_property(circle, "modulate:a", 0.0, 0.4)
	tween.tween_property(light, "energy", 0.0, 0.4)
	
	tween.chain().tween_callback(visual.queue_free)

func _create_radial_texture(size: int) -> GradientTexture2D:
	var grad = Gradient.new()
	grad.offsets = [0.0, 0.8]
	grad.colors = [Color.WHITE, Color(1, 1, 1, 0)]
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5) 
	tex.width = size
	tex.height = size
	return tex
