## Inimigo especializado: Chefe.
## Maior, mais forte e mais resistente do que inimigos padrão.
extends Enemy

signal boss_died # Especificamente para a lógica de geração de nível

func _ready():
	# Lógica do Chefe: garante que ele esteja no grupo correto e os sinais estejam configurados
	add_to_group("boss")
	
	# Atributos base elevados para o chefe
	health = 200.0
	attack_damage = 30.0
	move_speed = 80.0 # Chefe agora é mais rápido
	chase_speed = 210.0 # Ligeiramente mais rápido que o jogador (200.0)
	
	super._ready()
	
	# Reduz o tamanho da área de detecção (original é 48, escalonado por 10 no tscn)
	var col = detection_area.get_node("CollisionShape2D")
	if col and col.shape is CircleShape2D:
		col.shape = col.shape.duplicate()
		col.shape.radius = 24.0

func _handle_wandering(_delta: float):
	# O chefe não vaga aleatoriamente. Ele fica parado esperando o jogador.
	current_state = State.IDLE
	velocity = Vector2.ZERO

func _apply_level_scaling():
	# Chefes escalonam de forma mais agressiva: 25% por nível
	var gen = get_tree().root.find_child("LevelGenerator", true, false)
	if gen and "current_level" in gen:
		var mult = pow(1.25, gen.current_level - 1)
		health *= mult
		attack_damage *= mult

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_check_box_collision()

func _check_box_collision():
	# Se já estiver atacando ou em cooldown, ignora
	if current_state == State.ATTACK or not attack_timer.is_stopped():
		return
		
	# Verifica se colidiu com uma caixa durante o movimento
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var body = col.get_collider()
		if body.has_method("throw") and not body.is_thrown:
			# Gatilha o ataque de arremesso imediatamente ao colidir
			current_state = State.ATTACK
			call_deferred("_perform_throw_attack", body)
			break

func _perform_attack():
	# Decide entre ataque normal e arremesso de caixa
	var nearby_box = _find_nearby_box()
	
	if nearby_box:
		# 100% de chance de arremessar se houver caixa por perto
		_perform_throw_attack(nearby_box)
	else:
		_perform_standard_attack()

func _perform_standard_attack():
	# Ataque de investida padrão (copiado do Enemy base mas com valores do Boss)
	var lunge_dist = _get_lunge_dist()
	var tween = create_tween()
	var target_pos = global_position + (player.global_position - global_position).normalized() * lunge_dist
	tween.tween_property(self, "global_position", target_pos, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	hitbox.monitoring = true
	await get_tree().create_timer(0.2).timeout
	hitbox.monitoring = false
	
	attack_timer.start()

func _perform_throw_attack(box: RigidBody2D):
	if not is_instance_valid(box): 
		current_state = State.AGGRESSIVE
		return
		
	# 1. "Puxa" a caixa para perto do chefe
	var pull_tween = create_tween()
	var hold_pos = global_position + (player.global_position - global_position).normalized() * 40
	pull_tween.tween_property(box, "global_position", hold_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Efeito visual de carga
	_visual_jump()
	await get_tree().create_timer(0.5).timeout
	
	# 2. Arremessa em direção ao jogador
	if is_instance_valid(box) and player:
		var dir = (player.global_position - box.global_position).normalized()
		box.throw(dir, 3500.0, attack_damage * 1.5)
	
	attack_timer.start()
	current_state = State.AGGRESSIVE

func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO, knockback_strength: float = 300.0, is_crit: bool = false):
	# Reduz o knockback recebido pelo chefe (apenas 20% do normal)
	super.take_damage(amount, source_pos, knockback_strength * 0.2, is_crit)

func _find_nearby_box() -> RigidBody2D:
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 150.0 # Raio de busca por caixas
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 1 # Camada de objetos/paredes
	
	var space_state = get_world_2d().direct_space_state
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body.has_method("throw") and not body.is_thrown:
			return body
	return null

func _get_attack_range() -> float: 
	return 60.0 # Maior alcance de ataque

func _get_min_chase_dist() -> float: 
	return 50.0 # Permanece mais longe devido ao tamanho

func _get_jump_height() -> float: 
	return 40.0 # Salto mais alto para impacto visual

func _get_lunge_dist() -> float: 
	return 40.0 # Investida mais longa durante o ataque

func _get_bone_particle_scale() -> Vector2: 
	return Vector2(2, 2) # Fragmentos de osso maiores

func _get_ray_length() -> float: 
	return 60.0 # Raios de desvio mais longos
