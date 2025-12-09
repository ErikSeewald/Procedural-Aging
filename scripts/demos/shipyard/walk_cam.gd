extends CharacterBody3D

@export var move_speed: float = 6.0
@export var mouse_sensitivity: float = 0.003

var yaw := 0.0
var pitch := 0.0

@onready var camera: Camera3D = $Camera3D
var _mouse_captured := true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pitch = camera.rotation.x
	yaw = rotation.y

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_captured:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -PI * 0.5, PI * 0.5)

		rotation.y = yaw
		camera.rotation.x = pitch

	if event.is_action_pressed("ui_toggle"):
		_mouse_captured = !_mouse_captured
		if _mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(_delta: float) -> void:
	var input_vec = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_vec.z -= 1.0
	if Input.is_action_pressed("move_back"):
		input_vec.z += 1.0
	if Input.is_action_pressed("move_right"):
		input_vec.x += 1.0
	if Input.is_action_pressed("move_left"):
		input_vec.x -= 1.0

	if input_vec != Vector3.ZERO:
		input_vec = input_vec.normalized()

	var speed = move_speed
	if Input.is_action_pressed("sprint"):
		speed *= 2

	var direction = (transform.basis * input_vec).normalized()
	velocity = direction * speed
	move_and_slide()
