extends Node

# TESTING_MULTIPLE
@onready var testing_multiple_template: MeshInstance3D = $Testcube
var testing_multiple := false
var spawned_objects := []

func _ready() -> void:
	EventBus.reset_ages.connect(reset_ages)
	EventBus.test_multiple.connect(test_multiple)

func reset_ages() -> void:
	for node in get_tree().get_nodes_in_group("age_nodes"):
			node.set("age", 0)

func test_multiple(args: Dictionary) -> void:
	testing_multiple = args["toggled"]
	var amount = args["amount"]
	var root = int(sqrt(amount))
	
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
