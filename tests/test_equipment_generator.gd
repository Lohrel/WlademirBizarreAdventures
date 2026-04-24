extends GutTest

var Generator = load("res://scripts/equipment_generator.gd")
var _gen = null

func before_each():
	_gen = Generator.new()
	add_child(_gen)

func after_each():
	_gen.free()

func test_generate_item_level_1_scaling():
	# Since scaling now depends on rarity, we check against the rarity multiplier
	var item = _gen.generate_item(1)
	assert_not_null(item, "Should generate an item")
	
	var mult = 1.0
	match item.rarity:
		Equipment.Rarity.UNCOMMON: mult = 1.2
		Equipment.Rarity.RARE: mult = 1.5
		Equipment.Rarity.EPIC: mult = 2.0
		Equipment.Rarity.LEGENDARY: mult = 3.0
	
	for stat in item.stats:
		var val = item.stats[stat]
		# base is 0.01 to 0.06 * level * rarity_mult
		assert_between(val, 0.009 * mult, 0.061 * mult, "Stat boost should scale with rarity")

func test_generate_item_level_10_scaling():
	var item = _gen.generate_item(10)
	var mult = 1.0
	match item.rarity:
		Equipment.Rarity.UNCOMMON: mult = 1.2
		Equipment.Rarity.RARE: mult = 1.5
		Equipment.Rarity.EPIC: mult = 2.0
		Equipment.Rarity.LEGENDARY: mult = 3.0
	
	for stat in item.stats:
		var val = item.stats[stat]
		# base is 0.01 to 0.06 * level * rarity_mult
		assert_between(val, 0.09 * mult, 0.61 * mult, "Level 10 stat boost should scale with rarity")

func test_slot_stat_constraints():
	# Test multiple items to ensure stats match slots
	for i in range(20):
		var item = _gen.generate_item(1)
		var possible = _gen.SLOT_STATS[item.slot]
		for stat in item.stats:
			assert_true(stat in possible, "Stat %s should be valid for slot %s" % [stat, item.slot])
