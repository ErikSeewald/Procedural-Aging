extends MeshInstance3D
class_name AgingObject

@onready var debug_label: Label3D = $DebugLabel
@onready var context_sampler: ContextSampler
@onready var cur_context := ContextParams.new()
@onready var mat: ShaderMaterial = get_active_material(0)
var age = 0.0

func _ready():
	add_to_group("age_nodes")
	age = 0.0
	
	# Maybe stop creating it via script and let it be set by users eventually
	# so they can edit the probe mask.
	context_sampler = ContextSampler.new()
	context_sampler.context_changed.connect(_update_context)
	add_child(context_sampler)

	var is_compat: bool = ProjectSettings.get_setting(
	"rendering/renderer/rendering_method") == "gl_compatibility"
	mat.set_shader_parameter("compat_mode", is_compat)
	mat.set_shader_parameter("seed", get_instance_id())

func _process(delta: float) -> void:
	age += delta
	if debug_label:
		debug_label.text = "Age: %d" %[age]
		
	mat.set_shader_parameter("age", age)
	for param in cur_context.get_param_names():
		mat.set_shader_parameter(param, cur_context.get(param))
	
	
func _update_context(new_context: ContextParams) -> void:
	cur_context = new_context
