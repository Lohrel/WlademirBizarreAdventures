## O script de controle do Jogador.
## Gerencia movimento, combate, detecção de luz solar e atributos.
class_name PlayerController
extends CharacterBody2D

# --- Referências de Nós ---
@export_group("Internal Nodes")
@export var _animation_tree: AnimationTree			
@export var _dash_timer: Timer = null
@export var _cooldown_dash: Timer = null
@export var _attack_timer: Timer = null

# --- Atributos Base ---
@export_group("Stats")
@export var max_health: float = 100.0
@export var health: float = 100.0
@export var max_mana: float = 100.0
@export var mana: float = 100.0
@export var mana_regen_rate: float = 5.0 # Mana por segundo

# --- Configuração de Habilidades ---
@export_group("Skills Config")
@export var _move_speed: float = 200.0
@export var _dash_speed: float = 450.0
@export var dash_mana_cost: float = 25.0
@export var dash_cooldown_time: float = 2.0

# --- Upgrades ---
@export_group("Upgrades")
@export var admin_mode: bool = true
@export var attack_range_multiplier: float = 1.0
@export var passive_regen_percent: float = 0.0 # ex: 0.02 para 2% por segundo
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 1.5
@export var quicksand_speed_bonus: float = 0.0
@export var dash_mastery: float = 1.0
@export var life_steal: float = 0.0
@export var knockback_strength: float = 0.0

# --- Variáveis de Estado ---
var speed_multiplier: float = 1.0
var _use_dash: bool = true
var _state_machine: AnimationNodeStateMachinePlayback
var _last_direction := Vector2.RIGHT
var _dash_direction := Vector2.ZERO

var _is_dashing: bool = false
var _is_attacking: bool = false
var _current_room: Node2D = null
var _in_sunlight: bool = false
var is_immortal: bool = false
var sunlight_damage_reduction: float = 0.0

# --- Referências de HUD ---
var _hud_node: Node = null

# --- Inventário e Equipamento ---
var equipment: Dictionary = {
	Equipment.Slot.BOOTS: null,
	Equipment.Slot.GLOVES: null,
	Equipment.Slot.TUNIC: null,
	Equipment.Slot.HAT: null,
	Equipment.Slot.RING: null
}

func equip_item(item: Equipment) -> bool:
	if equipment[item.slot] != null:
		return false
	equipment[item.slot] = item
	recalculate_stats()
	return true

func unequip_item(slot: int) -> void:
	var item = equipment[slot]
	if item:
		drop_item(item)
	equipment[slot] = null
	recalculate_stats()

