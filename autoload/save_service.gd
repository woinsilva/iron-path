## Autoload: SaveService
## Handles atomic save/load of player progress to user://savegame.json.
## Validates data on load; backs up last valid save; migrates schema versions.
class_name SaveServiceNode
extends Node

const SAVE_PATH: String = "user://savegame.json"
const BACKUP_PATH: String = "user://savegame_backup.json"
const CORRUPT_PATH: String = "user://savegame_corrupt.json"
const CURRENT_SCHEMA_VERSION: int = 1


signal save_completed(success: bool)
signal load_completed(success: bool)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Creates a new default save data dictionary.
func _create_default_data() -> Dictionary:
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"progress": {
			"maps_unlocked": [&"vale_verde"],
			"stars": {},
			"best_results": {},
		},
		"settings": {
			"music_volume": 100,
			"sfx_volume": 100,
			"ui_scale": 1.0,
			"vibration_enabled": true,
		},
		"tutorial_completed": false,
	}


## Validates the types and ranges of loaded save data.
func _validate_data(data: Dictionary) -> bool:
	if not data.has("schema_version"):
		return false
	if not data["schema_version"] is int:
		return false
	if not data.has("progress"):
		return false
	if not data["progress"] is Dictionary:
		return false
	if not data.has("settings"):
		return false
	if not data["settings"] is Dictionary:
		return false
	return true


## Migrates save data from one schema version to the next.
func _migrate(data: Dictionary) -> Dictionary:
	var version: int = data.get("schema_version", 0)
	# Future migrations go here, applied sequentially.
	# if version < 2:
	#     data["new_field"] = default_value
	#     data["schema_version"] = 2
	data["schema_version"] = CURRENT_SCHEMA_VERSION
	return data


## Saves data atomically (write temp, then rename).
func save_game(data: Dictionary) -> bool:
	var temp_path: String = SAVE_PATH + ".tmp"
	var json_string: String = JSON.stringify(data, "\t")

	# Write to temporary file first.
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: Cannot open temp file for writing: %s" % temp_path)
		save_completed.emit(false)
		return false

	file.store_string(json_string)
	file.close()

	# Backup current save before overwriting.
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			dir.copy(SAVE_PATH, BACKUP_PATH)

	# Atomic rename.
	var dir := DirAccess.open("user://")
	if dir:
		var err := dir.rename(temp_path, SAVE_PATH)
		if err != OK:
			push_error("SaveService: Failed to rename temp to save: %d" % err)
			save_completed.emit(false)
			return false

	save_completed.emit(true)
	return true


## Loads and validates save data. Returns default if missing or corrupt.
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		var default_data := _create_default_data()
		load_completed.emit(true)
		return default_data

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveService: Cannot open save file, using defaults")
		load_completed.emit(false)
		return _create_default_data()

	var content: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(content)
	if parse_result != OK:
		push_warning("SaveService: JSON parse error, preserving corrupt file")
		_preserve_corrupt()
		load_completed.emit(false)
		return _create_default_data()

	var data: Variant = json.data
	if not data is Dictionary:
		push_warning("SaveService: Root is not Dictionary, preserving corrupt file")
		_preserve_corrupt()
		load_completed.emit(false)
		return _create_default_data()

	if not _validate_data(data as Dictionary):
		push_warning("SaveService: Validation failed, preserving corrupt file")
		_preserve_corrupt()
		load_completed.emit(false)
		return _create_default_data()

	# Migrate if needed.
	if data["schema_version"] < CURRENT_SCHEMA_VERSION:
		data = _migrate(data as Dictionary)
		save_game(data as Dictionary)

	load_completed.emit(true)
	return data as Dictionary


## Preserves the corrupt file for diagnostics.
func _preserve_corrupt() -> void:
	var dir := DirAccess.open("user://")
	if dir and FileAccess.file_exists(SAVE_PATH):
		dir.copy(SAVE_PATH, CORRUPT_PATH)
