extends GutTest

var Equipment = load("res://scripts/equipment.gd")

func test_equipment_init():
	var stats = {"max_health": 5.0}
	var item = Equipment.new("Test Tunic", Equipment.Slot.TUNIC, stats)
	
	assert_eq(item.name, "Test Tunic", "Name should be set correctly")
	assert_eq(item.slot, Equipment.Slot.TUNIC, "Slot should be TUNIC")
	assert_eq(item.stats["max_health"], 5.0, "Stats should be stored correctly")

func test_slot_enum_values():
	assert_eq(Equipment.Slot.BOOTS, 0)
	assert_eq(Equipment.Slot.GLOVES, 1)
	assert_eq(Equipment.Slot.TUNIC, 2)
	assert_eq(Equipment.Slot.HAT, 3)
	assert_eq(Equipment.Slot.RING, 4)
