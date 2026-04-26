extends GutTest

var PlayerScene = load("res://scenes/player.tscn")
var _player = null
var _root = null

func before_each():
	_root = PlayerScene.instantiate()
	_player = _root.get_node("player")
	add_child(_root)

func after_each():
	_root.free()

func test_apply_poison_deals_damage():
	var initial_health = _player.health
	# Apply 20 total damage over 0.5 seconds
	_player.apply_poison(20.0, 0.5)
	
	# Wait for all ticks (5 ticks)
	await wait_seconds(0.6)
	
	assert_lt(_player.health, initial_health, "Health should decrease after poison effect")
	assert_almost_eq(_player.health, initial_health - 20.0, 0.1, "Total damage should be around 20")

func test_apply_poison_visual_feedback():
	_player.apply_poison(10.0, 0.2)
	# Wait a bit for the tween to start
	await wait_seconds(0.05)
	var mod = _player.get_node("Sprite2D").modulate
	assert_gt(mod.r, 1.5, "Player should be tinted red (High Red component)")
	
	# Wait for completion (0.2s duration + 0.2s restore tween)
	await wait_seconds(0.5)
	mod = _player.get_node("Sprite2D").modulate
	assert_almost_eq(mod.r, 1.0, 0.1, "Red component should return to ~1.0")
	assert_almost_eq(mod.g, 1.0, 0.1, "Green component should return to ~1.0")
	assert_almost_eq(mod.b, 1.0, 0.1, "Blue component should return to ~1.0")
