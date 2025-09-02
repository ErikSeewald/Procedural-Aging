extends MeshInstance3D

# AGE
@onready var mat := get_active_material(0) as ShaderMaterial
@onready var debug_label: Label3D = $DebugLabel
var age := 0.0

# TexArray
var masks: Texture2DArrayRD
const mask_layers: int = 3
var tex_shader: RDShaderFile

var rd: RenderingDevice
var shader_rid: RID
var pipeline_rid: RID
var tex_rid: RID
var u_set: RID
var width := 256
var height := 256
var groups_x := 0
var groups_y := 0
var groups_z := 0

var param_buf: RID

func _ready():
	add_to_group("age_nodes")
	_init_compute()
	
	mat.set_shader_parameter("weight", [-0.5, 0.7, -0.1])
	mat.set_shader_parameter("mask_count", mask_layers)

func _init_compute() -> void:
	rd = RenderingServer.get_rendering_device()
	tex_shader = load("res://Shaders/tex_array.glsl")
	
	var spirv: RDShaderSPIRV = tex_shader.get_spirv()
	if !spirv.compile_error_compute.is_empty():
		print(spirv.compile_error_compute)
		
	shader_rid = rd.shader_create_from_spirv(tex_shader.get_spirv())
	pipeline_rid = rd.compute_pipeline_create(shader_rid)
	
	# Texture2DArray entirely on GPU
	var fmt := RDTextureFormat.new()
	fmt.width = width
	fmt.height = height
	fmt.array_layers = mask_layers
	fmt.texture_type = RenderingDevice.TEXTURE_TYPE_2D_ARRAY
	fmt.mipmaps = 1
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
		
	tex_rid = rd.texture_create(fmt, RDTextureView.new(), [])
		
	# Create uniforms
	var u_img := RDUniform.new()
	u_img.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_img.binding = 0
	u_img.add_id(tex_rid)
	
	var param_bytes := PackedByteArray()
	param_bytes.resize(16)
	param_bytes.encode_float(0, 1.0)
	
	var u_params := RDUniform.new()
	u_params.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u_params.binding = 1
	param_buf = rd.uniform_buffer_create(param_bytes.size(), param_bytes)
	u_params.add_id(param_buf)
	
	u_set = rd.uniform_set_create([u_img, u_params], shader_rid, 0)
	
	groups_x = int(ceil(float(width) / 8.0))
	groups_y = int(ceil(float(height) / 8.0))
	groups_z = mask_layers

	masks = Texture2DArrayRD.new()
	masks.texture_rd_rid = tex_rid
	mat.set_shader_parameter("masks", masks)

func _update_compute() -> void:
	var param_bytes := PackedByteArray()
	param_bytes.resize(16)
	param_bytes.encode_float(0, age)
	rd.buffer_update(param_buf, 0, param_bytes.size(), param_bytes)
	
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline_rid)
	rd.compute_list_bind_uniform_set(compute_list, u_set, 0)
	rd.compute_list_dispatch(compute_list, groups_x, groups_y, groups_z)
	rd.compute_list_end()

func _process(delta: float) -> void:
	age += delta
	mat.set_shader_parameter("age", age)
	
	debug_label.text = "Age: %d" %age
	
	_update_compute()

func get_tex_array() -> Texture2DArrayRD:
	return masks
