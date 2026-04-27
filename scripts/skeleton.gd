## Inimigo especializado: Esqueleto.
## Inimigo padrão com atributos padrão.
extends Enemy

func _ready():
	is_living = false
	super._ready()

func _perform_attack():
	# O esqueleto prepara um ataque de investida
	velocity = Vector2.ZERO
	_is_charging = true
	
	# Telegraphing: Brilho vermelho antes de avançar
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(2, 0, 0), 0.2) # Vermelho brilhante
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
	
	await get_tree().create_timer(0.25).timeout
	
	if is_instance_valid(self):
		_is_charging = false
		# Chama o ataque da classe base que faz o lunge
		super._perform_attack()

func _chase_player():
	var dist = global_position.distance_to(player.global_position)
	var target_dir = (player.global_position - global_position).normalized()
	
	# Se estiver perto, tenta circular o jogador um pouco (ziguezague)
	if dist < 80:
		var side_dir = target_dir.rotated(PI/2)
		var sin_offset = side_dir * sin(Time.get_ticks_msec() * 0.005) * 40.0
		var dir = (target_dir * chase_speed + sin_offset).normalized()
		velocity = velocity.move_toward(dir * chase_speed, chase_speed * 0.2)
	else:
		super._chase_player()
