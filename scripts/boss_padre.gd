## Boss especializado: Padre.
## Possui múltiplos ataques e maior resistência.
extends Enemy

signal boss_died

var _is_invincible: bool = false
var _sun_active: bool = false
var _sun_cooldown: float = 0.0
var _teleport_cooldown: float = 0.0

func _ready():
	add_to_group("boss")
	
	# Atributos base elevados para o chefe - Equilíbrio de velocidade
	health = 450.0
	attack_damage = 30.0
	move_speed = 80.0 # Reduzido de 100.0
	chase_speed = 208.0 # Apenas 4% mais rápido que os 200 de Wlademir
	
	super._ready()
	
	# Ajusta área de detecção para ser bem grande
	var col = detection_area.get_node("CollisionShape2D")
	if col and col.shape is CircleShape2D:
		col.shape = col.shape.duplicate()
		col.shape.radius = 400.0
	
	# Padre tem um cooldown de ataque reduzido para pressionar o jogador
	attack_timer.wait_time = 1.8 # Reduzido de 3.5

func _process(delta: float):
	if _sun_cooldown > 0:
		_sun_cooldown -= delta
	if _teleport_cooldown > 0:
		_teleport_cooldown -= delta

func _apply_level_scaling():
	var gen = get_tree().root.find_child("LevelGenerator", true, false)
	if gen and "current_level" in gen:
		var mult = pow(1.35, gen.current_level - 1)
		health *= mult
		attack_damage *= mult

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Padre destrói caixas ao colidir com elas
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		if body and body.has_method("destroy") and body.is_in_group("destructible"):
			body.destroy()

func _process_ai_state(delta: float):
	if current_state == State.ATTACK:
		# Durante ataques especiais, o Padre geralmente fica parado
		velocity = velocity.move_toward(Vector2.ZERO, 20.0)
		return
		
	super._process_ai_state(delta)

func _handle_aggressive(delta: float, in_range: bool, has_los: bool):
	var dist = global_position.distance_to(player.global_position)
	
	# Se estiver muito longe e o teleporte estiver pronto, usa para fechar a distância
	if dist > 350.0 and _teleport_cooldown <= 0 and not _is_charging:
		_perform_teleport_attack()
		return
		
	super._handle_aggressive(delta, in_range, has_los)

func _animate():
	# Bloqueio apenas se estiver REALMENTE no meio de um ataque animado
	if _is_charging:
		return
		
	# Padre não vira o sprite (flip_h), apenas anima
	if velocity.length() > 5:
		if anim_player.current_animation != "walk":
			anim_player.play("walk")
	else:
		if anim_player.current_animation != "idle":
			anim_player.play("idle")

func _perform_attack():
	# Bloqueia reentrada apenas se já estiver no processo de ataque
	if _is_charging: return
	
	var dist = global_position.distance_to(player.global_position)
	var r = randf()
	
	# Lógica de decisão de ataque
	if _teleport_cooldown <= 0 and r < 0.2:
		# Teleporte tem 20% de chance se disponível
		_perform_teleport_attack()
	elif _sun_cooldown <= 0 and r < 0.3:
		# Sacred Sun tem 30% de chance se disponível
		_perform_attack_2()
	elif dist < 65.0:
		# Se muito perto, decide entre Smash e Wide Swing
		if r < 0.4: # 40% chance de Smash
			_perform_attack_3()
		else: # 60% chance de Wide Swing mesmo perto
			_perform_attack_1()
	else:
		# Médio alcance: Wide Swing (Attack 1)
		_perform_attack_1()

## ATAQUE 1: Wide Swing (Médio Alcance) - Agora mais rápido
func _perform_attack_1():
	_is_charging = true
	current_state = State.ATTACK
	velocity = Vector2.ZERO 
	
	# Telegraph: Brilho antes de começar a animação propriamente dita (mais rápido: 0.1s)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(2, 2, 1), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
	
	await get_tree().create_timer(0.1).timeout
	
	if is_instance_valid(self):
		anim_player.play("attack_1", -1, 1.6) # Velocidade 1.6x
		
		# Espera o delay para sincronizar com o swing visual (0.3s)
		await get_tree().create_timer(0.3).timeout
		
		if not is_instance_valid(self): return
		
		# Efeito de Luz (Flash rápido)
		_spawn_attack_1_flash()
		# Efeito de Partículas (Arco)
		_spawn_attack_1_arc_particles()
		
		# Aumenta a hitbox para simular o alcance médio e o "wide swing"
		hitbox.scale = Vector2(2.5, 2.5) 
		hitbox.monitoring = true
		
		# Espera o tempo do swing na animação (ajustado para a nova velocidade)
		await get_tree().create_timer(0.3).timeout
		
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

func _perform_teleport_attack():
	_is_charging = true
	_teleport_cooldown = 10.0 # Cooldown de 10 segundos
	current_state = State.ATTACK
	
	# Efeito de desaparecer
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_spawn_attack_1_flash() # Reutiliza o flash como efeito de fumaça/luz
	
	await tween.finished
	
	if is_instance_valid(player):
		# Posiciona exatamente na posição do jogador
		var target_pos = player.global_position
		
		# --- SEGURANÇA: Evita teleportar para dentro de paredes se o player estiver colado em uma ---
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, target_pos)
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		
		if result:
			# Se houver uma parede no caminho direto, tenta se aproximar o máximo possível
			target_pos = result.position
		
		global_position = target_pos
		
		# Efeito de aparecer
		var tween_in = create_tween()
		tween_in.tween_property(self, "modulate:a", 1.0, 0.1)
		_spawn_attack_1_flash()
		
		await tween_in.finished
		
		# Ataca imediatamente
		_is_charging = false # Reset temporário para permitir o próximo ataque
		_perform_attack_1()
	else:
		_is_charging = false
		modulate.a = 1.0
		attack_timer.start()
		current_state = State.AGGRESSIVE

