extends GutTest

var PlayerScene = load("res://scenes/player.tscn")
var Equipment = load("res://scripts/equipment.gd")
var _player = null

func before_each():
	var root = PlayerScene.instantiate()
	_player = root.get_node("player")
	add_child(root)

func after_each():
	if is_instance_valid(_player) and _player.get_parent():
		_player.get_parent().free()

func test_equip_item():
	var item = Equipment.new("Speedy Boots", Equipment.Slot.BOOTS, {"move_speed": 50.0})
	_player.equip_item(item)
	
	assert_eq(_player.equipment[Equipment.Slot.BOOTS], item, "Item should be equipped in the BOOTS slot")

func test_unequip_item():
	var item = Equipment.new("Speedy Boots", Equipment.Slot.BOOTS, {"move_speed": 50.0})
	_player.equip_item(item)
	_player.unequip_item(Equipment.Slot.BOOTS)
	
	assert_null(_player.equipment[Equipment.Slot.BOOTS], "BOOTS slot should be empty after unequipping")

func test_equip_fails_if_occupied():
	var boots1 = Equipment.new("Old Boots", Equipment.Slot.BOOTS, {"move_speed": 10.0})
	var boots2 = Equipment.new("New Boots", Equipment.Slot.BOOTS, {"move_speed": 20.0})
	
	_player.equip_item(boots1)
	var result = _player.equip_item(boots2)
	
	assert_false(result, "Should return false when trying to equip into an occupied slot")
	assert_eq(_player.equipment[Equipment.Slot.BOOTS], boots1, "Original item should remain in the slot")
