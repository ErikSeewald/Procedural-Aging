extends MeshInstance3D

@onready var mat := get_active_material(0) as ShaderMaterial
@onready var debug_label: Label3D = $DebugLabel

var age := 0.0

func _ready():
	add_to_group("age_nodes")

func _process(delta: float) -> void:
	age += delta
	mat.set_shader_parameter("age", age)
	
	debug_label.text = "Age: %d" %age
