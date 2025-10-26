extends Node3D

@onready var camera: Camera3D = $Camera3D

@onready var ui: Panel = $UI
@onready var rotating_button: CheckButton = $UI/MarginContainer/VBoxContainer/Rotating
@onready var amount_input: SpinBox = $UI/MarginContainer/VBoxContainer/Amount

enum MeshLayout { SQUARE, CUBE }
var _cur_layout: MeshLayout = MeshLayout.SQUARE
var _cur_amount: int
var _rotating: bool = false

var _multi_mesh_instance: MultiMeshInstance3D
var age = 0.0
var _cur_mat: ShaderMaterial

func _ready() -> void:
	_multi_mesh_instance = MultiMeshInstance3D.new()
	rotating_button.visible = _cur_layout == MeshLayout.CUBE
	add_child(_multi_mesh_instance)
	set_multi_mesh(int(amount_input.value))
	

func _process(delta: float) -> void:
	if _rotating:
		_multi_mesh_instance.rotate_y(delta * 0.25)
		
	age += delta
	_cur_mat.set_shader_parameter("age", age)

func set_rotating(rotating: bool) -> void:
	_rotating = rotating
	if !rotating:
		_multi_mesh_instance.transform = Transform3D()

func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled
	
func switch_to_shader(shader: ShaderMaterial) -> void:
	_cur_mat = shader
	_multi_mesh_instance.material_override = shader

func set_layout(layout: int) -> void:
	_cur_layout = layout as MeshLayout
	
	var is_cube = _cur_layout == MeshLayout.CUBE
	rotating_button.visible = is_cube
	
	if !is_cube:
		set_rotating(false)
		rotating_button.button_pressed = false
	set_multi_mesh(_cur_amount)

func set_multi_mesh(amount: int) -> void:
	_cur_amount = amount
	var instance_count: int
	
	match _cur_layout:
		MeshLayout.SQUARE:
			instance_count = int(pow(amount, 2))
		MeshLayout.CUBE:
			instance_count = int(pow(amount, 3))
	
	var multimesh := MultiMesh.new()
	multimesh.mesh = SphereMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count

	match _cur_layout:
		MeshLayout.SQUARE:
			_populate_square(multimesh, amount)
			camera.position = Vector3(amount*0.5, amount*0.5, 1.0 + amount*0.75)
		MeshLayout.CUBE:
			_populate_cube(multimesh, amount)
			camera.position = Vector3(amount*0.5, amount*0.5, 1.0 + amount*1.75)
	
	_multi_mesh_instance.multimesh = multimesh

func _populate_square(multi_mesh: MultiMesh, square_size: int):
	var i = 0
	for x in range(square_size):
		for y in range(square_size):
				var pos = Vector3(x, y, 0.0)
				multi_mesh.set_instance_transform(i, Transform3D(Basis(), pos))
				i += 1

func _populate_cube(multi_mesh: MultiMesh, cube_size: int):
	var i = 0
	for x in range(cube_size):
		for y in range(cube_size):
			for z in range(cube_size):
				var pos = Vector3(x, y, z)
				multi_mesh.set_instance_transform(i, Transform3D(Basis(), pos))
				i += 1
