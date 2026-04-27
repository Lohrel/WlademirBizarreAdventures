extends GutTest

var ItemDropScene = load("res://scenes/item_drop.tscn")
var Equipment = load("res://scripts/equipment.gd")
var PlayerScene = load("res://scenes/player.tscn")
var _player = null
var _root = null

func before_each():
	_root = Node2D.new()
	add_child(_root)
	
	var p_root = PlayerScene.instantiate()
	_player = p_root.get_node("player")
	_root.add_child(p_root)

func after_each():
	if is_instance_valid(_root):
		_root.free()

func test_equip_item_fails_when_slot_full():
	var boots1 = Equipment.new("Old Boots", Equipment.Slot.BOOTS, {"move_speed": 0.1})
	var boots2 = Equipment.new("New Boots", Equipment.Slot.BOOTS, {"move_speed": 0.2})
	
	assert_true(_player.equip_item(boots1), "First equip should succeed")
	assert_false(_player.equip_item(boots2), "Second equip in same slot should fail")
	assert_eq(_player.equipment[Equipment.Slot.BOOTS], boots1, "Original item should remain")

func test_pickup_blocked_when_slot_full():
	var boots1 = Equipment.new("Old Boots", Equipment.Slot.BOOTS, {"move_speed": 0.1})
	var boots2 = Equipment.new("New Boots", Equipment.Slot.BOOTS, {"move_speed": 0.2})
	
	_player.equip_item(boots1)
	
	var drop = ItemDropScene.instantiate()
	drop.equipment_data = boots2
	_root.add_child(drop)
	
	# Attempt collect
	drop._collect(_player)
	
	# Item should still exist (not queue_freed)
	assert_true(is_instance_valid(drop), "Item drop should still exist when slot is full")
	assert_eq(_player.equipment[Equipment.Slot.BOOTS], boots1, "Player should still have old boots")

func test_unequip_key_drops_item():
	var boots = Equipment.new("Boots", Equipment.Slot.BOOTS, {"move_speed": 0.1})
	_player.equip_item(boots)
	
	# Simulate 'G' key press
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_G
	_player._input(event)
	
	assert_null(_player.equipment[Equipment.Slot.BOOTS], "Slot should be empty after pressing G")
	
	# Verify that an ItemDrop was spawned in the parent
	var found_drop = false
	var parent = _player.get_parent()
	for child in parent.get_children():
		if child.get_script() and child.get_script().get_path().ends_with("item_drop.gd"):
			if child.equipment_data == boots:
				found_drop = true
				break
	
	assert_true(found_drop, "Item should have been dropped as an ItemDrop in the player's parent")
