@tool
extends MeshInstance3D

@onready var debug_label: Label3D = $DebugLabel
@onready var context_sampler: ContextSampler = $ContextSampler
@onready var cur_context := ContextParams.new()
@export var age = 0.0
var aging_graphics: AgingGraphics

func _enter_tree() -> void:
	pass

@export var pA = 1000.0;
@export var p1 = 1;
@export var p2 = 10;
@export var p3 = 20;
@export var pb1 = 0.5;
@export var pb2 = 0.7;
@export var pS = 0.3;
@export var pT = 0.05;
@export var pT2 = 0.1;

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
	aging_graphics.debuug = [pA, p1, p2, p3, pb1, pb2, pS, pT, pT2]    

func _exit_tree() -> void:
	aging_graphics.cleanup()
	
func _update_context(new_context: ContextParams) -> void:
	cur_context = new_context
