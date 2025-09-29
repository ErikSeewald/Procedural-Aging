extends Node
class_name AgingGraphics

# DEBUG
var instanceColor: Color = RngHelper.random_color()

# LAYERS
var layers: Texture2DArrayRD
const layer_count: int = 2		# Needs to be >= 2
const layer_width: int = 256
const layer_height: int = 256

# COMPUTE SHADER
const compute_tile_size: int = 8
const groups_x: int = int(ceil(float(layer_width) / compute_tile_size))
const groups_y: int = int(ceil(float(layer_height) / compute_tile_size))
const groups_z: int = layer_count

var rd: RenderingDevice
var shader_rid: RID
var pipeline_rid: RID
var tex_rid: RID
var u_set_rid: RID
var push_bytes: PackedByteArray # For push constant compute params

# GDSHADER
var blend_material: ShaderMaterial

# DEBUG
@export var debuug: Array = [
1000.0,
3,
10,
20,
0.5,
0.7,
0.3,
0.05,
0.1]

func _init(blend: ShaderMaterial) -> void:
	rd = RenderingServer.get_rendering_device()
	_init_compute_shader()
	
	blend_material = blend
	blend_material.set_shader_parameter("weights", [1.0, 0.0])
	blend_material.set_shader_parameter("masks", layers)

func _init_compute_shader() -> void:
	shader_rid = _create_effects_shader()
	pipeline_rid = rd.compute_pipeline_create(shader_rid)
	tex_rid = rd.texture_create(_create_texture_format(), RDTextureView.new(), [])
	u_set_rid = _create_uniform_set()	
	push_bytes = _create_push_constants()

	layers = Texture2DArrayRD.new()
	layers.texture_rd_rid = tex_rid

func _create_effects_shader() -> RID:
	var effects_shader = load("res://shaders/effects.glsl")
	var spirv: RDShaderSPIRV = effects_shader.get_spirv()
	if !spirv.compile_error_compute.is_empty():
		print(spirv.compile_error_compute)
	return rd.shader_create_from_spirv(effects_shader.get_spirv())

func _create_texture_format() -> RDTextureFormat:
	var fmt := RDTextureFormat.new()
	fmt.texture_type = RenderingDevice.TEXTURE_TYPE_2D_ARRAY
	fmt.width = layer_width
	fmt.height = layer_height
	fmt.array_layers = layer_count
	fmt.mipmaps = 1
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	fmt.usage_bits |= RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	fmt.usage_bits |= RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT # For debug display
	return fmt
	
func _create_uniform_set() -> RID:
	var u_img := RDUniform.new()
	u_img.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_img.binding = 0
	u_img.add_id(tex_rid)
	return rd.uniform_set_create([u_img], shader_rid, 0)

func _create_push_constants() -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(64) # USED TO BE 32
	for i in 4:
		bytes.encode_float(i*4, instanceColor[i])

	return bytes

## Updates the aging shader with the given aging parameters.
## Dispatches a compute list for updating the aging effect textures.
func update(age: float, context: ContextParams) -> void:
	blend_material.set_shader_parameter("age", age)
	push_bytes.encode_float(16, age)
	push_bytes.encode_float(20, context.temperature)
	
	# DEBUG
	for i in 9:
		push_bytes.encode_float(24 + i*4, debuug[i])
	
	var cl = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipeline_rid)
	rd.compute_list_bind_uniform_set(cl, u_set_rid, 0)
	rd.compute_list_set_push_constant(cl, push_bytes, push_bytes.size())
	rd.compute_list_dispatch(cl, groups_x, groups_y, groups_z)
	rd.compute_list_end()

## Cleans up the memory reserved by the aging shader.
## Frees taken RIDs and disconnects textures from the blend material.
func cleanup():
	# Avoids use-after-free of tex_rid
	blend_material.set_shader_parameter("masks", null)
	for rid in [pipeline_rid, u_set_rid, tex_rid, shader_rid]:
		rd.free_rid(rid)
