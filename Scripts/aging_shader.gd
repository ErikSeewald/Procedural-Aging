extends Node
class_name AgingShader

var layers: Texture2DArrayRD
const layer_count: int = 3

var rd: RenderingDevice = RenderingServer.get_rendering_device()
var shader_rid: RID
var pipeline_rid: RID
var tex_rid: RID
var u_set: RID
var param_buf: RID
var width := 256
var height := 256
var groups_x := 0
var groups_y := 0
var groups_z := 0

var blend_material: ShaderMaterial

var instanceColor: Color

func _init(blend: ShaderMaterial) -> void:
	blend_material = blend
	blend_material.set_shader_parameter("weight", [-0.5, 0.7, -0.1])
	blend_material.set_shader_parameter("mask_count", layer_count)
	
	_init_compute_shader()
	blend_material.set_shader_parameter("masks", layers)

func _init_compute_shader() -> void:
	shader_rid = _build_effects_shader()
	pipeline_rid = rd.compute_pipeline_create(shader_rid)
	
	# Texture2DArray entirely on GPU
	var fmt := RDTextureFormat.new()
	fmt.width = width
	fmt.height = height
	fmt.array_layers = layer_count
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
	param_bytes.resize(32)
	param_bytes.encode_float(16, 1.0)
	
	# Random color
	var rng := RandomNumberGenerator.new()
	rng.seed = get_instance_id()
	rng.randomize()
	var hue := rng.randf()
	var sat := rng.randf_range(0.7, 1.0)
	var val := rng.randf_range(0.8, 1.0)
	instanceColor = Color.from_hsv(hue, sat, val, 1.0)
	
	var u_params := RDUniform.new()
	u_params.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u_params.binding = 1
	param_buf = rd.uniform_buffer_create(param_bytes.size(), param_bytes)
	u_params.add_id(param_buf)
	u_set = rd.uniform_set_create([u_img, u_params], shader_rid, 0)
	
	groups_x = int(ceil(float(width) / 8.0))
	groups_y = int(ceil(float(height) / 8.0))
	groups_z = layer_count

	layers = Texture2DArrayRD.new()
	layers.texture_rd_rid = tex_rid

func _build_effects_shader() -> RID:
	var effects_shader = load("res://Shaders/effects.glsl")
	var spirv: RDShaderSPIRV = effects_shader.get_spirv()
	if !spirv.compile_error_compute.is_empty():
		print(spirv.compile_error_compute)
		
	return rd.shader_create_from_spirv(effects_shader.get_spirv())

func update(age: float) -> void:
	blend_material.set_shader_parameter("age", age)
	
	var param_bytes := PackedByteArray()
	param_bytes.resize(32)
	param_bytes.encode_float(0, instanceColor.r)
	param_bytes.encode_float(4, instanceColor.g)
	param_bytes.encode_float(8, instanceColor.b)
	param_bytes.encode_float(12, instanceColor.a)
	param_bytes.encode_float(16, age)
	rd.buffer_update(param_buf, 0, param_bytes.size(), param_bytes)
	
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline_rid)
	rd.compute_list_bind_uniform_set(compute_list, u_set, 0)
	rd.compute_list_dispatch(compute_list, groups_x, groups_y, groups_z)
	rd.compute_list_end()

func cleanup():
	ComputeCleaner.defer_free([tex_rid, shader_rid, param_buf])
