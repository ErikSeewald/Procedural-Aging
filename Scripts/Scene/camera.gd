extends Node3D

@export var move_speed: float = 6.0
@export var look_speed: float = 2.0

var yaw := 0.0
var pitch := 0.0

func _process(delta: float) -> void:
	# Looking
	var look_x := 0.0
	var look_y := 0.0
	if Input.is_action_pressed("look_left"):
		look_x -= 1.0
	if Input.is_action_pressed("look_right"):
		look_x += 1.0
	if Input.is_action_pressed("look_up"):
		look_y -= 1.0
	if Input.is_action_pressed("look_down"):
		look_y += 1.0

	yaw   -= look_x * look_speed * delta
	pitch -= look_y * look_speed * delta
	pitch = clamp(pitch, -PI * 0.5, PI * 0.5)

	rotation.y = yaw
	rotation.x = pitch

	# Movement
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		dir += Vector3.FORWARD
	if Input.is_action_pressed("move_back"):
		dir -= Vector3.FORWARD
	if Input.is_action_pressed("move_left"):
		dir -= Vector3.RIGHT
	if Input.is_action_pressed("move_right"):
		dir += Vector3.RIGHT
	if Input.is_action_pressed("move_up"):
		dir += Vector3.UP
	if Input.is_action_pressed("move_down"):
		dir -= Vector3.UP

	if dir != Vector3.ZERO:
		dir = dir.normalized()
		var velocity := dir * move_speed * delta
		translate(velocity)
