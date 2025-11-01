## This autoload allows baking the results of the pma shader into static textures in memory.
extends Node3D

## albedo; metallic, roughness, specular; normal map
const bake_targets = {"albedo": 0, "mrs": 1, "normal": 2}

## Dataclass for storing information about an entry that has registered for baking.
## Results will also be written into this class.
class RegisteredEntry:
	func _init(inst: GeometryInstance3D, mat: ShaderMaterial, si: Vector2i, sl: int) -> void:
		geom_instance = inst
		material = mat
		size = si
		slot = sl
		baked_images = []
	
	var geom_instance: GeometryInstance3D
	var material: ShaderMaterial # The material to bake, not the one that displays the baked result
	var size: Vector2i # Results will be rendered at this size
	var slot: int # The slot into which the baked result material will be written
	var baked_images: Array[Image] # Filled during bake loop and later written to the result material
	
var _registered: Array[RegisteredEntry] = []

## This is the shader that is used to actually display the outputs.
## A default shader is not used here because of the way the mrs texture is handled.
const result_shader = preload("res://shaders/baking/baked.gdshader")
var _result_material: ShaderMaterial

func _ready() -> void:
	_result_material = ShaderMaterial.new()
	_result_material.shader = result_shader
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("bake"):
		bake()

## Allows registering the given geometry instance for batched baking. (started through bake()).
## The results will be rendered at the given size.
## The given material is the material that should be baked.
## The given slot defines which material slot should be baked (if the instance class does not support
## slot based overrides, a global override is used instead).
## The material (at the given slot) of the instance will be overwritten with one
## displaying the baked result.
func register(inst: GeometryInstance3D, material: ShaderMaterial, size: Vector2i, slot: int) -> void:
	_registered.append(RegisteredEntry.new(inst, material, size, slot))

## Runs the batched baking process for all registered entries in parallel over the course of
## three frames. Overwrites the materials of the entries with ones displaying the baked results.
func bake() -> void:
	# Only retain the entries that have not been freed since registering
	_registered = _registered.filter(func(r): return is_instance_valid(r.geom_instance))
	
	await _bake_textures(bake_targets.values())
	
	var target_names = bake_targets.keys()
	for r in _registered:
		var mat: ShaderMaterial = _result_material.duplicate()
		if r.geom_instance.has_method("set_surface_override_material"):
			r.geom_instance.set_surface_override_material(r.slot, mat)
		else:
			r.geom_instance.material_override = mat
		
		for i in len(bake_targets):
			var target_name = target_names[i]
			var image := r.baked_images[i]
			if target_name != "albedo":
				image.srgb_to_linear()
			image.generate_mipmaps()
			mat.set_shader_parameter(target_name, ImageTexture.create_from_image(image))
			
	_registered.clear()

## The actual three frame parallel baking loop. Only saves the results in the entry classes,
## does not convert or set materials yet.
func _bake_textures(targets: Array) -> void:
	
	# First, a viewport and a geom instance copy inside it are constructed for each entry
	var viewports = []
	var geom_copies = []
	for r in _registered:
		var vp := SubViewport.new()
		vp.size = r.size
		vp.disable_3d = false
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		vp.transparent_bg = true # Some UVs do not fill the texture, better this way
		add_child(vp)
		viewports.append(vp)
		
		# Only render own children
		vp.world_3d = World3D.new()
		var cam := Camera3D.new()
		vp.add_child(cam)
		
		# Any mesh that is flat on z needs this to be visible, even with cull_disabled in the shader
		cam.translate(Vector3(0.0, 0.0, 1.0))

		# Use a copy of the target instance because it needs to be a child
		# of the viewport and gets the registered material
		var geom_copy: GeometryInstance3D = r.geom_instance.duplicate()
		geom_copy.set_script(null) # Do NOT copy behaviour or you WILL recurse
		geom_copy.visible = true
		geom_copy.transform = Transform3D() # Move back in camera view
		
		if geom_copy.has_method("set_surface_override_material"):
			geom_copy.set_surface_override_material(r.slot, r.material)
		else:
			geom_copy.material_override = r.material
		
		vp.add_child(geom_copy)
		geom_copies.append(geom_copy)

	# Then these viewports render in parallel.
	# Each target takes one frame.
	for t in targets:
		for mc in geom_copies:
			mc.set_instance_shader_parameter("bake_target", t)
		await RenderingServer.frame_post_draw
		
		for i in len(viewports):
			var img: Image = viewports[i].get_texture().get_image()
			_registered[i].baked_images.append(img)
		
	for vp in viewports:
		vp.queue_free()
