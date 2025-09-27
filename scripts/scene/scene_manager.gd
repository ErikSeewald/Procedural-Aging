extends Node

@onready var test_mesh = $TestMesh

# SCENES
const scenes: Array = ["res://scenes/shader_testing.tscn", "res://scenes/docks.tscn"]
var scene_index = 0

# TESTING_MULTIPLE
@onready var testing_multiple_template: PackedScene = load(test_mesh.scene_file_path)
var testing_multiple := false
var spawned_objects := []

# SHOWING TEXARRAY
@onready var tex_array: Texture2DArrayRD = test_mesh.aging_graphics.layers
var showing_tex_array := false
var _tex_rects: Array[TextureRect] = []
var _layer_textures: Array[ImageTexture] = []

# SHOWING PROBES
var showing_probes := false
var probe_meshes: Dictionary[ContextProbe, MeshInstance3D] = {}

## Resets the ages of all nodes in the 'age_nodes' group
func reset_ages(_args: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("age_nodes"):
			node.set("age", 0)
	
## Loads and switches to the next scene
func switch_scene(_args: Dictionary) -> void:
	scene_index = (scene_index+1) % len(scenes)
	get_tree().change_scene_to_file(scenes[scene_index])

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

## Toggles the display of the tesh mesh tex array.
## If toggled, the display will pull the current state tex array
## every frame and display it.
func show_tex_array(args: Dictionary) -> void:
	showing_tex_array = args["toggled"]
	for t in _tex_rects:
		t.visible = showing_tex_array

## Toggles the display of the context probe collision shapes.
func show_probes(args: Dictionary) -> void:
	showing_probes = args["toggled"]
	for m: MeshInstance3D in probe_meshes.values():
		m.visible = showing_probes

func _process(_delta: float) -> void:
	if showing_tex_array:
		_update_tex_array_display()
	if showing_probes:
		_update_probe_display()

## Frees all instances in the given array and clears it.
func _clear_instances(instances: Array) -> void:
	for inst in instances:
		if is_instance_valid(inst):
			inst.queue_free()
	instances.clear()

func _update_tex_array_display() -> void:
	var layer_count := tex_array.get_layers()
	_adjust_texture_pool(layer_count)
	
	for i in layer_count:
		var rect := _tex_rects[i]
		var img: Image = tex_array.get_layer_data(i)
		
		var tex := _layer_textures[i]
		if tex == null:
			tex = ImageTexture.create_from_image(img)
			_layer_textures[i] = tex
		else:
			tex.update(img)
		
		rect.texture = tex
		rect.position = Vector2(rect.size.x * rect.scale.x * i, 0)

func _adjust_texture_pool(target_size) -> void:
	# Grow
	while _tex_rects.size() < target_size:
		var rect := TextureRect.new()
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		#rect.scale = Vector2(0.35, 0.35)
		add_child(rect)
		_tex_rects.append(rect)
		_layer_textures.append(null)
	
	# Shrink
	while _tex_rects.size() > target_size:
		var rect = _tex_rects.pop_back()
		rect.queue_free()
		_layer_textures.pop_back()
		

## Renders the current state of the probe collisions.
## Does not deal with sudden changes to the shape class or 
## probes added during runtime.
func _update_probe_display() -> void:
	for p: ContextProbe in get_tree().get_nodes_in_group("context_probes"):
		var mesh_inst: MeshInstance3D
		if not probe_meshes.has(p):
			mesh_inst = MeshHelper.new_wireframe_mesh()
			MeshHelper.add_transparent_child_shape(mesh_inst, p.collision_shape.shape)
			add_child(mesh_inst)
			probe_meshes[p] = mesh_inst
		else:
			mesh_inst = probe_meshes[p]

		mesh_inst.global_transform = p.collision_shape.global_transform
		MeshHelper.match_wireframe_to_shape(mesh_inst, p.collision_shape.shape)
