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

# --- Configuração de Habilidades ---
@export_group("Skills Config")
@export var _move_speed: float = 200.0
@export var _dash_speed: float = 600.0
@export var dash_mana_cost: float = 25.0
@export var dash_cooldown_time: float = 0.5

# --- Upgrades ---
@export_group("Upgrades")
@export var attack_range_multiplier: float = 1.0
@export var passive_regen_percent: float = 0.0 # ex: 0.02 para 2% por segundo

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

# --- Cenas Pré-carregadas ---
var blood_scene = preload("res://scenes/blood_particles.tscn")
var death_screen_scene = preload("res://scenes/death_screen.tscn")

# --- Ciclo de Vida ---

func _ready() -> void:
	# Essencial para movimento flutuante top-down
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	_state_machine = _animation_tree["parameters/playback"]
	add_to_group("player")
	
	update_hud()
	$PlayerLight.texture = _create_light_texture(256)

func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_combat()
	_handle_environment(delta)
	
	move_and_slide()
	_push_objects()
	_animate()

# --- Manipulação de Entrada ---

func _input(event: InputEvent) -> void:
	# F11: Alternar tela cheia
	var is_fs_pressed = false
	if InputMap.has_action("ui_fullscreen"):
		is_fs_pressed = event.is_action_pressed("ui_fullscreen")
	
	if is_fs_pressed or (event is InputEventKey and event.pressed and event.keycode == KEY_F11):
		var mode = DisplayServer.window_get_mode()
		if mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			
	# F5: Reinício Rápido
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		get_tree().reload_current_scene()

	# F1: God Mode
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		is_immortal = !is_immortal
		if is_immortal:
			$Sprite2D.modulate = Color(2, 2, 0) # Tint dourado
		else:
			$Sprite2D.modulate = Color(1, 1, 1)

# --- Métodos do Sistema ---

## Gerencia toda a lógica de movimento, incluindo o dash.
func _handle_movement() -> void:
	_dash() 
	
	if _is_dashing:
		velocity = _dash_direction * _dash_speed
	else:
		_move()

## Gerencia o combate (ataques).
func _handle_combat() -> void:
	_attack()

## Gerencia efeitos baseados no ambiente, como luz solar e regeneração passiva.
func _handle_environment(delta: float) -> void:
	_check_sunlight()
	
	# Aplica dano solar se exposto
	if _in_sunlight:
		take_damage(15.0 * delta)
	
	# Aplica regeneração passiva
	if health < max_health and passive_regen_percent > 0:
		health += max_health * passive_regen_percent * delta
		health = min(health, max_health)
		update_hud()

# --- Mecânicas Principais ---

## Movimento WASD padrão.
func _move() -> void:
	if _is_dashing: return
	
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Atualiza a direção interna para as animações
	if input_vector != Vector2.ZERO:
		_last_direction = input_vector.normalized()
		_animation_tree["parameters/walk/blend_position"] = _last_direction
		_animation_tree["parameters/idle/blend_position"] = _last_direction
	
	velocity = input_vector * (_move_speed * speed_multiplier)

## Mecânica de Dash: usa mana para se mover rapidamente em uma direção.
func _dash() -> void:
	if Input.is_action_just_pressed("dash") and not _is_dashing and _use_dash:
		if mana < dash_mana_cost: return
			
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction == Vector2.ZERO:
			direction = _last_direction
			
		_dash_direction = direction.normalized()
		_use_dash = false
		_is_dashing = true
		
		mana -= dash_mana_cost
		update_hud()
		
		_cooldown_dash.start(dash_cooldown_time)
		_dash_timer.start()
		$DashSmoke.emitting = true

## Mecânica de Ataque: ataque de investida simples com uma hitbox.
func _attack() -> void:
	if Input.is_action_just_pressed("attack") and not _is_attacking:
		_attack_timer.start()
		_is_attacking = true
		$garra_player/hand.start_attack()
		
	if _is_attacking:
		var current_dist = $garra_player/hand.distancia
		var target_dist = 60.0 * attack_range_multiplier
		$garra_player/hand.distancia = move_toward(current_dist, target_dist, 350 * get_physics_process_delta_time())
		$garra_player/hand/ShadowTrail.emitting = true
	else:
		$garra_player/hand.distancia = move_toward($garra_player/hand.distancia, 25, 200 * get_physics_process_delta_time())
		$garra_player/hand/ShadowTrail.emitting = false

