extends GutTest

var PlayerScene = load("res://scenes/player.tscn")
var _player = null
var _root = null

func before_each():
	_root = PlayerScene.instantiate()
	_player = _root.get_node("player")

func after_each():
	if _root:
		_root.free()

func test_mana_regen():
	add_child(_root)
	_player.max_mana = 100.0
	_player.mana = 50.0
	_player._handle_environment(1.0)
	assert_gt(_player.mana, 50.0, "Mana should regenerate over time")

func test_health_updates_hud():
	add_child(_root)
	_player.max_health = 100.0
	_player.health = 80.0
	_player.update_hud()
	var health_bar = _player.get_node("../HUD/Control/VBoxContainer/HealthBar")
	assert_eq(health_bar.value, 80.0, "HUD health bar should reflect current health")

func test_mana_updates_hud():
	add_child(_root)
	_player.max_mana = 100.0
	_player.mana = 70.0
	_player.update_hud()
	var mana_bar = _player.get_node("../HUD/Control/VBoxContainer/ManaBar")
	assert_eq(mana_bar.value, 70.0, "HUD mana bar should reflect current mana")
