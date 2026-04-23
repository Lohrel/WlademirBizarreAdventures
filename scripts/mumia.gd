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
	
	# Animação de ataque (se houver, senão usamos idle por um momento)
	# Como não temos uma animação de "cast" específica no spritesheet de 6 frames,
	# vamos usar o feedback visual de pulo ou apenas uma pausa.
	_visual_jump()
	
	# Espera um pequeno delay para "lançar"
	await get_tree().create_timer(0.3).timeout
	
	if player:
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
