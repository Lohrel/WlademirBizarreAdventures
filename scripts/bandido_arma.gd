## Inimigo especializado: Bandido com Arma.
## Dispara uma rajada de 12 projéteis, depois recarrega por 4 segundos.
extends Enemy

@export_group("Bandido Config")
@export var projectile_scene: PackedScene = preload("res://scenes/bandido_projectile.tscn")
@export var shots_per_burst: int = 12
@export var time_between_shots: float = 0.3
@export var reload_time: float = 4.0

var _muzzle_light: PointLight2D = null

func _ready():
	# Atributos específicos do bandido
	health = 80.0
	move_speed = 80.0
	chase_speed = 120.0
	super._ready()
	
	# Configura o tempo de recarga entre rajadas
	attack_timer.wait_time = reload_time
	
	# Cria a luz de tiro (muzzle flash)
	_setup_muzzle_light()

func _setup_muzzle_light():
	_muzzle_light = PointLight2D.new()
	_muzzle_light.color = Color(1.0, 0.8, 0.4) # Cor de pólvora/faísca
	_muzzle_light.energy = 0.0 # Começa desligada
	_muzzle_light.texture_scale = 0.8
	_muzzle_light.texture = _create_light_texture(128)
	add_child(_muzzle_light)

func _create_light_texture(size: int) -> GradientTexture2D:
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

func _perform_attack():
	# O bandido para para disparar a rajada
	velocity = Vector2.ZERO
	_is_charging = true
	
	# Telegraphing: Flash rápido antes de começar a rajada
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0, 0), 0.1) # Vermelho
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	
	await get_tree().create_timer(0.5).timeout
	
	if not is_instance_valid(self): return

	# Loop da rajada
	for i in range(shots_per_burst):
		if not is_instance_valid(self) or not player: break
		
		# Verifica se ainda tem linha de visão antes de cada tiro da rajada
		var in_range = detection_area.overlaps_body(player)
		if not _check_line_of_sight(in_range): break
		
		_fire_bullet()
		
		# Pequeno coice visual
		var kick = create_tween()
		sprite.position.x = -2 if sprite.flip_h else 2
		kick.tween_property(sprite, "position:x", 0, 0.1)
		
		await get_tree().create_timer(time_between_shots).timeout
	
	if is_instance_valid(self):
		_is_charging = false
		attack_timer.start()

func _fire_bullet():
	if not player: return
	
	# Muzzle flash visual
	var flash = create_tween()
	_muzzle_light.energy = 1.5
	flash.tween_property(_muzzle_light, "energy", 0.0, 0.1)
	
	var dir = (player.global_position - global_position).normalized()
	# Adiciona uma pequena imprecisão aleatória
	dir = dir.rotated(randf_range(-0.05, 0.05))
	
	var proj = projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position
	proj.direction = dir
	proj.damage = attack_damage
	proj.source = self

# Sobrescrita de métodos virtuais

func _get_attack_range() -> float:
	return 250.0

func _get_min_chase_dist() -> float:
	return 150.0 # Mantém uma distância maior que a múmia

func _on_attack_timer_timeout():
	if current_state == State.ATTACK:
		current_state = State.AGGRESSIVE
