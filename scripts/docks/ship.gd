extends Node3D

# Bobs and tilts the ship like waves

@export var bob_amplitude: float = 0.25
@export var bob_speed: float = 1.0
@export var tilt_amplitude: float = 0.6
@export var tilt_speed: float = 0.6

var _time: float = 0.0
var _base_position: Vector3
var _base_rotation: Vector3
var _phase_offset: float = 0.0

func _ready():
	_base_position = global_transform.origin
	_base_rotation = rotation_degrees
	_phase_offset = float(get_instance_id() % 1000) / 1000.0

func _process(delta: float) -> void:
	_time += delta
	
	var bob_offset = sin(_time * bob_speed + _phase_offset) * bob_amplitude
	
	var tilt_x = sin(_time * tilt_speed + _phase_offset) * tilt_amplitude
	var tilt_z = cos(_time * tilt_speed * 1.3 + _phase_offset * 1.1) * tilt_amplitude
	
	var new_pos = _base_position
	new_pos.y += bob_offset
	global_transform.origin = new_pos
	
	rotation_degrees.x = _base_rotation.x + tilt_x
	rotation_degrees.z = _base_rotation.z + tilt_z
