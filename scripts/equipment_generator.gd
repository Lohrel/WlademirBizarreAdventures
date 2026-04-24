extends Node

const Equipment = preload("res://scripts/equipment.gd")

## Slot to potential stats mapping
const SLOT_STATS = {
	Equipment.Slot.BOOTS: ["move_speed", "quicksand_speed", "dash_mana_cost_reduction", "dash_cooldown_reduction"],
	Equipment.Slot.GLOVES: ["attack_damage", "crit_chance", "attack_range"],
	Equipment.Slot.TUNIC: ["max_health", "health_regen", "max_mana"],
	Equipment.Slot.HAT: ["sunlight_damage_reduction"],
	Equipment.Slot.RING: ["skill_modifier"] # Placeholder for now
}

## Generates a random equipment piece scaled by level.
func generate_item(level: int = 1) -> Equipment:
	var slot = _get_random_slot()
	var item_name = _get_random_name(slot)
	var stats = _generate_random_stats(slot, level)
	
	return Equipment.new(item_name, slot, stats)

func _get_random_slot() -> int:
	# Hat is rare (5% chance)
	if randf() < 0.05:
		return Equipment.Slot.HAT
	
	var slots = [Equipment.Slot.BOOTS, Equipment.Slot.GLOVES, Equipment.Slot.TUNIC, Equipment.Slot.RING]
	return slots[randi() % slots.size()]

func _get_random_name(slot: int) -> String:
	var prefixes = ["Ancient", "Forgotten", "Cursed", "Blessed", "Royal", "Sandy", "Pharaoh's"]
	var base_names = {
		Equipment.Slot.BOOTS: "Sandals",
		Equipment.Slot.GLOVES: "Wraps",
		Equipment.Slot.TUNIC: "Robe",
		Equipment.Slot.HAT: "Crown",
		Equipment.Slot.RING: "Signet"
	}
	return prefixes[randi() % prefixes.size()] + " " + base_names[slot]

func _generate_random_stats(slot: int, level: int) -> Dictionary:
	var stats = {}
	var possible_stats = SLOT_STATS[slot].duplicate()
	
	# Pick 1-2 random stats from the pool
	var num_stats = 1 if randf() > 0.3 else 2
	possible_stats.shuffle()
	
	for i in range(min(num_stats, possible_stats.size())):
		var stat_name = possible_stats[i]
		# Scaling: 1% to 6% per level (multiplicative)
		# For level 1: 1.01 to 1.06
		var base_boost = randf_range(0.01, 0.06) * level
		stats[stat_name] = base_boost
		
	return stats
