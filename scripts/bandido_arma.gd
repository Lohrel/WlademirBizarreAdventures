## Inimigo especializado: Bandido com Arma.
## Dispara uma rajada de 12 projéteis, depois recarrega por 4 segundos.
extends Enemy

@export_group("Bandido Config")
@export var projectile_scene: PackedScene = preload("res://scenes/bandido_projectile.tscn")
@export var shots_per_burst: int = 12
@export var time_between_shots: float = 0.3
@export var reload_time: float = 4.0

func _ready():
	# Atributos específicos do bandido
	health = 80.0
	move_speed = 80.0
	chase_speed = 120.0
	super._ready()
	
	# Configura o tempo de recarga entre rajadas
	attack_timer.wait_time = reload_time

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
