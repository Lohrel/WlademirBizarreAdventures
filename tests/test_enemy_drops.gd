extends GutTest

var EnemyScene = load("res://scenes/skeleton.tscn")
var _enemy = null

func before_each():
	_enemy = EnemyScene.instantiate()
	add_child(_enemy)

func after_each():
	_enemy.free()

func test_enemy_drop_logic():
	# Mock the generator and drop scene if necessary, 
	# but for now I'll just check if the logic is called
	# This is more of an integration test
	pass
