## Autoload: SceneRouter
## Manages scene transitions. Actual transitions and loading screens are M1+.
class_name SceneRouterNode
extends Node


signal scene_change_started(scene_path: String)
signal scene_change_completed(scene_path: String)


var _current_scene_path: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Returns the path of the currently loaded scene.
func get_current_scene_path() -> String:
	return _current_scene_path


## Changes to a new scene by path. Minimal implementation for M0.
func change_scene(scene_path: String) -> void:
	scene_change_started.emit(scene_path)
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneRouter: Failed to change scene to '%s': %d" % [scene_path, err])
		return
	_current_scene_path = scene_path
	scene_change_completed.emit(scene_path)
