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
	Engine.time_scale = 1.0 # Ensure engine speed is reset

func test_hit_stop_triggers():
	# Create a dummy enemy
	var EnemyScript = load("res://scripts/enemy.gd")
	var mock_enemy = double(EnemyScript).new()
	var hurtbox = Area2D.new()
	hurtbox.name = "Hurtbox"
	mock_enemy.add_child(hurtbox)
	hurtbox.owner = mock_enemy
	
	_hand._on_hitbox_area_entered(hurtbox)
	
	assert_lt(Engine.time_scale, 1.0, "Engine time_scale should drop during hit stop")
