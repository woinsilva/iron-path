class_name SaveServiceNode extends Node
## Versioned local progress; write temporary file, flush, then rename.
signal save_completed(success: bool)
signal load_completed(success: bool)
const SAVE_PATH: String = "user://savegame.json"
const CURRENT_SCHEMA_VERSION: int = 2
var save_path: String = SAVE_PATH
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _create_default_data() -> Dictionary:
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"progress": {"maps_unlocked": ["vale_verde"], "stars": {}, "best_results": {}, "campaign": {}, "formations": {}},
		"settings": {"music_volume": 100, "sfx_volume": 100, "ui_scale": 1.0, "vibration_enabled": true, "graphics_profile": "balanced"},
		"tutorial_completed": false,
	}
func _is_integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value))
func _validate_data(data: Dictionary) -> bool:
	if data.has("tutorial_completed") and not data.tutorial_completed is bool: return false
	var version: Variant = data.get("schema_version")
	if not _is_integer(version) or int(version) < 1 or int(version) > CURRENT_SCHEMA_VERSION:
		return false
	if not data.get("progress") is Dictionary or not data.get("settings") is Dictionary:
		return false
	var formations: Variant = data.progress.get("formations", {})
	if not formations is Dictionary: return false
	for selection: Variant in formations.values():
		if not selection is Array or selection.size() > 5 or selection.is_empty(): return false
		var seen: Dictionary = {}
		for key: Variant in selection:
			if not key is String or seen.has(key): return false
			seen[key] = true
	var campaign: Variant = data.progress.get("campaign", {})
	if not campaign is Dictionary:
		return false
	for key: Variant in campaign:
		if not key is String or not campaign[key] is Dictionary:
			return false
		var stars: Variant = campaign[key].get("stars", 0)
		if not _is_integer(stars) or int(stars) < 0 or int(stars) > 3:
			return false
		if campaign[key].has("best_ticks"):
			var best_ticks: Variant = campaign[key].best_ticks
			if not _is_integer(best_ticks) or int(best_ticks) <= 0: return false
	for key: String in ["music_volume", "sfx_volume"]:
		var value: Variant = data.settings.get(key, 100)
		if not _is_integer(value) or int(value) < 0 or int(value) > 100:
			return false
	if str(data.settings.get("graphics_profile", "balanced")) not in ["economy", "balanced", "quality"]:
		return false
	return true
func _migrate(data: Dictionary) -> Dictionary:
	var result: Dictionary = _create_default_data()
	result.merge(data, true)
	for section: String in ["progress", "settings"]:
		var defaults: Dictionary = _create_default_data()[section]
		defaults.merge(data.get(section, {}), true)
		result[section] = defaults
	result.schema_version = CURRENT_SCHEMA_VERSION
	return result
func save_game(data: Dictionary) -> bool:
	if not _validate_data(data):
		save_completed.emit(false)
		return false
	var normalized: Dictionary = _migrate(data)
	var file: FileAccess = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_completed.emit(false)
		return false
	file.store_string(JSON.stringify(normalized, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		save_completed.emit(false)
		return false
	# Never replace the last valid backup with damaged data.
	if not _read_valid(save_path).is_empty():
		var backup_error: Error = DirAccess.copy_absolute(save_path, save_path + ".backup")
		if backup_error != OK:
			save_completed.emit(false)
			return false
	var error: Error = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	save_completed.emit(error == OK)
	return error == OK
func _read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path).trim_prefix("\ufeff")) != OK:
		return {}
	var value: Variant = parser.data
	if value is Dictionary and _validate_data(value):
		return _migrate(value)
	return {}
func load_game() -> Dictionary:
	var data: Dictionary = _read_valid(save_path)
	if not data.is_empty():
		load_completed.emit(true)
		return data
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path, save_path + ".corrupt")
		data = _read_valid(save_path + ".backup")
		load_completed.emit(false)
		return data if not data.is_empty() else _create_default_data()
	load_completed.emit(true)
	return _create_default_data()
func record_battle(data: Dictionary, result: Dictionary) -> bool:
	if int(result.get("state", -1)) != BattleSimV2.State.VICTORY:
		return false
	var stage: String = str(result.get("stage", ""))
	var difficulty: String = str(result.get("difficulty", ""))
	if not stage.begins_with("stage_") or difficulty not in ["adventure", "normal", "veteran"]:
		return false
	var key: String = stage + ":" + difficulty
	var previous: Dictionary = data.progress.campaign.get(key, {})
	var stars: int = clampi(int(result.get("stars", 0)), 0, 3)
	var ticks: int = maxi(1, int(result.get("ticks", 1)))
	data.progress.campaign[key] = {
		"stars": maxi(stars, int(previous.get("stars", 0))),
		"best_ticks": mini(ticks, int(previous.get("best_ticks", ticks))),
	}
	return save_game(data)
