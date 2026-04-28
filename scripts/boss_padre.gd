## Boss especializado: Padre.
## Possui múltiplos ataques e maior resistência.
extends Enemy

signal boss_died

var _is_invincible: bool = false
var _sunlight_active: bool = false
var _sun_cooldown: float = 0.0

func _ready():
	add_to_group("boss")
	
	# Atributos base elevados para o chefe - Ajustados para serem mais lentos
	health = 450.0
	attack_damage = 30.0
	move_speed = 45.0 # Reduzido em 25% de 60.0
	chase_speed = 98.0 # Reduzido em 25% de 130.0 (Wlademir tem 200 base)
	
	super._ready()
	
	# Ajusta área de detecção para ser bem grande
	var col = detection_area.get_node("CollisionShape2D")
	if col and col.shape is CircleShape2D:
		col.shape = col.shape.duplicate()
		col.shape.radius = 400.0
	
	# Padre tem um cooldown de ataque maior para dar tempo de reação ao jogador
	attack_timer.wait_time = 3.5 # Aumentado de 2.0

func _process(delta: float):
	if _sun_cooldown > 0:
		_sun_cooldown -= delta

func _apply_level_scaling():
	var gen = get_tree().root.find_child("LevelGenerator", true, false)
	if gen and "current_level" in gen:
		var mult = pow(1.35, gen.current_level - 1)
		health *= mult
		attack_damage *= mult

func _process_ai_state(delta: float):
	if current_state == State.ATTACK:
		# Durante ataques especiais, o Padre geralmente fica parado
		velocity = velocity.move_toward(Vector2.ZERO, 20.0)
		return
		
	super._process_ai_state(delta)

func _animate():
	# Bloqueio apenas se estiver REALMENTE no meio de um ataque animado
	if _is_charging:
		return
		
	# Usa a lógica base para flip do sprite e detecção de movimento
	super._animate()

func _perform_attack():
	# Bloqueia reentrada apenas se já estiver no processo de ataque
	if _is_charging: return
	
	var dist = global_position.distance_to(player.global_position)
	
	# Lógica de decisão de ataque
	if dist < 80.0:
		# Muito perto: Smash (Attack 3) ou Sacred Sun (Attack 2)
		if _sun_cooldown <= 0 and randf() < 0.5:
			_perform_attack_2()
		else:
			_perform_attack_3()
	else:
		# Médio alcance: Wide Swing (Attack 1)
		_perform_attack_1()

## ATAQUE 1: Wide Swing (Médio Alcance) - Agora dura pelo menos 1 segundo
func _perform_attack_1():
	_is_charging = true
	current_state = State.ATTACK
	velocity = Vector2.ZERO 
	
	# Telegraph: Brilho antes de começar a animação propriamente dita
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(2, 2, 1), 0.3)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	
	await get_tree().create_timer(0.4).timeout
	
	if is_instance_valid(self):
		anim_player.play("attack_1")
		
		# Aumenta a hitbox para simular o alcance médio e o "wide swing"
		hitbox.scale = Vector2(1.8, 1.8) 
		hitbox.monitoring = true
		
		# Espera o tempo do swing na animação (frames 1-3)
		await get_tree().create_timer(0.5).timeout
		
		hitbox.monitoring = false
		hitbox.scale = Vector2(1.0, 1.0)
		
		# Espera o resto da animação se necessário
		if anim_player.is_playing() and anim_player.current_animation == "attack_1":
			await anim_player.animation_finished
	
	_is_charging = false
	attack_timer.start()
	current_state = State.AGGRESSIVE

## ATAQUE 2: Sacred Sun (Luz que queima) - 15s Cooldown
func _perform_attack_2():
	_is_charging = true
	_sun_cooldown = 15.0 # Inicia o cooldown de 15 segundos
	current_state = State.ATTACK
	anim_player.play("attack_2")
	
	# Telegraph: Brilho azul/branco intenso
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 5), 0.5)
	
	await get_tree().create_timer(0.5).timeout
	
	if is_instance_valid(self):
		sprite.modulate = Color(1, 1, 1)
		_spawn_sacred_sun()
	
	# Espera animação terminar
	if anim_player.is_playing() and anim_player.current_animation == "attack_2":
		await anim_player.animation_finished
	
	_is_charging = false
	attack_timer.start()
	current_state = State.AGGRESSIVE

func _spawn_sacred_sun():
	# Cria um efeito de luz que causa dano contínuo
	var sun_light = PointLight2D.new()
	sun_light.color = Color(1, 0.9, 0.5)
	sun_light.energy = 2.0
	sun_light.texture = _create_radial_texture(256)
	sun_light.texture_scale = 0.75 # Reduzido pela metade (era 1.5)
	add_child(sun_light)
	
	# Área de dano
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 60.0 # Reduzido pela metade (era 120.0)
	col.shape = shape
	area.add_child(col)
	area.collision_layer = 0
	area.collision_mask = 2
	add_child(area)
	
	# Duração de 4 segundos - Roda em segundo plano
	_run_sun_timer(sun_light, area)

func _run_sun_timer(light, area):
	var timer = 4.0
	var elapsed = 0.0
	while elapsed < timer:
		if not is_instance_valid(self) or not is_instance_valid(area): break
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		
		if player and area.overlaps_body(player):
			player.take_damage(25.0 * get_process_delta_time())
	
	if is_instance_valid(light): light.queue_free()
	if is_instance_valid(area): area.queue_free()

## ATAQUE 3: Holy Smash (Lento, mas devastador)
func _perform_attack_3():
	_is_charging = true
	current_state = State.ATTACK
	anim_player.play("attack_3")
	
	# Telegraph lento
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(3, 1, 1), 0.6)
	
	await get_tree().create_timer(0.6).timeout
	
	if is_instance_valid(self):
		sprite.modulate = Color(1, 1, 1)
		_visual_jump() 
		
		var original_damage = attack_damage
		attack_damage *= 2.5
		hitbox.scale = Vector2(2.0, 2.0)
		hitbox.monitoring = true
		
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("shake"): cam.shake(10.0)
		
		_break_nearby_boxes()
		
		await get_tree().create_timer(0.4).timeout
		
		hitbox.monitoring = false
		hitbox.scale = Vector2(1.0, 1.0)
		attack_damage = original_damage
	
	if anim_player.is_playing() and anim_player.current_animation == "attack_3":
		await anim_player.animation_finished
	
	_is_charging = false
	attack_timer.start()
	current_state = State.AGGRESSIVE

func _break_nearby_boxes():
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 180.0 # Raio de quebra
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 1 # Camada de objetos/paredes
	
	var space_state = get_world_2d().direct_space_state
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body.has_method("destroy"):
			body.destroy()

func _create_radial_texture(size: int) -> GradientTexture2D:
	var grad = Gradient.new()
	grad.offsets = [0.0, 1.0]
	grad.colors = [Color(1, 1, 1, 1), Color(1, 1, 1, 0)]
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = size
	tex.height = size
	return tex

func _get_attack_range() -> float:
	return 180.0

func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO, knockback_strength: float = 300.0, is_crit: bool = false):
	# O Padre tem resistência a knockback (apenas 10%)
	super.take_damage(amount, source_pos, knockback_strength * 0.1, is_crit)

func die():
	boss_died.emit()
	super.die()
