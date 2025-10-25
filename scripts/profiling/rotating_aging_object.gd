extends MeshInstance3D

@onready var mat: ShaderMaterial = get_active_material(0)
var age = 0.0

func _ready() -> void:
	mat.set_shader_parameter("time_scale", 0.02)

func _process(delta: float) -> void:
	age += delta
	mat.set_shader_parameter("age", age)
	
	if mesh is QuadMesh:
		rotate_z(delta * 0.25)
	else:
		rotate_y(delta * 0.25)
