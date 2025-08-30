extends Node

var _vp: SubViewport
var _rect: ColorRect

func _ready() -> void:
	_vp = SubViewport.new()
	_vp.disable_3d = true
	_vp.transparent_bg = false
	_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(_vp)
	
	_rect = ColorRect.new()
	_rect.color = Color.WHITE	
	_vp.add_child(_rect)

## Returns a Texture2DArray created by rendering each given ShaderMaterial
## to a ColorRect([param width], [param height]).
## Expects all shader params to already be set.
func from_materials(materials: Array[ShaderMaterial], width: int, height: int)  -> Texture2DArray:
	_vp.size = Vector2i(width, height)
	_rect.size = Vector2(width, height)
	
	var images: Array[Image] = []
	for mat in materials:
		_rect.material = mat
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw

		var img: Image = _vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		images.append(img)

	var arr = Texture2DArray.new()
	arr.create_from_images(images)
	return arr
