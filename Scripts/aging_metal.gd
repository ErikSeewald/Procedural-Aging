extends MeshInstance3D

# AGE
@onready var mat := get_active_material(0) as ShaderMaterial
@onready var debug_label: Label3D = $DebugLabel
var age := 0.0



func _ready():
	add_to_group("age_nodes")

	var tex_array = await TextureBaker.bake_from_textures(["res://Textures/rust_layers.jpg", "res://Textures/spot_layers.jpg"])
	mat.set_shader_parameter("mask_count", tex_array.get_layers())
	mat.set_shader_parameter("masks", tex_array)

func _process(delta: float) -> void:
	age += delta
	mat.set_shader_parameter("age", age)
	
	debug_label.text = "Age: %d" %age
