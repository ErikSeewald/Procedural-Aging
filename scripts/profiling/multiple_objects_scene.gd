extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var ui: Panel = $UI
@onready var size_input: SpinBox = $UI/MarginContainer/VBoxContainer/Size

const material_slot := 0

var _cur_age = 0.0 # One shared age for all instances
var _aging_paused = false
var _cur_mat: ShaderMaterial
var _cur_size: int # Edge length/size of square/cube of instances

var _instance_mode: bool = true
var _baked_mode = false
var _bake_size: Vector2i

# NON INSTANCED
@onready var non_instanced_template: PackedScene = preload("res://scenes/profiling/base_sphere.tscn")
var spawned_objects = []

# INSTANCED
var _multi_mesh_instance: MultiMeshInstance3D

# LAYOUT
enum MeshLayout { SQUARE, CUBE, OVERDRAW}
var _cur_layout: MeshLayout = MeshLayout.SQUARE
 
func _ready() -> void:
	set_size(int(size_input.value))

func _process(delta: float) -> void:
	if not _aging_paused:
		_cur_age += delta
		_update_shader_age()

func _update_shader_age() -> void:
		_cur_mat.set_shader_parameter("age", _cur_age)
		if _instance_mode:
			_multi_mesh_instance.set_instance_shader_parameter("age", _cur_age)
		else:
			for o in spawned_objects:
				o.set_instance_shader_parameter("age", _cur_age)

## Called by profiling_main_scene
func pause_aging(toggled: bool) -> void:
	_aging_paused = toggled

## Called by profiling_main_scene
func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled

## Called by profiling_main_scene and for reinitializing shaders.
func switch_to_shader(mat: ShaderMaterial) -> void:	
	_baked_mode = false # This function is never called for the baked shader
	if not mat:
		return # Can happen if it is called during ready() tree
	
	_cur_mat = mat
	_update_shader_age()
	
	if _instance_mode:
		_multi_mesh_instance.material_override = _cur_mat
	else:
		for o in spawned_objects:
			o.set_surface_override_material(0, _cur_mat)
			o.set_instance_shader_parameter("seed", o.get_instance_id())

## Called by profiling_main_scene and for reinitializing shaders.
func bake_shader(mat: ShaderMaterial, size: Vector2i) -> void:
	_cur_mat = mat
	_bake_size = size
	_baked_mode = true
	_update_shader_age()
	
	if _instance_mode:
		AgeBaker.register(_multi_mesh_instance, _cur_mat, size, material_slot)
	else:
		for o in spawned_objects:
			var i_mat = _cur_mat.duplicate()
			i_mat.set_shader_parameter("seed", o.get_instance_id())
			AgeBaker.register(o, i_mat, size, material_slot)
	AgeBaker.bake()

func set_instance_mode(instanced: bool) -> void:
	_instance_mode = instanced
	set_objects(_cur_layout, _cur_size)

func set_layout(layout: int) -> void:
	_cur_layout = layout as MeshLayout	
	set_objects(_cur_layout, _cur_size)

func set_size(size: int) -> void:
	_cur_size = size
	set_objects(_cur_layout, _cur_size)

## Reinitializes the current multi-objects with the given layout and size.
func set_objects(layout: MeshLayout, size: int) -> void:
	var positions := _get_positions(layout, _cur_size)
	if _instance_mode:
		_clear_non_instanced()
		set_multi_mesh(positions)
	else:
		if _multi_mesh_instance:
			_multi_mesh_instance.queue_free()
		set_non_instanced(positions)
	
	# Moving the camera this way roughly keeps the meshes centered
	match _cur_layout:
		MeshLayout.SQUARE:
			camera.position = Vector3(size*0.5, size*0.5, 1.0 + size*0.75)
		MeshLayout.CUBE:
			camera.position = Vector3(size*0.5, size*0.5, 1.0 + size*1.75)
		MeshLayout.OVERDRAW:
			camera.position = Vector3(0.0, 0.0, 1.0)
	
 	# Shaders need to be reinitialized too
	if _baked_mode:
		bake_shader(_cur_mat, _bake_size)
	else:
		switch_to_shader(_cur_mat)

## Creates a MultiMeshInstance with instances at the given positions, 
## sets _multi_mesh_instances to reference it and adds it as a child.
func set_multi_mesh(positions: Array[Vector3]) -> void:
	if not _multi_mesh_instance:
		_multi_mesh_instance = MultiMeshInstance3D.new()
		add_child(_multi_mesh_instance)
	
	var multi_mesh := MultiMesh.new()
	multi_mesh.mesh = SphereMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = len(positions)
	
	var i = 0
	for pos in positions:
		multi_mesh.set_instance_transform(i, Transform3D(Basis(), pos))
		i += 1

	_multi_mesh_instance.multimesh = multi_mesh

## Removes the old set of spawned objects and spawns new template instances
## at the given positions.
func set_non_instanced(positions: Array[Vector3]) -> void:
	_clear_non_instanced()
	for pos in positions:
		var inst = non_instanced_template.instantiate()
		inst.position = pos
		add_child(inst)
		spawned_objects.append(inst)

func _clear_non_instanced() -> void:
	for o in spawned_objects:
		o.queue_free()
	spawned_objects.clear()

## Returns an array of positions, one for each instance required by "size"
## in the given layout.
func _get_positions(layout: MeshLayout, size: int) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	if layout == MeshLayout.OVERDRAW:
		for i in range(size):
			positions.append(Vector3(0.0, 0.0, -i * 0.5))
		return positions
	
	var size_z: int = size if layout == MeshLayout.CUBE else 1
	for x in range(size):
		for y in range(size):
			for z in range(size_z):
				positions.append(Vector3(x, y, z))
				
	return positions
