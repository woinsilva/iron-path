## Resource: WaveGroup
## A single group of enemies within a wave.
class_name WaveGroup
extends Resource

## Enemy type id from EnemyDefinition.
@export var enemy_id: StringName = &""
## Number of enemies in this group.
@export var count: int = 1
## Time between spawns within this group, in seconds.
@export var spawn_interval: float = 0.8
## Delay before this group starts spawning, in seconds.
@export var start_delay: float = 0.0
## Which path this group uses (for multi-entry maps).
@export var path_id: StringName = &"main"
## Optional modifiers (e.g., {"hp_multiplier": 0.45} for miniboss waves).
@export var modifiers: Dictionary = {}


## Validates this group's data. Returns an array of error strings.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if enemy_id.is_empty():
		errors.append("WaveGroup: enemy_id cannot be empty")
	if count <= 0:
		errors.append("WaveGroup[%s]: count must be positive (%d)" % [enemy_id, count])
	if spawn_interval < 0.0:
		errors.append("WaveGroup[%s]: spawn_interval cannot be negative (%.2f)" % [enemy_id, spawn_interval])
	if start_delay < 0.0:
		errors.append("WaveGroup[%s]: start_delay cannot be negative (%.2f)" % [enemy_id, start_delay])
	return errors
