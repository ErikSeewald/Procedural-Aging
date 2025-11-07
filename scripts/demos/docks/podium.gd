extends Node3D
class_name Podium

@onready var button_area := $Button/Area3D
@onready var podium_mesh := $Podium
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var default_texture: Texture2D
@export var activated_texture: Texture2D
@export var click_sound: AudioStream

var _podium_mat: StandardMaterial3D
var _sfx_player: AudioStreamPlayer

signal button_pressed

func _ready() -> void:
	_podium_mat = podium_mesh.get_active_material(0)
	_podium_mat.albedo_texture = default_texture
	button_area.input_event.connect(_on_input)
	
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.stream = click_sound
	add_child(_sfx_player)

func _on_input(_camera: Node, event: InputEvent, _event_position: Vector3, 
_normal: Vector3,  _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		button_pressed.emit()
		animation_player.play("ButtonPressAction")
		_sfx_player.play()
		
func switch_material(is_active: bool) -> void:
	if is_active:
		_podium_mat.albedo_texture = activated_texture
	else:
		_podium_mat.albedo_texture = default_texture
