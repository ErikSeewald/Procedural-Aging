extends Node3D

# Should be autoload

const bake_targets = {"albedo": 0, "mrs": 1, "normal": 2}

class RegisteredEntry:
	func _init(mesh: MeshInstance3D, mat: ShaderMaterial) -> void:
		mesh_instance = mesh
		material = mat
		baked_images = [] # Filled later
	
	var mesh_instance: MeshInstance3D
	var material: ShaderMaterial
	var baked_images: Array[Image]
	
var _registered: Array[RegisteredEntry] = []

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("bake"):
		bake()
		
	if event.is_action_pressed("save_and_export"):
		save_bake()

func save_bake() -> void:
	var target_names = bake_targets.keys()
	for r in _registered:
		var images = r.baked_images
		for i in len(images):
			images[i].save_png("res://baked_%s.png" % target_names[i])

	print("Baking saved!")

func register(mesh: MeshInstance3D, material: ShaderMaterial) -> void:
	_registered.append(RegisteredEntry.new(mesh, material))

func bake() -> void:
	var size = Vector2i(2048, 2048)
	await _bake_textures(size, bake_targets.values())
	var target_names = bake_targets.keys()
	
	for r in _registered:
		var mat: ShaderMaterial = r.mesh_instance.get_active_material(0)
		for i in len(bake_targets):
			if i != 0:
				r.baked_images[i].srgb_to_linear()
			var tex := ImageTexture.create_from_image(r.baked_images[i])
			mat.set_shader_parameter(target_names[i], tex)
	#_registered.clear()

func _bake_textures(size: Vector2i, targets: Array) -> void:
	var viewports = []
	var mesh_copies = []
	for r in _registered:
		var vp := SubViewport.new()
		vp.size = size
		vp.disable_3d = false
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		vp.transparent_bg = true # Some UVs do not fill the texture, better this way
		add_child(vp)
		viewports.append(vp)
		
		# Only render own children
		vp.world_3d = World3D.new()
		vp.add_child(Camera3D.new())

		# Use a copy of the target mesh because it needs to be a child
		# of the viewport and gets the registered material
		var mesh_copy: MeshInstance3D = r.mesh_instance.duplicate()
		mesh_copy.set_script(null) # Do NOT copy behaviour or you WILL recurse
		mesh_copy.set_surface_override_material(0, r.material)
		mesh_copy.visible = true
		mesh_copy .transform = Transform3D() # Move back in camera view
		vp.add_child(mesh_copy)
		mesh_copies.append(mesh_copy)

	# Each target takes one frame. Since all baked objects are parallel,
	# this is still a very small (and constant) amount of frames for baking.
	for t in targets:
		for mc in mesh_copies:
			mc.set_instance_shader_parameter("bake_target", t)
		await RenderingServer.frame_post_draw
		
		for i in len(viewports):
			var img: Image = viewports[i].get_texture().get_image()#
			_registered[i].baked_images.append(img)
		
	for vp in viewports:
		vp.queue_free()

"""
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save_and_export"):
		save_bake()

func save_bake() -> void:
	var target_names = bake_targets.keys()
	for i in len(images):
		images[i].save_png("res://baked_%s.png" % target_names[i])

	print("Baking saved!")
"""
