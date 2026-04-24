extends GutTest

var ItemDropScene = load("res://scenes/item_drop.tscn")
var Equipment = load("res://scripts/equipment.gd")
var PlayerScene = load("res://scenes/player.tscn")
var _player = null

func before_each():
	var root = PlayerScene.instantiate()
	_player = root.get_node("player")
	add_child(root)

func after_each():
	_player.get_parent().free()

func test_pickup_equipment():
	var drop = ItemDropScene.instantiate()
	var boots = Equipment.new("Speedy Boots", Equipment.Slot.BOOTS, {"move_speed": 50.0})
	drop.equipment_data = boots
	add_child(drop)
	
	drop._collect(_player)
	
	assert_eq(_player.equipment[Equipment.Slot.BOOTS], boots, "Player should have equipped the picked up boots")
