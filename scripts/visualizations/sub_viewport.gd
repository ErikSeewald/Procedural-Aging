@tool
extends SubViewport

@export var save_png: bool = false:
	set(value):
		_save_png()
		save_png = false # Reset so it can be used like a button
		
func _save_png() -> void:
	var img := get_texture().get_image()
	img.save_png("user://sub_viewport.png")
