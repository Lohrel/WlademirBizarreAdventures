## Inimigo especializado: Bandido com Faca.
## Rápido, persegue agressivamente e causa sangramento.
extends Enemy

@export var bleed_damage: float = 15.0
@export var bleed_duration: float = 3.0

func _ready():
	# Atributos específicos: Mais rápido e menos vida
	health = 60.0
	move_speed = 150.0
	chase_speed = 220.0
	super._ready()

func _perform_attack():
	# O bandido avança rápido para esfaquear
	velocity = Vector2.ZERO
	_is_charging = true
	
	# Telegraphing: Brilho vermelho
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(2, 0, 0), 0.15)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
	
	await get_tree().create_timer(0.2).timeout
	
	if is_instance_valid(self):
		_is_charging = false
		# Lunge (avanco)
		var target_dir = (player.global_position - global_position).normalized()
		var lunge_tween = create_tween()
		lunge_tween.tween_property(self, "velocity", target_dir * 500.0, 0.1)
		lunge_tween.tween_property(self, "velocity", Vector2.ZERO, 0.1)
		
		# Verifica acerto manualmente se estiver perto (ou usa hitbox)
		if global_position.distance_to(player.global_position) < 40.0:
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
			if player.has_method("apply_poison"):
				player.apply_poison(bleed_damage, bleed_duration)
				
		attack_timer.start()
		current_state = State.AGGRESSIVE

func _get_attack_range() -> float:
	return 35.0

func _get_min_chase_dist() -> float:
	return 20.0 # Tenta ficar colado no jogador
