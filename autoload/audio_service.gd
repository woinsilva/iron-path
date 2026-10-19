## Autoload: AudioService
## Manages audio buses and provides play/stop helpers.
## Actual audio content is loaded in later milestones.
class_name AudioServiceNode
extends Node

## Audio bus names matching the project audio bus layout.
const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_UI: StringName = &"UI"

## Maximum simultaneous combat SFX as per spec.
const MAX_COMBAT_SFX: int = 12


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Sets volume for a bus by name (0–100 linear scale).
func set_bus_volume(bus_name: StringName, volume_percent: int) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		push_warning("AudioService: Bus '%s' not found" % bus_name)
		return
	var clamped: int = clampi(volume_percent, 0, 100)
	if clamped == 0:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		var db: float = linear_to_db(clamped / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db)


## Gets volume for a bus by name (0–100 linear scale).
func get_bus_volume(bus_name: StringName) -> int:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return 0
	if AudioServer.is_bus_mute(bus_idx):
		return 0
	var db: float = AudioServer.get_bus_volume_db(bus_idx)
	return roundi(db_to_linear(db) * 100.0)
