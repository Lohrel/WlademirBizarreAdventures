extends GutTest

var Player = load("res://scripts/player.gd")
var _player = null

func before_each():
	_player = Player.new()
	# We need to mock some dependencies or ensure they exist if we use instantiate
	# For unit tests, it's better to use Player.new() if logic is decoupled
	# but Godot classes often depend on nodes.
	
	# Since player.gd uses @export and $, we might need to instantiate the scene instead
	var scene = load("res://scenes/player.tscn")
	var root = scene.instantiate()
	_player = root.get_node("player")
	add_child(root)

func after_each():
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
	Input.action_press("dash")
	_player._dash()
	Input.action_release("dash")
	
	# Simulate physics process for the duration of the dash
	var duration = _player._dash_timer.wait_time
	var steps = int(duration / 0.016) # 60 fps
	for i in range(steps):
		_player._physics_process(0.016)
	
	assert_gt(_player.global_position.length(), 100.0, "Player should have moved a significant distance during dash")

func test_dash_invincibility():
	_player._is_dashing = true
	_player.take_damage(10)
	assert_eq(_player.health, 100.0, "Player should not take damage while dashing")