func _spawn_sacred_sun():
	var center_offset = Vector2(18, 2) # Alinha com o centro da colisão do boss
	
	# Cria um efeito de luz que causa dano contínuo
	var sun_light = PointLight2D.new()
	sun_light.color = Color(1, 0.9, 0.5)
	sun_light.energy = 2.0
	sun_light.texture = _create_radial_texture(256)
	sun_light.texture_scale = 0.75 # Reduzido pela metade (era 1.5)
	sun_light.position = center_offset
	add_child(sun_light)
	
	# Partículas de brilho sagrado
	var particles = CPUParticles2D.new()
	particles.amount = 40
	particles.lifetime = 1.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 60.0
	particles.gravity = Vector2(0, -40) # Flutuam para cima
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 3.0
	particles.color = Color(1.0, 1.0, 0.6, 0.8) # Amarelo brilhante translúcido
	particles.position = center_offset
	add_child(particles)
	
	# Área de dano
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 60.0 # Reduzido pela metade (era 120.0)
	col.shape = shape
	area.add_child(col)
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = center_offset
	add_child(area)
	
	# Duração de 4 segundos - Roda em segundo plano
	_run_sun_timer(sun_light, area, particles)

func _run_sun_timer(light, area, particles):
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
	if is_instance_valid(particles):
		particles.emitting = false
		get_tree().create_timer(2.0).timeout.connect(particles.queue_free)

## ATAQUE 3: Holy Smash (Lento, mas devastador)
func _perform_attack_3():
	_is_charging = true
	current_state = State.ATTACK
	anim_player.play("attack_3")
	
	# Telegraph lento -> Agora mais rápido
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(3, 1, 1), 0.4)
	
	await get_tree().create_timer(0.4).timeout
	
	if is_instance_valid(self):
		sprite.modulate = Color(1, 1, 1)
		_visual_jump() 
		_spawn_smash_explosion()
		
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

func _chase_player():
	_last_strafe_dir = Vector2.ZERO
	
	# Padre tenta se posicionar acima (norte) do jogador para que seus ataques
	# visualmente conectem melhor de cima para baixo.
	var ideal_pos = player.global_position + Vector2(0, -50)
	
	var dist_to_ideal = global_position.distance_to(ideal_pos)
	var dir_to_ideal = (ideal_pos - global_position).normalized()
	
	if dist_to_ideal < 20.0:
		# Está na posição ideal (acima do jogador)
		velocity = velocity.move_toward(Vector2.ZERO, chase_speed * 0.1)
	else:
		# Move-se para a posição ideal
		velocity = velocity.move_toward(dir_to_ideal * chase_speed, chase_speed * 0.1)

func _get_attack_range() -> float:
	return 180.0

func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO, knockback_strength: float = 300.0, is_crit: bool = false):
	# O Padre tem resistência a knockback (apenas 10%)
	super.take_damage(amount, source_pos, knockback_strength * 0.1, is_crit)

func die():
	boss_died.emit()
	super.die()

func _spawn_smash_explosion():
	var particles = CPUParticles2D.new()
	particles.amount = 80
	particles.explosiveness = 1.0
	particles.lifetime = 0.8
	particles.one_shot = true
	
	# Espalha em todas as direções (esfera/círculo)
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 140.0
	
	# Visual
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color_initial_ramp = Gradient.new()
	particles.color_initial_ramp.colors = [Color(1, 0.8, 0.2), Color(1, 0.4, 0.1)] # Dourado para Laranja
	
	# Fade out
	var grad = Gradient.new()
	grad.colors = [Color(1, 1, 1, 1), Color(1, 1, 1, 0)]
	particles.color_ramp = grad
	
	particles.position = Vector2(18, 72) # 70 pixels abaixo do centro original (18, 2)
	add_child(particles)
	particles.emitting = true
	
	# Efeito de luz (Flash)
	var flash = PointLight2D.new()
	flash.texture = _create_radial_texture(256)
	flash.texture_scale = 1.5
	flash.color = Color(1, 0.9, 0.6)
	flash.energy = 4.0
	flash.position = Vector2(18, 72)
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "energy", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(flash.queue_free)
	
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func _spawn_attack_1_flash():
	var flash = PointLight2D.new()
	flash.texture = _create_radial_texture(128)
	flash.texture_scale = 2.0
	flash.color = Color(1, 1, 0.8)
	flash.energy = 2.0
	flash.position = Vector2(18, 2)
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "energy", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(flash.queue_free)

func _spawn_attack_1_arc_particles():
	var particles = CPUParticles2D.new()
	particles.amount = 100 # Aumentado de 30
	particles.lifetime = 0.4
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(1, 0.9, 0.5, 0.6)
	
	# Fade out
	var grad = Gradient.new()
	grad.colors = [Color(1, 1, 1, 1), Color(1, 1, 1, 0)]
	particles.color_ramp = grad
	
	add_child(particles)
	
	# Anima o emissor em um arco - De Esquerda para Direita, peakando para baixo
	var tween = create_tween()
	var start_angle = PI - 0.5 # Esquerda-Baixo
	var end_angle = 0.5 # Direita-Baixo
	var radius = 60.0
	var center = Vector2(-2, 10)
	
	tween.tween_method(func(t):
		var angle = lerp(start_angle, end_angle, t)
		particles.position = center + Vector2(cos(angle), sin(angle)) * radius
	, 0.0, 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.finished.connect(func():
		particles.emitting = false
		get_tree().create_timer(0.5).timeout.connect(particles.queue_free)
	)
