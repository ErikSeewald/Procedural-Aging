extends MeshInstance3D

# AGE
@onready var mat := get_active_material(0) as ShaderMaterial
@onready var debug_label: Label3D = $DebugLabel
var age := 0.0

# TexArray
var masks: Texture2DArray


func _ready():
	add_to_group("age_nodes")
	
	var voronoi: Shader = preload("res://Shaders/voronoi.gdshader")
	
	var mat1 := ShaderMaterial.new()
	mat1.shader = voronoi
	mat1.set_shader_parameter("scale", 25.0)
	
	var mat2 := ShaderMaterial.new()
	mat2.shader = voronoi
	
	var mat3 := ShaderMaterial.new()
	mat3.shader = voronoi
	mat3.set_shader_parameter("scale", 2.0)
	mat3.set_shader_parameter("color_cells", true)

	masks = await TexArray.from_materials([mat1, mat2, mat3], 256, 256)
	mat.set_shader_parameter("weight", [-0.5, 0.7, -0.1])
	mat.set_shader_parameter("mask_count", masks.get_layers())
	mat.set_shader_parameter("masks", masks)

func _process(delta: float) -> void:
	age += delta
	mat.set_shader_parameter("age", age)
	
	debug_label.text = "Age: %d" %age

func get_tex_array() -> Texture2DArray:
	return masks
