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
