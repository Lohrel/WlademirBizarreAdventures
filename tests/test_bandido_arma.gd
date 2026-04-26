extends GutTest

var BanditScene = load("res://scenes/bandido_arma.tscn")
var _bandit = null

func before_each():
	_bandit = BanditScene.instantiate()
	add_child(_bandit)
	# Mock player
	var player = CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	_bandit.player = player

func after_each():
	_bandit.free()

func test_bandit_burst_stats():
	assert_eq(_bandit.shots_per_burst, 12, "Bandit should shoot 12 times per burst")
	assert_eq(_bandit.time_between_shots, 0.3, "Bandit should have 0.3s between shots")
	assert_eq(_bandit.reload_time, 4.0, "Bandit should have 4s reload time")

func test_bandit_attack_range():
	assert_eq(_bandit._get_attack_range(), 250.0, "Bandit should have an attack range of 250")

func test_bandit_charging_state():
	_bandit._perform_attack()
	assert_true(_bandit._is_charging, "Bandit should be in charging state while firing burst")
