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

func test_stat_recalculation_speed():
	var initial_speed = _player._move_speed
	var boots = Equipment.new("Speedy Boots", Equipment.Slot.BOOTS, {"move_speed": 0.5}) # 50% increase
	_player.equip_item(boots)
	
	assert_eq(_player._move_speed, initial_speed * 1.5, "Movement speed should increase by 50%")
	
	_player.unequip_item(Equipment.Slot.BOOTS)
	assert_eq(_player._move_speed, initial_speed, "Movement speed should return to base after unequip")

func test_stat_recalculation_health():
	var initial_max_health = _player.max_health
	var tunic = Equipment.new("Heavy Tunic", Equipment.Slot.TUNIC, {"max_health": 0.25}) # 25% increase
	_player.equip_item(tunic)
	
	assert_eq(_player.max_health, initial_max_health * 1.25, "Max health should increase by 25%")
	
	_player.unequip_item(Equipment.Slot.TUNIC)
	assert_eq(_player.max_health, initial_max_health, "Max health should return to base after unequip")

func test_stat_recalculation_attack():
	var hand = _player.get_node("garra_player/hand")
	var initial_damage = hand.attack_damage
	var gloves = Equipment.new("Power Gloves", Equipment.Slot.GLOVES, {"attack_damage": 0.5}) # 50% increase
	_player.equip_item(gloves)
	
	assert_eq(hand.attack_damage, initial_damage * 1.5, "Attack damage should increase by 50%")
