extends GutTest

var Generator = load("res://scripts/equipment_generator.gd")
var _gen = null

func before_each():
	_gen = Generator.new()
	add_child(_gen)

func after_each():
	_gen.free()

func test_generate_item_level_1_scaling():
	var item = _gen.generate_item(1)
	assert_not_null(item, "Should generate an item")
	for stat in item.stats:
		var val = item.stats[stat]
		assert_between(val, 0.01, 0.06, "Level 1 stat boost should be between 1% and 6%")

func test_generate_item_level_10_scaling():
	var item = _gen.generate_item(10)
	for stat in item.stats:
		var val = item.stats[stat]
		assert_between(val, 0.1, 0.6, "Level 10 stat boost should be between 10% and 60%")

func test_slot_stat_constraints():
	# Test multiple items to ensure stats match slots
	for i in range(20):
		var item = _gen.generate_item(1)
		var possible = _gen.SLOT_STATS[item.slot]
		for stat in item.stats:
			assert_true(stat in possible, "Stat %s should be valid for slot %s" % [stat, item.slot])
