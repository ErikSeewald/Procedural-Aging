extends ProfilingScene

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var _cur_id := "others_default"
var _values_set := false

const profiling_ids: Array[String] = [
	"others_default", "others_half", "others_twice", "others_10x",
	"instance_default", "instance_half", "instance_twice", "instance_10x",
	"age_0", "age_50", "age_100", "age_200", "age_500",
	"vertex_colors_on", "vertex_colors_off",
	"paint_layer_on", "paint_layer_off",
	"pit_fbm8", "pit_fbm7", "pit_fbm6", "pit_fbm5", "pit_fbm4", "pit_fbm3", "pit_fbm2", "pit_fbm1",
	"detail_fbm8", "detail_fbm7", "detail_fbm6", "detail_fbm5", "detail_fbm4", "detail_fbm3", "detail_fbm2", "detail_fbm1"
]

const other_params_names: Array[String] = [
	"mask_scale", "wear_scale", "pit_scale", "detail_scale", "time_scale", 
	"uniform_corrosion_speed", "exposure", "paint_edge_sharpness", "paint_yellowing_intensity",
	"grime_intensity", "grime_falloff", "rust_growth_factor", "rust_red_shift", "rust_green_shift"
]

const instance_params_names: Array[String] = [
	"seed", "paint_stability", "uv_and_heat", "pollution", "moisture"
]

func get_profiling_ids() -> Array[String]:
	return profiling_ids

func _setup_existing_id(profiling_id: String) -> void:
	print("SETUP " + profiling_id)
	_cur_id = profiling_id
	
func _ready() -> void:
	super()
	mesh_instance.set_instance_shader_parameter("age", 50.0)

func _process(delta: float) -> void:
	super(delta)
	if _cur_mat and not _values_set:
		_set_params()

## Sets the parameters once according to the current profiling id.
func _set_params() -> void:
	_values_set = true
	if "others" in _cur_id:
		for p in other_params_names:
			var v = _cur_mat.get_shader_parameter(p)
			var new_v = v
			match _cur_id:
				"others_half": new_v *= 0.5
				"others_twice": new_v *= 2.0
				"others_10x": new_v *= 10.0
			
			if v <= 1.0:
				new_v = min(new_v, 1.0)
				
			_cur_mat.set_shader_parameter(p, new_v)
			
	elif "instance" in _cur_id:
		for p in instance_params_names:
			var v = mesh_instance.get_instance_shader_parameter(p)
			var new_v = v
			match _cur_id:
				"instance_half": new_v *= 0.5
				"instance_twice": new_v *= 2.0
				"instance_10x": new_v *= 10.0
			
			if v <= 1.0:
				new_v = min(new_v, 1.0)
				
			mesh_instance.set_instance_shader_parameter(p, new_v)
			
	elif "age" in _cur_id:
		mesh_instance.set_instance_shader_parameter("age", float(_cur_id.split("_")[1]))
		
	elif "vertex_colors" in _cur_id:
		_cur_mat.set_shader_parameter("use_vertex_weight", "on" in _cur_id)
	
	elif "paint_layer" in _cur_id:
		_cur_mat.set_shader_parameter("use_paint_layer", "on" in _cur_id)
	
	elif "fbm" in _cur_id:
		var v = int(_cur_id.split("fbm")[1])
		var type = _cur_id.split("_")[0]
		_cur_mat.set_shader_parameter(type + "_fbm_iterations", v)


# Does not really make sense to change the shader to anything else but
# allow the option for compatibility.
func switch_to_shader(mat: ShaderMaterial) -> void:
	super(mat)
	mesh_instance.set_surface_override_material(material_slot, _cur_mat)

func bake_shader(_mat: ShaderMaterial, _size: Vector2i) -> void:
	pass # Keep this here just so super() is not automatically called
