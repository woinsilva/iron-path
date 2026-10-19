## Main scene script — bootstrap and diagnostics.
## In M0 this displays project diagnostics. In M1+ it will handle routing.
extends Control


@onready var _info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var _status_label: Label = $MarginContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	_display_diagnostics()


func _display_diagnostics() -> void:
	var info_lines: PackedStringArray = [
		"Iron Path — Bootstrap (M0)",
		"",
		"Engine: Godot %s" % Engine.get_version_info().string,
		"Renderer: %s" % ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"),
		"Viewport: %d × %d" % [
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"),
		],
		"Stretch Mode: %s" % ProjectSettings.get_setting("display/window/stretch/mode", "unknown"),
		"Stretch Aspect: %s" % ProjectSettings.get_setting("display/window/stretch/aspect", "unknown"),
		"Orientation: %s" % _get_orientation_name(),
		"Physics FPS: %d" % ProjectSettings.get_setting("physics/common/physics_ticks_per_second"),
		"",
		"Autoloads:",
		"  GameSession: %s" % ("OK" if GameSession != null else "MISSING"),
		"  SaveService: %s" % ("OK" if SaveService != null else "MISSING"),
		"  AudioService: %s" % ("OK" if AudioService != null else "MISSING"),
		"  SceneRouter: %s" % ("OK" if SceneRouter != null else "MISSING"),
	]
	_info_label.text = "\n".join(info_lines)
	_status_label.text = "Bootstrap complete. Ready for M1."


func _get_orientation_name() -> String:
	var orient: int = ProjectSettings.get_setting("display/window/handheld/orientation", 0)
	match orient:
		0: return "Landscape"
		1: return "Landscape"
		2: return "Portrait"
		_: return "Unknown (%d)" % orient
