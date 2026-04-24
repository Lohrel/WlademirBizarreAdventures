extends GutTest

var PlayerScene = load("res://scenes/player.tscn")
var _player = null
var _hand = null

func before_each():
	var root = PlayerScene.instantiate()
	_player = root.get_node("player")
	_hand = _player.get_node("garra_player/hand")
	add_child(root)

func after_each():
	_player.get_parent().free()

func test_attack_enables_hitbox():
	_player._attack() # Should trigger Input.is_action_just_pressed check if mocked
	# Since _attack() uses Input, I'll call _hand.start_attack() directly or mock input
	Input.action_press("attack")
	_player._handle_combat()
	Input.action_release("attack")
	
	assert_true(_hand.hitbox.monitoring, "Hitbox should be monitoring during attack")

func test_attack_damage_calculation():
	# Create a dummy enemy with take_damage method
	var enemy = Area2D.new()
	enemy.name = "Hurtbox"
	var enemy_logic = Node.new()
	enemy_logic.name = "Enemy"
	enemy.add_child(enemy_logic) # This doesn't quite work because hand.gd uses area.owner
	
	# Better to use a real enemy tscn if available or a mock
	var EnemyScript = load("res://scripts/enemy.gd")
	var mock_enemy = double(EnemyScript).new()
	var hurtbox = Area2D.new()
	hurtbox.name = "Hurtbox"
	mock_enemy.add_child(hurtbox)
	hurtbox.owner = mock_enemy
	
	# Manually trigger the hit
	_hand._on_hitbox_area_entered(hurtbox)
	
	assert_called(mock_enemy, "take_damage", [10.0, _hand.global_position, 300.0])
