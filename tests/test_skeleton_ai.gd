extends GutTest

var SkeletonScene = load("res://scenes/skeleton.tscn")
var _skeleton = null

func before_each():
	_skeleton = SkeletonScene.instantiate()
	add_child(_skeleton)
	# Mock player
	var player = CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	_skeleton.player = player

func after_each():
	_skeleton.free()

func test_skeleton_attack_range():
	assert_eq(_skeleton._get_attack_range(), 25.0, "Skeleton should have a short melee attack range")

func test_skeleton_telegraphing():
	# Initially it has no charging logic, so this flag will be missing or false
	if "_is_charging" in _skeleton:
		_skeleton._perform_attack()
		assert_true(_skeleton._is_charging, "Skeleton should have a charging state for telegraphing")
	else:
		assert_true(false, "Skeleton does not have telegraphing state implemented yet")