## Detecção de luz solar usando o contexto da sala e raycasts.
func _check_sunlight() -> void:
	# Encontra a sala atual se estiver perdida
	if not _current_room or not _current_room.get_node("DetectionArea").overlaps_body(self):
		_current_room = null
		for room in get_tree().get_nodes_in_group("rooms"):
			if room.get_node("DetectionArea").overlaps_body(self):
				_current_room = room
				break
	
	# Verifica se a sala está aberta para a luz solar
	if not _current_room or not _current_room.has_open_ceiling:
		_set_in_sunlight(false)
		return

	# Verifica se o sol está visivelmente ativo (baseado no ciclo)
	var sun = _current_room.get_node_or_null("Sunlight")
	if not sun or not sun.visible or sun.energy < 0.5:
		_set_in_sunlight(false)
		return
		
	# Raycast para garantir que não estamos nas sombras
	$SunShapeCast.target_position = to_local(sun.global_position)
	$SunShapeCast.force_shapecast_update()
	
	_set_in_sunlight(not $SunShapeCast.is_colliding())

# --- Utilitários ---

func take_damage(amount: float) -> void:
	if is_immortal or _is_dashing: return
	
	health -= amount
	health = max(0, health)
	update_hud()
	
	if amount > 0.5:
		# Shake da câmera
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("shake"):
			cam.shake(5.0) # Dano causa um shake um pouco mais forte que o ataque
			
		# Flash visual
		var tween = create_tween()
		tween.tween_property($Sprite2D, "modulate", Color(5, 0.5, 0.5), 0.1)
		tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1), 0.1)
		
		# Partículas de sangue
		var blood = blood_scene.instantiate()
		get_parent().add_child(blood)
		blood.global_position = global_position
		blood.emitting = true
		get_tree().create_timer(blood.lifetime).timeout.connect(blood.queue_free)
	
	if health <= 0:
		_die()

## Aplica um efeito de veneno que causa dano ao longo do tempo.
func apply_poison(total_damage: float, duration: float) -> void:
	# Efeito visual esverdeado
	var visual_tween = create_tween()
	visual_tween.tween_property($Sprite2D, "modulate", Color(0.2, 1.2, 0.2), 0.2)
	visual_tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1), duration)
	
	# Dano particionado (5 ticks se a duração for 5s)
	var ticks = int(duration)
	var damage_per_tick = total_damage / ticks
	
	for i in range(ticks):
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self) and health > 0:
			take_damage(damage_per_tick)

func _die() -> void:
	var ds = death_screen_scene.instantiate()
	get_tree().root.add_child(ds)

func update_hud() -> void:
	if has_node("HUD/Control/VBoxContainer/HealthBar"):
		$HUD/Control/VBoxContainer/HealthBar.max_value = max_health
		$HUD/Control/VBoxContainer/HealthBar.value = health
	if has_node("HUD/Control/VBoxContainer/ManaBar"):
		$HUD/Control/VBoxContainer/ManaBar.max_value = max_mana
		$HUD/Control/VBoxContainer/ManaBar.value = mana

func _set_in_sunlight(is_in: bool) -> void:
	if _in_sunlight != is_in:
		_in_sunlight = is_in
		if _in_sunlight:
			$HUD/Control/VBoxContainer/HealthBar.modulate = Color(2, 1, 1)
			$BurnParticles.emitting = true
		else:
			$HUD/Control/VBoxContainer/HealthBar.modulate = Color(1, 1, 1)
			$BurnParticles.emitting = false

func _push_objects() -> void:
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var body = col.get_collider()
		if body is RigidBody2D:
			body.apply_central_impulse(col.get_normal() * -25.0)

func _animate() -> void:
	if velocity.length() > 5:
		_state_machine.travel("walk")
	else:
		_state_machine.travel("idle")

func _create_light_texture(size: int) -> GradientTexture2D:
	var grad = Gradient.new()
	grad.offsets = [0.0, 0.8]
	grad.colors = [Color(1,1,1,1), Color(1,1,1,0)]
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.use_hdr = true
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5) 
	tex.width = size
	tex.height = size
	return tex

# --- Sinais ---

func _on_dash_timer_timeout() -> void:
	_is_dashing = false
	$DashSmoke.emitting = false

func _on_cooldown_dash_timeout() -> void:
	_use_dash = true

func _on_attack_timer_timeout() -> void:
	_is_attacking = false
	$garra_player/hand.stop_attack()
