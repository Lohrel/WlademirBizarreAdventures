## Controla a mão/garra do jogador.
## Responsável pelo posicionamento em relação ao mouse e detecção de ataques.
extends Sprite2D

# --- Atributos ---
@export var distancia: int = 25
@export var attack_damage: float = 10.0

# --- Referências ---
@onready var hitbox = $Hitbox

# --- Ciclo de Vida ---

func _ready() -> void:
	# Conecta o sinal de colisão para causar dano
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)

func _physics_process(_delta: float) -> void:
	var player = get_parent().get_parent()
	if not player: return
	
	# Faz a garra seguir a direção do mouse
	var target_pos = get_global_mouse_position()
	var dir = (target_pos - player.global_position).normalized()
	
	global_position = player.global_position + dir * distancia
	look_at(target_pos)
	
	# Corrige a orientação vertical (flip) para não ficar de cabeça para baixo
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if not player._is_attacking:
		if rotation_degrees > 90 and rotation_degrees < 270:
			scale.y = -1
		else:
			scale.y = 1

# --- Sinais ---

func _on_hitbox_area_entered(area: Area2D) -> void:
	# Se atingir a área de dano de um inimigo
	if area.name == "Hurtbox" and area.owner.has_method("take_damage"):
		# Aplica dano e knockback usando a posição da garra
		area.owner.take_damage(attack_damage, global_position)
