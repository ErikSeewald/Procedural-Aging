extends MeshInstance3D
class_name AgingObject

@onready var context_sampler: ContextSampler
@onready var cur_context := ContextParams.new()

@export var material_slot := 0

func _ready():
	add_to_group("age_nodes")
	
	context_sampler = ContextSampler.new()
	context_sampler.context_changed.connect(_set_context)
	add_child(context_sampler)

func _set_context(new_context: ContextParams) -> void:
	if cur_context.changed.is_connected(_on_context_changed):
			cur_context.changed.disconnect(_on_context_changed)	
	
	new_context.changed.connect(_on_context_changed)
	cur_context = new_context
	
	_on_context_changed()

func _on_context_changed() -> void:
	for param in cur_context.get_param_names():
		set_instance_shader_parameter(param, cur_context.get(param))
