extends SceneTree
func _initialize() -> void:
	for name: String in ["icon", "splash"]:
		var image: Image = Image.new()
		var result: Error = image.load_svg_from_string(FileAccess.get_file_as_string("res://art/branding/" + name + ".svg"))
		if result != OK or image.save_png("res://art/branding/" + name + ".png") != OK:
			push_error("Unable to rasterize branding: " + name)
			quit(1)
			return
	quit()
