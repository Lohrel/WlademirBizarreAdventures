extends GutTest

var CameraScript = load("res://scripts/camera_2d.gd")
var _cam = null

func before_each():
	_cam = CameraScript.new()
	add_child(_cam)

func after_each():
	_cam.free()

func test_camera_shake_sets_amount():
	_cam.shake(10.0)
	assert_eq(_cam._shake_amount, 10.0, "Shake amount should be set")

func test_camera_shake_decays():
	_cam.shake(10.0)
	_cam._process(0.1)
	assert_lt(_cam._shake_amount, 10.0, "Shake amount should decay over time")
