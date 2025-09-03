extends MeshInstance3D

@onready var debug_label: Label3D = $DebugLabel
var age := 0.0
var aging_shader: AgingShader

func _ready():
	add_to_group("age_nodes")
	aging_shader = AgingShader.new(get_active_material(0))

func _process(delta: float) -> void:
	age += delta
	debug_label.text = "Age: %d" %age
	aging_shader.update(age)

func _exit_tree() -> void:
	aging_shader.cleanup()
