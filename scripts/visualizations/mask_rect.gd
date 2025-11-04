@tool
extends ColorRect

@export var save_png: bool = false:
	set(value):
		_save_png()
		save_png = false # Reset so it can be used like a button
		
func _save_png() -> void:
	# Make it a child of the viewport when saving
	# (click on the viewport in the editor once to make it update its image)
	var vp: SubViewport = get_parent()
	var img := vp.get_texture().get_image()
	img.save_png("user://color_rect.png")
	print("Color rect saved!")
