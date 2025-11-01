extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var ui: Panel = $UI

const material_slot := 0

const max_lights := 8 # Forward+ directional light limit for a single mesh
const light_radius := 5.0
var _cur_lights := []

var _rotating := true
var _cur_age := 0.0
var _aging_paused := false

func _ready() -> void:
	ui.visible = false

func _process(delta: float) -> void:
	if not _aging_paused:
		_cur_age += delta
		mesh_instance.set_instance_shader_parameter("age", _cur_age)
	if _rotating:
		mesh_instance.rotate_y(delta * 0.25)

func pause_aging(toggled: bool) -> void:
	_aging_paused = toggled

func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled
	
func switch_to_shader(shader: ShaderMaterial) -> void:
	mesh_instance.set_surface_override_material(material_slot, shader)

func bake_shader(mat: ShaderMaterial, size: Vector2i) -> void:
	mat.set_shader_parameter("age", _cur_age)
	AgeBaker.register(mesh_instance, mat, size, material_slot)
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
