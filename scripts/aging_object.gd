extends MeshInstance3D

@onready var debug_label: Label3D = $DebugLabel

var age := 0.0
var context_sampler: ContextSampler
@onready var cur_context := ContextParams.new()
var aging_graphics: AgingGraphics

func _ready():
	add_to_group("age_nodes")
	
	aging_graphics = AgingGraphics.new(get_active_material(0))
	add_child(aging_graphics)
	
	context_sampler = ContextSampler.new()
	context_sampler.connect(ContextSampler.params_changed_signal, _update_context)
	add_child(context_sampler)
	

func _process(delta: float) -> void:
	age += delta
	debug_label.text = "Age: %d \nTemp: %d" %[age, cur_context.temperature]
	aging_graphics.update(age, cur_context)

func _exit_tree() -> void:
	aging_graphics.cleanup()
	
func _update_context(new_context: ContextParams) -> void:
	cur_context = new_context
