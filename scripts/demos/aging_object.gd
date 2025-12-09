extends MeshInstance3D
class_name AgingObject

@onready var context_sampler: ContextSampler
@onready var env_context := ContextParams.new()

func _ready():
	context_sampler = ContextSampler.new()
	context_sampler.context_changed.connect(_on_context_changed)
	add_child(context_sampler)

func _on_context_changed(new_context: ContextParams) -> void:
	env_context = new_context
	for param in env_context.get_param_names():
		set_instance_shader_parameter(param, env_context.get(param))
