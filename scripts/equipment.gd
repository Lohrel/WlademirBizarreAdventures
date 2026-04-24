## Define os tipos de equipamentos e seus atributos.
class_name Equipment
extends Resource

enum Slot { BOOTS, GLOVES, TUNIC, HAT, RING }

@export var name: String = "Unknown Item"
@export var slot: Slot = Slot.TUNIC
@export var icon: Texture2D

## Dicionário de bônus de atributos.
## Ex: {"max_health": 5.0, "move_speed": 10.0}
@export var stats: Dictionary = {}

func _init(p_name: String = "", p_slot: Slot = Slot.TUNIC, p_stats: Dictionary = {}):
	name = p_name
	slot = p_slot
	stats = p_stats
