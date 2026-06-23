## Inimigo especializado: Mumia.
## Ataca à distância lançando bolas de fogo que explodem.
extends Enemy

@export_group("Mumia Config")
@export var projectile_scene: PackedScene = preload("res://scenes/mumia_projectile.tscn")

func _ready():
	# Atributos específicos da múmia
	health = 60.0
	move_speed = 60.0 # Mais lenta que o esqueleto
	chase_speed = 100.0
	is_living = false
	super._ready()
	
	# Dobra o tempo de recarga do ataque (o padrão no Enemy é 1.2s, definido no tscn)
	attack_timer.wait_time = 2.4

var _damage_audio_stream = preload("res://assets/sounds/MummyTakingDamage.wav")

func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO, knockback_strength: float = 300.0, is_crit: bool = false):
	if amount > 0:
		var audio = AudioStreamPlayer2D.new()
		audio.stream = _damage_audio_stream
		get_parent().add_child(audio)
		audio.global_position = global_position
		audio.play()
		audio.finished.connect(audio.queue_free)
	super.take_damage(amount, source_pos, knockback_strength, is_crit)
	
	# Aumenta o alcance de detecção (deferido para evitar erro da física do Godot)
	call_deferred("_increase_detection_range")

func _increase_detection_range():
	var detection_shape = detection_area.get_node_or_null("CollisionShape2D")
	if detection_shape and detection_shape.shape:
		detection_shape.shape = detection_shape.shape.duplicate()
		if detection_shape.shape is CircleShape2D:
			detection_shape.shape.radius = 350.0
		elif detection_shape.shape is RectangleShape2D:
			detection_shape.shape.size = Vector2(700, 700) # Dobro do raio pretendido

func _perform_attack():
	if attack_audio:
		attack_audio.stop()
		attack_audio.play()
	# A múmia para para lançar o projétil
	velocity = Vector2.ZERO
	_is_charging = true
	
	# Telegraphing: Brilho antes de atirar
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 0.5), 0.4) # Amarelo visível mas menos agressivo
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	
	_visual_jump()
	
	# Espera o delay de telegraphing
	await get_tree().create_timer(0.5).timeout
	
	if is_instance_valid(self):
		_is_charging = false
		var in_range = detection_area.overlaps_body(player)
		if player and _check_line_of_sight(in_range):
			var dir = (player.global_position - global_position).normalized()
			var proj = projectile_scene.instantiate()
			get_parent().add_child(proj)
			proj.global_position = global_position
			proj.direction = dir
			proj.damage = attack_damage
			proj.source = self
	
	attack_timer.start()
	current_state = State.AGGRESSIVE

# Sobrescrita de métodos virtuais

func _get_attack_range() -> float:
	return 300.0 # Aumentado para maior perigo à distância

func _get_min_chase_dist() -> float:
	return 180.0 # Tenta manter uma distância maior do jogador

func _on_attack_timer_timeout():
	if current_state == State.ATTACK:
		current_state = State.AGGRESSIVE
