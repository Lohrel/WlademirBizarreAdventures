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

func test_stat_recalculation_crit():
	var initial_crit = _player.crit_chance
	var gloves = Equipment.new("Assassin Wraps", Equipment.Slot.GLOVES, {"crit_chance": 0.1}) 
	_player.equip_item(gloves)
	
	assert_eq(_player.crit_chance, initial_crit + 0.1, "Crit chance should increase by flat 0.1")

func test_stat_recalculation_quicksand():
	var initial_qs = _player.quicksand_speed_bonus
	var boots = Equipment.new("Desert Boots", Equipment.Slot.BOOTS, {"quicksand_speed": 0.2})
	_player.equip_item(boots)
	
	assert_eq(_player.quicksand_speed_bonus, initial_qs + 0.2, "Quicksand speed bonus should increase by flat 0.2")

func test_stat_recalculation_dash_reductions():
	var initial_mana_cost = _player.dash_mana_cost
	var initial_cooldown = _player.dash_cooldown_time
	
	# Test Boots with 20% reduction
	var boots = Equipment.new("Efficient Sandals", Equipment.Slot.BOOTS, {
		"dash_mana_cost_reduction": 0.2,
		"dash_cooldown_reduction": 0.2
	})
	_player.equip_item(boots)
	
	# Reduction is relative to base
	assert_eq(_player.dash_mana_cost, initial_mana_cost * 0.8, "Dash mana cost should be reduced by 20%")
	assert_eq(_player.dash_cooldown_time, initial_cooldown * 0.8, "Dash cooldown should be reduced by 20%")

func test_stat_recalculation_skill_modifier():
	var initial_dash_speed = _player._dash_speed
	var initial_mana_cost = _player.dash_mana_cost
	
	# Test Ring with 20% dash_mastery (1.0 -> 1.2)
	var ring = Equipment.new("Master Ring", Equipment.Slot.RING, {"dash_mastery": 0.2})
	_player.equip_item(ring)
	
	# _dash_speed *= 1.2, dash_mana_cost /= 1.2
	assert_eq(_player._dash_speed, initial_dash_speed * 1.2, "Dash speed should be increased by dash mastery")
	assert_almost_eq(_player.dash_mana_cost, initial_mana_cost / 1.2, 0.01, "Dash mana cost should be divided by dash mastery")
