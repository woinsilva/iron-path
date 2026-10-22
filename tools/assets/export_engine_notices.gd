extends SceneTree
func _initialize() -> void:
	var text: String = "GODOT ENGINE 4.5.2 — MIT and third-party notices\n\n" + Engine.get_license_text()
	text += "\n\nTHIRD-PARTY COPYRIGHTS\n" + JSON.stringify(Engine.get_copyright_info(),"  ")
	text += "\n\nTHIRD-PARTY LICENSE TEXTS\n" + JSON.stringify(Engine.get_license_info(),"  ")
	var file: FileAccess = FileAccess.open("res://art/licenses/godot-engine.txt",FileAccess.WRITE)
	if file == null:
		push_error("Cannot write engine notices")
		quit(1)
		return
	file.store_string(text)
	file.close()
	print("Godot and dependency notices exported: ",text.length()," characters")
	quit()
