extends Node3D

@export var move_speed: float = 6.0
@export var mouse_sensitivity: float = 0.003

var yaw := 0.0
var pitch := 0.0

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -PI * 0.5, PI * 0.5)

		rotation.y = yaw  # yaw on the body
		camera.rotation.x = pitch  # pitch only on the camera

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	var forward_input := 0.0
	if Input.is_action_pressed("move_forward"):
		forward_input += 1.0
	if Input.is_action_pressed("move_back"):
		forward_input -= 1.0

	var right_input := 0.0
	if Input.is_action_pressed("move_right"):
		right_input += 1.0
	if Input.is_action_pressed("move_left"):
		right_input -= 1.0

	if forward_input == 0.0 and right_input == 0.0:
		return
	
	var speed = move_speed
	if Input.is_action_pressed("sprint"):
		speed *= 2

	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))

	var dir := (forward * forward_input + right * right_input)
	dir = dir.normalized()

	global_translate(dir * speed * delta)