func drop_item(item: Equipment) -> void:
	var drop = item_drop_scene.instantiate()
	drop.equipment_data = item
	get_parent().add_child(drop)
	drop.global_position = global_position
	
	# Pulo simples para o lado
	var jump_target = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	var sprite = drop.get_node("Sprite2D")
	
	var tween = drop.create_tween()
	tween.tween_property(sprite, "position:y", -20, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var move_tween = drop.create_tween()
	var start_pos = global_position
	move_tween.tween_method(func(t): 
		if is_instance_valid(drop):
			var target = start_pos.lerp(jump_target, t)
			var diff = target - drop.global_position
			drop.move_and_collide(diff)
	, 0.0, 1.0, 0.3)

# --- Cenas Pré-carregadas ---
var blood_scene = preload("res://scenes/blood_particles.tscn")
var death_screen_scene = preload("res://scenes/death_screen.tscn")
var damage_indicator_scene = preload("res://scenes/damage_indicator.tscn")
var item_drop_scene = preload("res://scenes/item_drop.tscn")
const EquipmentGenerator = preload("res://scripts/equipment_generator.gd")

# --- Stats de Base (Cópia dos exports para cálculo) ---
var base_max_health: float
var base_max_mana: float
var base_move_speed: float
var base_dash_speed: float
var base_dash_mana: float
var base_dash_cooldown: float
var base_attack_damage: float
var base_crit_chance: float
var base_crit_multiplier: float
var base_quicksand_speed_bonus: float
var base_dash_mastery: float
var base_life_steal: float
var base_knockback_strength: float

func _ready() -> void:
	# Inicializa valores base
	base_max_health = max_health
	base_max_mana = max_mana
	base_move_speed = _move_speed
	base_dash_speed = _dash_speed
	base_dash_mana = dash_mana_cost
	base_dash_cooldown = dash_cooldown_time
	base_crit_chance = crit_chance
	base_crit_multiplier = crit_multiplier
	base_quicksand_speed_bonus = quicksand_speed_bonus
	base_dash_mastery = dash_mastery
	base_life_steal = life_steal
	base_knockback_strength = knockback_strength
	
	var hand = get_node_or_null("garra_player/hand")
	if hand:
		base_attack_damage = hand.attack_damage
	else:
		base_attack_damage = 10.0

	# Essencial para movimento flutuante top-down
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	_state_machine = _animation_tree["parameters/playback"]
	add_to_group("player")
	
	# Cache do HUD
	if get_parent():
		_hud_node = get_parent().get_node_or_null("HUD")
	
	# Registra ação de interação se não existir
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var event = InputEventKey.new()
		event.keycode = KEY_E
		InputMap.action_add_event("interact", event)
	
	$PlayerLight.texture = _create_light_texture(256)
	update_hud()

func recalculate_stats() -> void:
	max_health = base_max_health
	max_mana = base_max_mana
	_move_speed = base_move_speed
	_dash_speed = base_dash_speed
	dash_mana_cost = base_dash_mana
	dash_cooldown_time = base_dash_cooldown
	sunlight_damage_reduction = 0.0
	attack_range_multiplier = 1.0
	passive_regen_percent = 0.0
	crit_chance = base_crit_chance
	crit_multiplier = base_crit_multiplier
	quicksand_speed_bonus = base_quicksand_speed_bonus
	dash_mastery = base_dash_mastery
	life_steal = base_life_steal
	knockback_strength = base_knockback_strength
	
	var hand = get_node_or_null("garra_player/hand")
	if hand:
		hand.attack_damage = base_attack_damage
		
	for slot in equipment:
		var item = equipment[slot]
		if item and item is Equipment:
			for stat in item.stats:
				var bonus = item.stats[stat]
				match stat:
					"move_speed": _move_speed += base_move_speed * bonus
					"max_health": max_health += base_max_health * bonus
					"max_mana": max_mana += base_max_mana * bonus
					"attack_damage": 
						if hand: hand.attack_damage += base_attack_damage * bonus
					"dash_mana_cost_reduction": dash_mana_cost -= base_dash_mana * bonus
					"dash_cooldown_reduction": dash_cooldown_time -= base_dash_cooldown * bonus
					"sunlight_damage_reduction": sunlight_damage_reduction += bonus
					"attack_range": attack_range_multiplier += bonus
					"health_regen": passive_regen_percent += bonus
					"dash_speed": _dash_speed += base_dash_speed * bonus
					"crit_chance": crit_chance += bonus
					"crit_multiplier": crit_multiplier += bonus
					"life_steal": life_steal += bonus
					"knockback_increase": knockback_strength += 300.0 * bonus
					"quicksand_speed": quicksand_speed_bonus += bonus
					"dash_mastery": dash_mastery += bonus
	
	# Aplica dash_mastery para aumentar a eficiência do dash (velocidade maior e custo menor)
	_dash_speed *= dash_mastery
	dash_mana_cost /= dash_mastery
	
	health = min(health, max_health)
	mana = min(mana, max_mana)
	dash_mana_cost = max(5.0, dash_mana_cost)
	dash_cooldown_time = max(0.1, dash_cooldown_time)
	
	update_hud()

func update_hud() -> void:
	if not is_instance_valid(self): return
	
	if _hud_node == null and get_parent():
		_hud_node = get_parent().get_node_or_null("HUD")

	if _hud_node:
		var health_bar = _hud_node.get_node_or_null("Control/VBoxContainer/HealthBar")
		if health_bar:
			health_bar.max_value = max_health
			health_bar.value = health
		var mana_bar = _hud_node.get_node_or_null("Control/VBoxContainer/ManaBar")
		if mana_bar:
			mana_bar.max_value = max_mana
			mana_bar.value = mana
			
		_update_equipment_slot_ui("Boots", Equipment.Slot.BOOTS)
		_update_equipment_slot_ui("Gloves", Equipment.Slot.GLOVES)
		_update_equipment_slot_ui("Tunic", Equipment.Slot.TUNIC)
		_update_equipment_slot_ui("Hat", Equipment.Slot.HAT)
		_update_equipment_slot_ui("Ring", Equipment.Slot.RING)
		
		# Atualiza o contador de andar buscando o gerador
		var gen = get_tree().root.find_child("LevelGenerator", true, false)
		var floor_label = _hud_node.get_node_or_null("Control/FloorLabel")
		if floor_label and gen and "current_level" in gen:
			floor_label.text = "Floor: " + str(gen.current_level)

func _update_equipment_slot_ui(slot_name: String, slot_enum: int) -> void:
	if _hud_node:
		var path = "Control/VBoxContainer/EquipmentSlots/" + slot_name
		var slot_node = _hud_node.get_node_or_null(path)
		if slot_node and slot_node is ColorRect:
			var item = equipment[slot_enum]
			if item:
				slot_node.color = Color(0.8, 0.2, 1.0, 1.0) # Roxo quando equipado
			else:
				slot_node.color = Color(1, 1, 1, 0.2) # Cinza claro transparente quando vazio

func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_combat()
	_handle_environment(delta)
	
	move_and_slide()
	_push_objects()
	_animate()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# F5 - Recarregar cena
		if event.keycode == KEY_F5:
			get_tree().reload_current_scene()
			return
		
		# F1 - Imortalidade
		if event.keycode == KEY_F1:
			is_immortal = !is_immortal
			$Sprite2D.modulate = Color(2, 2, 0) if is_immortal else Color(1, 1, 1)
			return
			
		# Tecla G - Desequipar
		if event.keycode == KEY_G:
			for slot in equipment:
				if equipment[slot] != null:
					unequip_item(slot)
					break
			return

		# Admin Mode Hotkeys
		if admin_mode:
			var level = 1
			var gen_node = get_tree().root.find_child("LevelGenerator", true, false)
			if gen_node and "current_level" in gen_node:
				level = gen_node.current_level
				
			match event.keycode:
				KEY_F2: # Spawn aleatório
					_spawn_debug_item(EquipmentGenerator.generate_item(level))
				KEY_F3: # Spawn Luva Admin
					var stats = {
						"life_steal": 0.15,
						"crit_multiplier": 1.0,
						"knockback_increase": 0.8,
						"crit_chance": 0.2,
						"attack_range": 1.5
					}
					var item = Equipment.new("Admin Gauntlets", Equipment.Slot.GLOVES, stats, Equipment.Rarity.EPIC)
					_spawn_debug_item(item)
				KEY_F4: # Spawn Lendário
					for i in range(100):
						var item = EquipmentGenerator.generate_item(level + 5)
						if item.rarity == Equipment.Rarity.LEGENDARY:
							_spawn_debug_item(item)
							break
				KEY_F6: # Teleporte para o Boss
					var gen = get_tree().root.find_child("LevelGenerator", true, false)
					if gen:
						for grid_pos in gen.map_data:
							if gen.map_data[grid_pos]["type"] == "boss":
								var world_pos = gen._get_physical_position(grid_pos)
								# Teleporta a raiz do jogador (CharacterBody2D)
								global_position = world_pos
								# Reseta velocidade para não "deslizar" ao chegar
								velocity = Vector2.ZERO
								# Ajusta a câmera imediatamente
								var cam = get_viewport().get_camera_2d()
								if cam and cam.has_method("snap_to_player"):
									cam.snap_to_player()
								break

func _handle_movement() -> void:
	_dash() 
	if _is_dashing:
		velocity = _dash_direction * _dash_speed
	else:
		_move()

func _handle_combat() -> void:
	_attack()

func _handle_environment(delta: float) -> void:
	_check_sunlight()
	if _in_sunlight:
		var dmg = 15.0 * delta
		dmg = max(0, dmg - (dmg * sunlight_damage_reduction))
		take_damage(dmg)
	
	if health < max_health and passive_regen_percent > 0:
		health = min(health + (max_health * passive_regen_percent * delta), max_health)
		update_hud()
	if mana < max_mana:
		mana = min(mana + (mana_regen_rate * delta), max_mana)
		update_hud()

func _move() -> void:
	if _is_dashing: return
	var iv = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if iv != Vector2.ZERO:
		_last_direction = iv.normalized()
		_animation_tree["parameters/walk/blend_position"] = _last_direction
		_animation_tree["parameters/idle/blend_position"] = _last_direction
	velocity = iv * (_move_speed * speed_multiplier)

func _dash() -> void:
	if Input.is_action_just_pressed("dash") and not _is_dashing and _use_dash:
		if mana < dash_mana_cost: return
		var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir == Vector2.ZERO: dir = _last_direction
		_dash_direction = dir.normalized()
		_use_dash = false
		_is_dashing = true
		mana -= dash_mana_cost
		update_hud()
		_cooldown_dash.start(dash_cooldown_time)
		_dash_timer.start()
		$DashSmoke.emitting = true

func _attack() -> void:
	if Input.is_action_just_pressed("attack") and not _is_attacking:
		_attack_timer.start()
		_is_attacking = true
		$garra_player/hand.start_attack()
		# Escala a garra visualmente com o alcance usando a nova propriedade visual_scale
		$garra_player/hand.visual_scale = 1.0 * attack_range_multiplier
	
	if _is_attacking:
		# Aumenta a velocidade de projeção proporcionalmente ao alcance para não parecer "lento"
		var projection_speed = 350.0 * attack_range_multiplier
		$garra_player/hand.distancia = move_toward($garra_player/hand.distancia, 60.0 * attack_range_multiplier, projection_speed * get_physics_process_delta_time())
		$garra_player/hand/ShadowTrail.emitting = true
	else:
		$garra_player/hand.distancia = move_toward($garra_player/hand.distancia, 25, 200 * get_physics_process_delta_time())
		$garra_player/hand/ShadowTrail.emitting = false
		# Reseta a escala visual gradualmente
		if $garra_player/hand.visual_scale > 1.0:
			$garra_player/hand.visual_scale = move_toward($garra_player/hand.visual_scale, 1.0, 2.0 * get_physics_process_delta_time())

func _check_sunlight() -> void:
	if not _current_room or not _current_room.get_node("DetectionArea").overlaps_body(self):
		_current_room = null
		for room in get_tree().get_nodes_in_group("rooms"):
			if room.get_node("DetectionArea").overlaps_body(self):
				_current_room = room
				break
	if not _current_room or not _current_room.has_open_ceiling:
		_set_in_sunlight(false)
		return
	var sun = _current_room.get_node_or_null("Sunlight")
	if not sun or not sun.visible or sun.energy < 0.5:
		_set_in_sunlight(false)
		return
	$SunShapeCast.target_position = to_local(sun.global_position)
	$SunShapeCast.force_shapecast_update()
	_set_in_sunlight(not $SunShapeCast.is_colliding())

func take_damage(amount: float) -> void:
	if is_immortal or _is_dashing: return
	
	if amount > 0:
		var indicator = damage_indicator_scene.instantiate()
		get_parent().add_child(indicator)
		indicator.global_position = global_position + Vector2(0, -20)
		indicator.setup(str(int(amount)), Color(1, 0.2, 0.2)) # Vermelho para o jogador
	
	health = max(0, health - amount)
	update_hud()
	if amount > 0.5:
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("shake"): cam.shake(5.0)
		var tween = create_tween()
		tween.tween_property($Sprite2D, "modulate", Color(5, 0.5, 0.5), 0.1)
		tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1), 0.1)
		var blood = blood_scene.instantiate()
		get_parent().add_child(blood)
		blood.global_position = global_position
		blood.emitting = true
		get_tree().create_timer(blood.lifetime).timeout.connect(blood.queue_free)
	if health <= 0: _die()

