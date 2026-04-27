extends GutTest

var Player = load("res://scripts/player.gd")
var _player = null

func before_each():
	var scene = load("res://scenes/player.tscn")
	var root = scene.instantiate()
	_player = root.get_node("player")
	add_child(root)

func after_each():
	if _player and _player.get_parent():
		_player.get_parent().free()

func test_dash_mana_cost():
	var initial_mana = _player.mana
	Input.action_press("dash")
	_player._dash()
	Input.action_release("dash")
	assert_lt(_player.mana, initial_mana, "Mana should decrease after dashing")

func test_dash_sets_is_dashing():
	Input.action_press("dash")
	_player._dash()
	Input.action_release("dash")
	assert_true(_player._is_dashing, "Player should be dashing after dash input")

func test_dash_distance():
	_player.global_position = Vector2.ZERO
	_player._last_direction = Vector2.RIGHT
	Input.action_press("dash")
	_player._dash()
	Input.action_release("dash")
	
	# Force direction just in case InputMap isn't perfect in headless
	_player._dash_direction = Vector2.RIGHT
	_player._is_dashing = true
	
	# Simulate physics process for the duration of the dash
	var duration = _player._dash_timer.wait_time
	# Godot 4 move_and_slide uses internal delta, but we can mock it by calling multiple times
	# or just checking velocity.
	var steps = int(duration / 0.016) + 1
	for i in range(steps):
		_player._physics_process(0.016)
	
	assert_gt(_player.global_position.length(), 50.0, "Player should have moved a significant distance during dash")

func test_dash_invincibility():
	_player._is_dashing = true
	_player.take_damage(10)
	assert_eq(_player.health, 100.0, "Player should not take damage while dashing")

func test_dash_animation_triggered():
	_player._animation_tree.active = true
	_player._state_machine.start("idle")
	
	_player._last_direction = Vector2.RIGHT
	Input.action_press("dash")
	_player._dash()
	_player._dash_direction = Vector2.RIGHT # Ensure direction for test
	Input.action_release("dash")
	
	_player._animate()
	# Give it a small advance to process state change
	_player._animation_tree.advance(0.01)
	
	assert_eq(_player._state_machine.get_current_node(), "dash", "Animation state should be 'dash' while dashing")
	assert_almost_eq(_player.get_node("Sprite2D").rotation, PI/2, 0.01, "Sprite should be rotated 90 degrees for right dash")

func test_dash_rotation_resets():
	_player._is_dashing = true
	_player._dash_direction = Vector2.RIGHT
	_player._animate()
	assert_ne(_player.get_node("Sprite2D").rotation, 0.0, "Rotation should be non-zero while dashing")
	
	_player._on_dash_timer_timeout()
	assert_eq(_player.get_node("Sprite2D").rotation, 0.0, "Rotation should reset to 0 after dash timer timeout")

func test_garra_player_hidden_during_dash():
	_player._is_dashing = true
	_player._dash_direction = Vector2.RIGHT
	_player._animate()
	assert_false(_player.get_node("garra_player").visible, "garra_player should be hidden while dashing")
	
	_player._on_dash_timer_timeout()
	assert_true(_player.get_node("garra_player").visible, "garra_player should be visible after dash")
