extends Node

const Equipment = preload("res://scripts/equipment.gd")

## Slot to potential stats mapping
const SLOT_STATS = {
	Equipment.Slot.BOOTS: ["move_speed", "quicksand_speed", "dash_mana_cost_reduction", "dash_cooldown_reduction"],
	Equipment.Slot.GLOVES: ["attack_damage", "crit_chance", "attack_range"],
	Equipment.Slot.TUNIC: ["max_health", "health_regen", "max_mana"],
	Equipment.Slot.HAT: ["sunlight_damage_reduction"],
	Equipment.Slot.RING: ["dash_mastery"]
}

## Generates a random equipment piece scaled by level.
static func generate_item(level: int = 1) -> Equipment:
	var rarity = _roll_rarity()
	var slot = _get_random_slot()
	var item_name = _get_random_name(slot, rarity)
	var stats = _generate_random_stats(slot, level, rarity)
	
	return Equipment.new(item_name, slot, stats, rarity)

static func _roll_rarity() -> int:
	var roll = randf()
	if roll < 0.03: return Equipment.Rarity.LEGENDARY
	if roll < 0.10: return Equipment.Rarity.EPIC
	if roll < 0.25: return Equipment.Rarity.RARE
	if roll < 0.50: return Equipment.Rarity.UNCOMMON
	return Equipment.Rarity.COMMON

static func _get_random_slot() -> int:
	# Hat is rare (5% chance) - independently of item rarity tier
	if randf() < 0.05:
		return Equipment.Slot.HAT
	
	var slots = [Equipment.Slot.BOOTS, Equipment.Slot.GLOVES, Equipment.Slot.TUNIC, Equipment.Slot.RING]
	return slots[randi() % slots.size()]

static func _get_random_name(slot: int, rarity: int) -> String:
	var prefixes = {
		Equipment.Rarity.COMMON: ["Worn", "Simple", "Old", "Basic"],
		Equipment.Rarity.UNCOMMON: ["Reinforced", "Polished", "Sturdy"],
		Equipment.Rarity.RARE: ["Ancient", "Forgotten", "Egyptian", "Royal"],
		Equipment.Rarity.EPIC: ["Pharaoh's", "Shadowed", "Cursed", "Blessed"],
		Equipment.Rarity.LEGENDARY: ["Godly", "Eternal", "Solar", "Osiris'"]
	}
	var current_prefixes = prefixes[rarity]
	var base_names = {
		Equipment.Slot.BOOTS: "Sandals",
		Equipment.Slot.GLOVES: "Wraps",
		Equipment.Slot.TUNIC: "Robe",
		Equipment.Slot.HAT: "Crown",
		Equipment.Slot.RING: "Signet"
	}
	return current_prefixes[randi() % current_prefixes.size()] + " " + base_names[slot]

static func _generate_random_stats(slot: int, level: int, rarity: int) -> Dictionary:
	var stats = {}
	var possible_stats = SLOT_STATS[slot].duplicate()
	
	# Multpliers based on rarity
	var rarity_mult = 1.0
	var num_stats = 1
	
	match rarity:
		Equipment.Rarity.UNCOMMON:
			rarity_mult = 1.2
		Equipment.Rarity.RARE:
			rarity_mult = 1.5
			num_stats = randi_range(1, 2)
		Equipment.Rarity.EPIC:
			rarity_mult = 2.0
			num_stats = randi_range(2, 3)
		Equipment.Rarity.LEGENDARY:
			rarity_mult = 3.0
			num_stats = randi_range(3, 4)
	
	possible_stats.shuffle()
	
	for i in range(min(num_stats, possible_stats.size())):
		var stat_name = possible_stats[i]
		# Scaling base: 1% to 6% per level * rarity multiplier
		var base_boost = randf_range(0.01, 0.06) * level * rarity_mult
		
		# Balanço específico para regeneração: max 3% no lvl 1 para lendários (0.01 * 1 * 3.0)
		if stat_name == "health_regen":
			base_boost = randf_range(0.005, 0.01) * level * rarity_mult
		
		# Balanço específico para dano de ataque: aumentado (5% a 15% por nível base)
		if stat_name == "attack_damage":
			base_boost = randf_range(0.05, 0.15) * level * rarity_mult
			
		stats[stat_name] = base_boost
		
	return stats