## Aplica um efeito de veneno ou sangramento que causa dano ao longo do tempo.
func apply_poison(total_damage: float, duration: float) -> void:
	var ticks = 5
	var damage_per_tick = total_damage / ticks
	
	# Efeito visual de sangramento (avermelhado)
	var visual_tween = create_tween()
	visual_tween.tween_property($Sprite2D, "modulate", Color(2, 0.5, 0.5), 0.2)
	
	for i in range(ticks):
		await get_tree().create_timer(duration / ticks).timeout
		if is_instance_valid(self) and health > 0:
			take_damage(damage_per_tick)
	
	# Restaura cor original
	if is_instance_valid(self):
		var restore_tween = create_tween()
		restore_tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1), 0.2)

func _die() -> void:
	var ds = death_screen_scene.instantiate()
	get_tree().root.add_child(ds)

func _set_in_sunlight(is_in: bool) -> void:
	if _in_sunlight != is_in:
		_in_sunlight = is_in
		if _hud_node:
			var hb = _hud_node.get_node_or_null("Control/VBoxContainer/HealthBar")
			if hb: hb.modulate = Color(2, 1, 1) if _in_sunlight else Color(1, 1, 1)
		$BurnParticles.emitting = _in_sunlight

func _push_objects() -> void:
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var body = col.get_collider()
		if body is RigidBody2D: body.apply_central_impulse(col.get_normal() * -25.0)

