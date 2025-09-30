@tool
extends MeshInstance3D

@onready var debug_label: Label3D = $DebugLabel
@onready var context_sampler: ContextSampler = $ContextSampler
@onready var cur_context := ContextParams.new()
@export var age = 0.0
var aging_graphics: AgingGraphics

@export var cell_size_1 = 8;
@export var cell_size_2  = 4;
@export var cell_size_3  = 256;
@export var cell_weight_1 = 0.6;
@export var cell_weight_2 = 0.9;
@export var cell_weight_3 = 0.6;
@export var time_scale = 0.1;

func _ready():
	age = 0.0
	add_to_group("age_nodes")
	aging_graphics = AgingGraphics.new(get_active_material(0))
	add_child(aging_graphics)
	context_sampler.context_changed.connect(_update_context)

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		age += delta
	debug_label.text = "Age: %d \nTemp: %d" %[age, cur_context.temperature]
	aging_graphics.update(age, cur_context)
	aging_graphics.debuug = [cell_size_1, cell_size_2, cell_size_3, cell_weight_1, cell_weight_2, cell_weight_3, time_scale]    

func _exit_tree() -> void:
	aging_graphics.cleanup()
	
func _update_context(new_context: ContextParams) -> void:
	cur_context = new_context
