@tool
extends EditorScript

func _run():
	var tex: Texture2D = load("res://Textures/spot_layers.jpg")
	var img1: Image = tex.get_image()
	img1.decompress()
	img1.convert(Image.FORMAT_RGB8)
	
	tex = load("res://Textures/rust_layers.jpg")
	var img2: Image = tex.get_image()
	img2.decompress()
	img2.convert(Image.FORMAT_RGB8)
	
	var tex_array := Texture2DArray.new()
	tex_array.create_from_images([img1, img2])

	
	var flags := ResourceSaver.SaverFlags.FLAG_BUNDLE_RESOURCES | ResourceSaver.SaverFlags.FLAG_COMPRESS
	var path := "res://Textures/tex_array.tres"
	var err := ResourceSaver.save(tex_array, path, flags)
	
	if err != OK:
		push_error("ResourceSaver.save failed with code: " + str(err))
	else:
		print("Saved: ", path)
