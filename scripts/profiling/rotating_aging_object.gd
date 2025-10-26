extends MeshInstance3D

@onready var mat: ShaderMaterial = get_active_material(0)
var age = 0.0

func _process(delta: float) -> void:
	age += delta
	mat = get_active_material(0) # Need to get it each time since it may change
	mat.set_shader_parameter("age", age)
	
	if mesh is QuadMesh:
		rotate_z(delta * 0.25)
	else:
		rotate_y(delta * 0.25)
