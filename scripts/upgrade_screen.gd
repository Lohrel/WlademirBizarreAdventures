## Gerencia a tela de seleção de upgrade após derrotar um chefe.
## Gerencia a seleção aleatória de upgrades e os aplica ao jogador.
class_name UpgradeScreen
extends Control

# --- Referências ---
var player: PlayerController = null
var level_generator: LevelGenerator = null

# --- Configuração de Upgrade ---
var upgrade_pool = [
	{"name": "Raise Max Health +15%", "type": "max_health"},
	{"name": "Raise Max Mana +15%", "type": "max_mana"},
	{"name": "Raise Attack Damage +15%", "type": "damage"},
	{"name": "Raise Attack Range +15%", "type": "range"},
	{"name": "Raise Attack Hitbox +15%", "type": "hitbox"},
	{"name": "Passive Regen +2%/s", "type": "regen"}
]

var chosen_upgrades = []

# --- Nós Onready ---
@onready var buttons = [
	$VBoxContainer/HBoxContainer/Button1,
	$VBoxContainer/HBoxContainer/Button2,
	$VBoxContainer/HBoxContainer/Button3
]

# --- Ciclo de Vida ---

func _ready() -> void:
	# Pausa o jogo e mostra o mouse
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Seleciona 3 upgrades aleatórios únicos do conjunto
	var pool_copy = upgrade_pool.duplicate()
	pool_copy.shuffle()
	chosen_upgrades = pool_copy.slice(0, 3)
	
	# Conecta botões e define o texto
	for i in range(buttons.size()):
		buttons[i].text = chosen_upgrades[i]["name"]
		buttons[i].pressed.connect(_on_upgrade_selected.bind(i))

# --- Lógica de Configuração ---

## Configura as referências do jogador e do gerador.
func setup(p: Node, lg: LevelGenerator) -> void:
	# Gerencia possível nó de invólucro do jogador
	if p.has_node("player"):
		player = p.get_node("player")
	else:
		player = p
	
	level_generator = lg

# --- Lógica de Seleção ---

func _on_upgrade_selected(index: int) -> void:
	# Evita cliques duplos e esconde a UI imediatamente
	get_parent().visible = false
	set_process_input(false)
	
	# Aplica o upgrade escolhido
	var upgrade = chosen_upgrades[index]
	_apply_upgrade(upgrade)
	
	# Retoma o jogo e gera o próximo nível
	get_tree().paused = false
	if level_generator:
		level_generator.generate_new_level()
	
	# Libera o CanvasLayer
	get_parent().queue_free()

## Aplica a lógica do upgrade escolhido aos atributos do jogador.
func _apply_upgrade(upgrade: Dictionary) -> void:
	if not player: return
	
	match upgrade["type"]:
		"max_health":
			player.max_health *= 1.15
			player.health *= 1.15
		"max_mana":
			player.max_mana *= 1.15
			player.mana *= 1.15
		"damage":
			var hand = player.get_node_or_null("garra_player/hand")
			if hand: hand.attack_damage *= 1.15
		"range":
			player.attack_range_multiplier *= 1.15
		"hitbox":
			var hitbox_shape = player.get_node_or_null("garra_player/hand/Hitbox/CollisionShape2D")
			if hitbox_shape and hitbox_shape.shape is CircleShape2D:
				hitbox_shape.shape.radius *= 1.15
		"regen":
			player.passive_regen_percent += 0.02
	
	# Atualiza a UI
	player.update_hud()