func _animate() -> void:
	if _is_dashing:
		_state_machine.travel("dash")
		$Sprite2D.rotation = _dash_direction.angle() + PI/2
		$Sprite2D.flip_h = false
		$garra_player.visible = false
	else:
		if $Sprite2D.rotation != 0:
			$Sprite2D.rotation = 0
		if not $garra_player.visible:
			$garra_player.visible = true
		
		if velocity.length() > 5:
			_state_machine.travel("walk")
		else:
			_state_machine.travel("idle")

func _on_dash_timer_timeout() -> void:
	_is_dashing = false
	$DashSmoke.emitting = false
	$Sprite2D.rotation = 0
	$garra_player.visible = true

func _on_cooldown_dash_timeout() -> void: _use_dash = true

func _on_attack_timer_timeout() -> void:
	_is_attacking = false
	$garra_player/hand.stop_attack()

func _create_light_texture(size: int) -> GradientTexture2D:
	var grad = Gradient.new()
	grad.offsets = [0.0, 1.0]
	grad.colors = [Color(1,1,1,1), Color(1,1,1,0)]
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = size
	tex.height = size
	return tex

func _spawn_debug_item(item: Equipment) -> void:
	var drop = item_drop_scene.instantiate()
	drop.equipment_data = item
	get_parent().add_child(drop)
	drop.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
