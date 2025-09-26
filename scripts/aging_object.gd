extends MeshInstance3D

@onready var debug_label: Label3D = $DebugLabel
@onready var context_sampler: ContextSampler = $ContextSampler
@onready var cur_context := ContextParams.new()
@export var age := 0.0
var aging_graphics: AgingGraphics

func _ready():
	add_to_group("age_nodes")
	aging_graphics = AgingGraphics.new(get_active_material(0))
	add_child(aging_graphics)
	context_sampler.context_changed.connect(_update_context)

func _process(delta: float) -> void:
	if age <= 30.0:
		age += delta
	debug_label.text = "Age: %d \nTemp: %d" %[age, cur_context.temperature]
	aging_graphics.update(age, cur_context)

func _exit_tree() -> void:
	aging_graphics.cleanup()
	
func _update_context(new_context: ContextParams) -> void:
	cur_context = new_context
