extends Node

# TESTING_MULTIPLE
@onready var testing_multiple_template: MeshInstance3D = $Testcube
var testing_multiple := false
var spawned_objects := []

# TEXARRAY
var displayed_textures := []

func _ready() -> void:
	EventBus.reset_ages.connect(reset_ages)
	EventBus.test_multiple.connect(test_multiple)
	EventBus.show_tex_array.connect(show_tex_array)

func reset_ages() -> void:
	for node in get_tree().get_nodes_in_group("age_nodes"):
			node.set("age", 0)

func test_multiple(args: Dictionary) -> void:
	testing_multiple = args["toggled"]
	var amount = args["amount"]
	var root := int(sqrt(amount))
	
	if testing_multiple:
		for i in range(amount):
			var inst = testing_multiple_template.duplicate()
			inst.position = inst.position + Vector3((i % root) * 2, 0.0, i / floor(root) * 2)
			add_child(inst)
			spawned_objects.append(inst)
	else:
		for inst in spawned_objects:
			if is_instance_valid(inst):
				inst.queue_free()
		spawned_objects.clear()
	
func show_tex_array(args: Dictionary) -> void:
	if args["toggled"]:
		var node := get_tree().get_nodes_in_group("age_nodes")[0]
		var arr: Texture2DArray = node.get_tex_array()
		
		for i in range(arr.get_layers()):
			var img: Image = arr.get_layer_data(i)
			var tex := ImageTexture.create_from_image(img)
			tex.set_size_override(Vector2i(128, 128))
			
			var rect := TextureRect.new()
			rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			rect.texture = tex
			rect.set_position(Vector2(tex.get_width()*i, 0.0))
			add_child(rect)
			displayed_textures.append(rect)
	else:
		for inst in displayed_textures:
			if is_instance_valid(inst):
				inst.queue_free()
		displayed_textures.clear()
