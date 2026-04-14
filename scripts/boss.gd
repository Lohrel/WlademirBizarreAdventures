## Inimigo especializado: Chefe.
## Maior, mais forte e mais resistente do que inimigos padrão.
extends Enemy

signal boss_died # Especificamente para a lógica de geração de nível

func _ready():
	# Lógica do Chefe: garante que ele esteja no grupo correto e os sinais estejam configurados
	add_to_group("boss")
	super._ready()

func die():
	boss_died.emit()
	super.die()

# --- Sobrescrita de Atributos para o Chefe ---

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
