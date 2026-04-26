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
	super._ready()
	# Dobra o tempo de recarga do ataque (o padrão no Enemy é 1.2s, definido no tscn)
	attack_timer.wait_time = 2.4

func _perform_attack():
	# A múmia para para lançar o projétil
	velocity = Vector2.ZERO
	_is_charging = true
	
	# Telegraphing: Brilho antes de atirar
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(2, 2, 0), 0.4) # Amarelo brilhante
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

# Sobrescrita de métodos virtuais

func _get_attack_range() -> float:
	return 200.0 # Alcance considerável para um arqueiro/mago

func _get_min_chase_dist() -> float:
	return 120.0 # Tenta manter distância do jogador

func _on_attack_timer_timeout():
	if current_state == State.ATTACK:
		current_state = State.AGGRESSIVE
