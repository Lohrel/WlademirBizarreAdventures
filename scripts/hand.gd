## Controla a mão/garra do jogador.
## Responsável pelo posicionamento em relação ao mouse e detecção de ataques.
extends Sprite2D

# --- Atributos ---
@export var distancia: int = 25
@export var attack_damage: float = 10.0

# --- Referências ---
@onready var hitbox = $Hitbox

var _already_hit_areas: Array[Area2D] = []

# --- Ciclo de Vida ---

func _ready() -> void:
	# Conecta o sinal de colisão para causar dano
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
		hitbox.monitoring = false
		hitbox.monitorable = false

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
			scale.y = -abs(scale.y)
		else:
			scale.y = abs(scale.y)

# --- Lógica de Ataque ---

func start_attack() -> void:
	distancia = 0
	_already_hit_areas.clear()
	if hitbox:
		hitbox.monitoring = true
		hitbox.monitorable = true
		# Verifica imediatamente quem já está dentro da hitbox
		# Isso resolve o problema de inimigos colados no player
		_check_initial_overlaps()

func stop_attack() -> void:
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false
	_already_hit_areas.clear()

func _check_initial_overlaps() -> void:
	if not hitbox or not hitbox.is_inside_tree(): return
	
	var overlapping_areas = hitbox.get_overlapping_areas()
	for area in overlapping_areas:
		_on_hitbox_area_entered(area)

# --- Sinais ---

func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area in _already_hit_areas:
		# Se atingir a área de dano de um inimigo
		if area.name == "Hurtbox" and area.owner.has_method("take_damage"):
			_already_hit_areas.append(area)
			
			var damage_to_deal = attack_damage
			var is_crit = false
			
			var player = get_parent().get_parent()
			if player and "crit_chance" in player:
				if randf() < player.crit_chance:
					is_crit = true
					damage_to_deal *= player.crit_multiplier
			
			# Aplica dano e knockback usando a posição da garra
			var knockback = player.knockback_strength if player and "knockback_strength" in player else 300.0
			area.owner.take_damage(damage_to_deal, global_position, knockback, is_crit)
			
			# Lógica de Roubo de Vida (apenas em inimigos vivos)
			if player and "life_steal" in player and player.life_steal > 0:
				var enemy = area.owner
				if enemy.get("is_living") == true:
					var heal_amount = damage_to_deal * player.life_steal
					player.health = min(player.health + heal_amount, player.max_health)
					player.update_hud()
			
			# Feedback visual na garra
			var tween = create_tween()
			var base_scale = scale
			var scale_mult = 2.0 if is_crit else 1.5
			tween.tween_property(self, "scale", base_scale * scale_mult, 0.05)
			tween.tween_property(self, "scale", base_scale, 0.1)
			
			# Shake da câmera
			var cam = get_viewport().get_camera_2d()
			if cam and cam.has_method("shake"):
				var shake_intensity = 6.0 if is_crit else 3.0
				cam.shake(shake_intensity)
				
			# Hit Stop (Freeze frame)
			var stop_time = 0.1 if is_crit else 0.05
			Engine.time_scale = 0.05
			await get_tree().create_timer(stop_time, true, false, true).timeout
			Engine.time_scale = 1.0
