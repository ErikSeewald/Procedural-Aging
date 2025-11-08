extends Node

@onready var test_mesh: MeshInstance3D = $TestMesh
@onready var ui = $"Debug UI"
@onready var sub_menu: SubMenu = $SubMenu

# TESTING_MULTIPLE
@onready var testing_multiple_template: PackedScene = load(test_mesh.scene_file_path)
var testing_multiple := false
var spawned_objects := []

# SHOWING PROBES
var showing_probes := false
var probe_meshes: Dictionary[ContextProbe, Dictionary] = {} # probe -> {shape -> mesh_inst}

func _ready() -> void:
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		push_warning("This project is not designed for gl_compatibility rendering!
		You may see incorrect color values.")
	sub_menu.visibility_changed.connect(_on_sub_menu_visibility)

func _on_sub_menu_visibility() -> void:
	ui.visible = sub_menu.visible

## Resets the ages of all nodes in the 'age_nodes' group
func reset_ages(_args: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("age_nodes"):
			node.set("age", 0)

## Spawns multiple copies of the test mesh. The amount and whether
## the objects are to be spawned or despawned are defined by the args.
func test_multiple(args: Dictionary) -> void:
	testing_multiple = args["toggled"]
	if testing_multiple:
		var amount: int = args["amount"]
		var root := int(sqrt(amount))
		for i in range(1, amount):
			var inst = testing_multiple_template.instantiate()
			inst.position = inst.position + Vector3((i % root) * 2, 0.0, i / floor(root) * 2)
			add_child(inst)
			spawned_objects.append(inst)
	else:
		_clear_instances(spawned_objects)

## Toggles the display of the context probe collision shapes.
func show_probes(args: Dictionary) -> void:
	showing_probes = args["toggled"]
	for dict: Dictionary in probe_meshes.values():
		for m: MeshInstance3D in dict.values():
			m.visible = showing_probes

func _process(_delta: float) -> void:
	if showing_probes:
		_update_probe_display()

## Frees all instances in the given array and clears it.
func _clear_instances(instances: Array) -> void:
	for inst in instances:
		if is_instance_valid(inst):
			inst.queue_free()
	instances.clear()

## Renders the current state of the probe collisions.
## Does not deal with sudden changes to the shape class or 
## probes added during runtime.
func _update_probe_display() -> void:
	for p: ContextProbe in get_tree().get_nodes_in_group("context_probes"):
		if not probe_meshes.has(p):
			probe_meshes[p] = {}
		
		# Add untracked collision shapes
		for s in p.get_children():
			if s is CollisionShape3D and not probe_meshes[p].has(s):
				var m = MeshHelper.new_wireframe_mesh()
				MeshHelper.add_transparent_child_shape(m, s.shape)
				add_child(m)
				probe_meshes[p][s] = m
				
				
		# Update collision shape meshes
		for shape: CollisionShape3D in probe_meshes[p].keys():
			var mesh: MeshInstance3D = probe_meshes[p][shape]
			mesh.global_transform = shape.global_transform
			MeshHelper.match_wireframe_to_shape(mesh, shape.shape)
