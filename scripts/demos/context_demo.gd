extends Node3D

@onready var ui: Panel = $UI
@onready var age_input: HSlider = $UI/MarginContainer/VBoxContainer/AgeSlider
@onready var seed_input: SpinBox = $UI/MarginContainer/VBoxContainer/SeedInput
@onready var sub_menu: SubMenu = $SubMenu
@onready var instance_count_input = $UI/MarginContainer/VBoxContainer/InstancesInput

var _instances: Array[MeshInstance3D] = []

@onready var mesh_helper: MeshHelper = MeshHelper.new()
var _probe_meshes: Dictionary[ContextProbe, Dictionary] = {} # probe -> {shape -> mesh_inst}
var _showing_probes: bool = true

func _ready() -> void:
	ui.visible = false
	sub_menu.visibility_changed.connect(_on_sub_menu_visibility)
	set_instance_count(instance_count_input.value)

func _on_sub_menu_visibility() -> void:
	ui.visible = sub_menu.visible

func set_age(age: float) -> void:
	for inst in _instances:
		inst.set_instance_shader_parameter("age", age)
		
func randomize_age() -> void:
	for inst in _instances:
		inst.set_instance_shader_parameter("age", randf_range(0.0,  100.0))
		
func set_seed(s: int) -> void:
	for inst in _instances:
		inst.set_instance_shader_parameter("seed", s)
		
func randomize_seed() -> void:
	for inst in _instances:
		inst.set_instance_shader_parameter("seed", randi())

func set_instance_count(count: int) -> void:
	for inst in _instances:
		inst.queue_free()
	_instances.clear()
	
	var root := int(sqrt(count))
	for i in range(count):
		var inst: MeshInstance3D = $BaseInstance.duplicate()
		inst.position = inst.position + Vector3(-(i % root) * 1.5, 0.0, -i / floor(root) * 1.5)
		inst.visible = true
		add_child(inst)
		_instances.append(inst)
		
	set_age(age_input.value)
	set_seed(int(seed_input.value))
	

func _process(_delta: float) -> void:
	if _showing_probes:
		_update_probe_display()

func show_probes(toggled: bool) -> void:
	_showing_probes = toggled
	for dict: Dictionary in _probe_meshes.values():
		for m: MeshInstance3D in dict.values():
			m.visible = _showing_probes

## Renders the current state of the probe collisions.
## Does not deal with sudden changes to the shape class or 
## probes added during runtime.
func _update_probe_display() -> void:
	for p: ContextProbe in get_tree().get_nodes_in_group("context_probes"):
		if not _probe_meshes.has(p):
			_probe_meshes[p] = {}
		
		# Add untracked collision shapes
		for s in p.get_children():
			if s is CollisionShape3D and not _probe_meshes[p].has(s):
				var m = mesh_helper.new_wireframe_mesh()
				mesh_helper.add_transparent_child_shape(m, s.shape)
				add_child(m)
				_probe_meshes[p][s] = m
				
				
		# Update collision shape meshes
		for shape: CollisionShape3D in _probe_meshes[p].keys():
			var mesh: MeshInstance3D = _probe_meshes[p][shape]
			mesh.global_transform = shape.global_transform
			mesh_helper.match_wireframe_to_shape(mesh, shape.shape)
