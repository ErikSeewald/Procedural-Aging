extends Node

@onready var test_mesh = $TestMesh

# SCENES
const scenes: Array = ["res://Scenes/shader_testing.tscn", "res://Scenes/docks.tscn"]
var scene_index = 0

# TESTING_MULTIPLE
@onready var testing_multiple_template: PackedScene = load(test_mesh.scene_file_path)
var testing_multiple := false
var spawned_objects := []

# SHOWING TEXARRAY
@onready var tex_array: Texture2DArrayRD = test_mesh.aging_graphics.layers
var showing_tex_array := false
var displayed_textures := []

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
	if args["toggled"]:
		showing_tex_array = true
		_update_tex_array_display()
	else:
		showing_tex_array = false
		_clear_instances(displayed_textures)


func _process(_delta: float) -> void:
	if showing_tex_array:
		_update_tex_array_display()

## Frees all instances in the given array and clears it.
func _clear_instances(instances: Array) -> void:
	for inst in instances:
		if is_instance_valid(inst):
			inst.queue_free()
	instances.clear()

func _update_tex_array_display() -> void:
	_clear_instances(displayed_textures)
	for i in tex_array.get_layers():
		var img: Image = tex_array.get_layer_data(i)
		var tex := ImageTexture.create_from_image(img)
		tex.set_size_override(Vector2i(128, 128))
		
		var rect := TextureRect.new()
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.texture = tex
		rect.set_position(Vector2(tex.get_width()*i, 0.0))
		add_child(rect)
		displayed_textures.append(rect)
