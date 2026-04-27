extends GutTest

var MummyScene = load("res://scenes/mumia.tscn")
var _mummy = null

func before_each():
	_mummy = MummyScene.instantiate()
	add_child(_mummy)
	# Mock player for AI logic
	var player = CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	_mummy.player = player

func after_each():
	_mummy.free()

func test_mummy_attack_range():
	assert_eq(_mummy._get_attack_range(), 300.0, "Mummy should have an attack range of 300")

func test_mummy_telegraphing():
	_mummy._perform_attack()
	assert_true(_mummy._is_charging, "Mummy should be in charging state when telegraphing")

func test_mummy_stops_during_attack():
	_mummy.velocity = Vector2(100, 100)
	_mummy._perform_attack()
	assert_eq(_mummy.velocity, Vector2.ZERO, "Mummy should stop moving when performing an attack")
