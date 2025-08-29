extends Node

var tex_array: Texture2DArray
var _vp: SubViewport
var _rect: ColorRect
var _mat: ShaderMaterial

var texture_shader: Shader

func _ready() -> void:
	texture_shader = ResourceLoader.load("res://Shaders/texer.gdshader");
	
	_vp = SubViewport.new()
	_vp.disable_3d = true
	_vp.transparent_bg = false
	add_child(_vp)
	
	_mat = ShaderMaterial.new()
	_mat.shader = texture_shader
	
	_rect = ColorRect.new()
	_rect.color = Color.WHITE
	_rect.material = _mat	
	_vp.add_child(_rect)

func bake_from_textures(tex_paths: Array[String]) -> Texture2DArray:
	var images: Array[Image] = []
	for tex_path in tex_paths:
		var tex := load(tex_path) as Texture2D
		assert(tex, "Could not load texture at: " + tex_path)
		_mat.set_shader_parameter("src_tex", tex)	

		# DEBUG LOW RES FOR NOW
		var w := tex.get_width() / 4
		var h := tex.get_height() / 4
		_vp.size = Vector2i(w, h)
		_rect.size = Vector2(w, h)

		# Render once and read back
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw

		var img: Image = _vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		images.append(img)

	tex_array = Texture2DArray.new()
	tex_array.create_from_images(images)

	return tex_array
