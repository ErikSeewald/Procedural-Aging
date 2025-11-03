extends Node3D
class_name Podium

@onready var button_area := $Button/Area3D

signal button_pressed

func _ready() -> void:
	button_area.input_event.connect(_on_input)

func _on_input(_camera: Node, event: InputEvent, _event_position: Vector3, 
_normal: Vector3,  _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		button_pressed.emit()
