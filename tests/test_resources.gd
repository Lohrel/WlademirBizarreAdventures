extends GutTest

var PlayerScene = load("res://scenes/player.tscn")
var _player = null

func before_each():
	var root = PlayerScene.instantiate()
	_player = root.get_node("player")
	add_child(root)

func after_each():
	_player.get_parent().free()

func test_mana_regen():
	_player.mana = 50.0
	# Simulate 1 second of environment processing
	_player._handle_environment(1.0)
	assert_gt(_player.mana, 50.0, "Mana should regenerate over time")

func test_health_updates_hud():
	_player.take_damage(20)
	var health_bar = _player.get_node("HUD/Control/VBoxContainer/HealthBar")
	assert_eq(health_bar.value, 80.0, "HUD health bar should reflect current health")

func test_mana_updates_hud():
	_player.mana = 70.0
	_player.update_hud()
	var mana_bar = _player.get_node("HUD/Control/VBoxContainer/ManaBar")
	assert_eq(mana_bar.value, 70.0, "HUD mana bar should reflect current mana")
