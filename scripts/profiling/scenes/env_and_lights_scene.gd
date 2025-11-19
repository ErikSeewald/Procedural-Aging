extends ProfilingScene

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var env: Environment = $WorldEnvironment.environment

const max_lights := 8 # Forward+ directional light limit for a single mesh
const light_radius := 5.0
var _cur_lights := []
var _light_count := 0

var _enable_env_effects := false

var _rotating := true

const profiling_ids: Array[String] = [
	"lights_0", "lights_1", "lights_8",
	"env_effects_on"
]

func get_profiling_ids() -> Array[String]:
	return profiling_ids

func _setup_existing_id(profiling_id: String) -> void:
	print("SETUP " + profiling_id)
	if profiling_id.contains("lights"):
		_light_count = int(profiling_id.split("_")[-1])
	if profiling_id == "env_effects_on":
		_enable_env_effects = true

func _ready() -> void:
	super()
	set_random_light_count(_light_count)
	
	if _enable_env_effects:
		env.ssr_enabled = true
		env.ssao_enabled = true
		env.ssil_enabled = true
		env.fog_enabled = true

func _process(delta: float) -> void:
	super(delta)
	mesh_instance.set_instance_shader_parameter("age", _cur_age)
	
	if _rotating:
		mesh_instance.rotate_y(delta * 0.25)
	
func switch_to_shader(mat: ShaderMaterial) -> void:
	super(mat)
	mesh_instance.set_surface_override_material(material_slot, _cur_mat)

func bake_shader(mat: ShaderMaterial, size: Vector2i) -> void:
	super(mat, size)
	AgeBaker.register(mesh_instance, _cur_mat, _cur_bake_size, material_slot)
	AgeBaker.bake()

func set_rotating(rotating: bool) -> void:
	_rotating = rotating

func regenerate_lights() -> void:
	var cur_count = len(_cur_lights)
	for l in _cur_lights:
		l.queue_free()
	_cur_lights.clear()
	
	set_random_light_count(cur_count)

## Sets the random light count and generates all missing lights
## or removes them if there are too many.
func set_random_light_count(count: int) -> void:
	var cur_count = len(_cur_lights)
	if cur_count == count:
		return
	
	count = min(max_lights, count)
	if count <= cur_count:
		for i in range(cur_count - 1, count - 1, -1):
			_cur_lights[i].queue_free()
			_cur_lights.remove_at(i)
	else:
		for i in range(count - cur_count):
			var light = _generate_random_light(light_radius)
			add_child(light)
			_cur_lights.append(light)

## Generates a directional right at a random position in the given radius
## on the positive side of the Z axis, a random direction pointing generally
## toward the negative side of the Z axis, and a random color.
func _generate_random_light(radius: float) -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	
	var dir := Vector3(
		randf_range(-radius, radius),
		randf_range(-radius, radius),
		-1.0
	).normalized()
	var pos := Vector3(
		randf_range(-radius, radius),
		randf_range(-radius, radius),
		randf_range(2.0, radius) # Always behind the camera
	)
	light.transform = Transform3D(Basis.looking_at(dir, Vector3.UP), pos)

	light.light_color = Color.from_hsv(randf(), 1.0, 1.0)
	return light
