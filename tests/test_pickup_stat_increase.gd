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
	if is_instance_valid(_player) and _player.get_parent():
		_player.get_parent().free()

func test_pickup_increases_speed():
	var initial_speed = _player._move_speed
	var drop = ItemDropScene.instantiate()
	var boots = Equipment.new("Speedy Boots", Equipment.Slot.BOOTS, {"move_speed": 0.5})
	drop.equipment_data = boots
	add_child(drop)
	
	drop._collect(_player)
	
	assert_eq(_player._move_speed, initial_speed * 1.5, "Movement speed should increase by 50% after picking up boots")

func test_pickup_increases_max_health():
	var initial_max_health = _player.max_health
	var drop = ItemDropScene.instantiate()
	var tunic = Equipment.new("Heavy Tunic", Equipment.Slot.TUNIC, {"max_health": 0.25})
	drop.equipment_data = tunic
	add_child(drop)
	
	drop._collect(_player)
	
	assert_eq(_player.max_health, initial_max_health * 1.25, "Max health should increase by 25% after picking up tunic")

func test_pickup_increases_attack_damage():
	var hand = _player.get_node("garra_player/hand")
	var initial_damage = hand.attack_damage
	var drop = ItemDropScene.instantiate()
	var gloves = Equipment.new("Power Gloves", Equipment.Slot.GLOVES, {"attack_damage": 0.5})
	drop.equipment_data = gloves
	add_child(drop)
	
	drop._collect(_player)
	
	assert_eq(hand.attack_damage, initial_damage * 1.5, "Attack damage should increase by 50% after picking up gloves")
