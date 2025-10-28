extends Node3D

@onready var camera: Camera3D = $Camera3D

@onready var ui: Panel = $UI
@onready var rotating_button: CheckButton = $UI/MarginContainer/VBoxContainer/Rotating
@onready var amount_input: SpinBox = $UI/MarginContainer/VBoxContainer/Amount

@onready var testing_multiple_template: PackedScene = preload("res://scenes/profiling/base_sphere.tscn")
var spawned_objects = []

enum MeshLayout { SQUARE, CUBE }
var _cur_layout: MeshLayout = MeshLayout.SQUARE
var _cur_amount: int
var _rotating: bool = false

var _multi_mesh_instance: MultiMeshInstance3D
var age = 0.0
var _cur_mat: ShaderMaterial

var instanced_mode: bool = true

func _ready() -> void:
	_multi_mesh_instance = MultiMeshInstance3D.new()
	rotating_button.visible = _cur_layout == MeshLayout.CUBE
	add_child(_multi_mesh_instance)
	set_objects(int(amount_input.value))

func _process(delta: float) -> void:
	if _rotating:
		if instanced_mode:
			_multi_mesh_instance.rotate_y(delta * 0.25)
		else:
			for o in spawned_objects:
				o.rotate_y(delta * 0.25)
		
	age += delta
	if instanced_mode:
		_multi_mesh_instance.set_instance_shader_parameter("age", age)
	else:
		for o in spawned_objects:
			o.set_instance_shader_parameter("age", age)

func set_instanced_mode(instanced: bool) -> void:
	if instanced_mode and not instanced:
		_multi_mesh_instance.queue_free()
	
	elif not instanced_mode and instanced:
		for o in spawned_objects:
			o.queue_free()
		spawned_objects.clear()
		
		_multi_mesh_instance = MultiMeshInstance3D.new()
		add_child(_multi_mesh_instance)
	
	instanced_mode = instanced
	set_objects(int(amount_input.value))

func set_rotating(rotating: bool) -> void:
	_rotating = rotating
	if !rotating:
		if instanced_mode:
			_multi_mesh_instance.transform = Transform3D()
		else:
			for o in spawned_objects:
				o.transform = Transform3D()

func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled
	
func switch_to_shader(shader: ShaderMaterial) -> void:
	_cur_mat = shader 
	
	if instanced_mode:
		_multi_mesh_instance.material_override = shader
	else:
		for o in spawned_objects:
			o.set_surface_override_material(0, shader)
			o.set_instance_shader_parameter("seed", o.get_instance_id() * 0.1)

func set_layout(layout: int) -> void:
	_cur_layout = layout as MeshLayout
	
	var is_cube = _cur_layout == MeshLayout.CUBE
	rotating_button.visible = is_cube
	
	if !is_cube:
		set_rotating(false)
		rotating_button.button_pressed = false
		
	set_objects(_cur_amount)

func set_objects(amount: int) -> void:
	_cur_amount = amount

	if instanced_mode:
		set_multi_mesh(amount)
	else:
		set_non_instanced(amount)
		
	match _cur_layout:
		MeshLayout.SQUARE:
			camera.position = Vector3(amount*0.5, amount*0.5, 1.0 + amount*0.75)
		MeshLayout.CUBE:
			camera.position = Vector3(amount*0.5, amount*0.5, 1.0 + amount*1.75)
			
	switch_to_shader(_cur_mat)

func set_non_instanced(amount: int) -> void:
	for o in spawned_objects:
		o.queue_free()
	spawned_objects.clear()
	
	match _cur_layout:
		MeshLayout.SQUARE:
			_populate_square_ps(testing_multiple_template, amount)
		MeshLayout.CUBE:
			_populate_cube_ps(testing_multiple_template, amount)


func set_multi_mesh(amount: int) -> void:
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
			_populate_square_mm(multimesh, amount)
		MeshLayout.CUBE:
			_populate_cube_mm(multimesh, amount)
	
	_multi_mesh_instance.multimesh = multimesh

func _populate_square_ps(template: PackedScene, square_size: int):
	for x in range(square_size):
		for y in range(square_size):
				var inst = template.instantiate()
				inst.position = Vector3(x, y, 0.0)
				add_child(inst)
				spawned_objects.append(inst)

func _populate_square_mm(multi_mesh: MultiMesh, square_size: int):
	var i = 0
	for x in range(square_size):
		for y in range(square_size):
				var pos = Vector3(x, y, 0.0)
				multi_mesh.set_instance_transform(i, Transform3D(Basis(), pos))
				i += 1

func _populate_cube_ps(template: PackedScene, cube_size: int):
	for x in range(cube_size):
		for y in range(cube_size):
			for z in range(cube_size):
				var inst = template.instantiate()
				inst.position = Vector3(x, y, z)
				add_child(inst)
				spawned_objects.append(inst)

func _populate_cube_mm(multi_mesh: MultiMesh, cube_size: int):
	var i = 0
	for x in range(cube_size):
		for y in range(cube_size):
			for z in range(cube_size):
				var pos = Vector3(x, y, z)
				multi_mesh.set_instance_transform(i, Transform3D(Basis(), pos))
				i += 1
