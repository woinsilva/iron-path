## Resource: MapDefinition
## Describes a map with its gameplay parameters and references.
class_name MapDefinition
extends Resource

## Unique identifier for this map.
@export var id: StringName = &""
## Localization key for display name.
@export var display_name_key: StringName = &""
## Path to the map scene.
@export var scene: PackedScene = null
## Thumbnail texture for map selection.
@export var thumbnail: Texture2D = null
## Starting coins for Normal difficulty on this map.
@export var starting_coins: int = 200
## Starting lives for Normal difficulty on this map.
@export var lives: int = 20
## Array of WaveDefinitions for this map.
@export var wave_set: Array[WaveDefinition] = []
## Map id required to unlock this map (empty = unlocked by default).
@export var unlock_requirement: StringName = &""
## HP multiplier applied to enemies on this map (base = 1.0).
@export var hp_multiplier: float = 1.0


## Validates this map definition. Returns an array of error strings.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if id.is_empty():
		errors.append("MapDefinition: id cannot be empty")
	if display_name_key.is_empty():
		errors.append("MapDefinition[%s]: display_name_key is empty" % id)
	if starting_coins < 0:
		errors.append("MapDefinition[%s]: starting_coins cannot be negative (%d)" % [id, starting_coins])
	if lives <= 0:
		errors.append("MapDefinition[%s]: lives must be positive (%d)" % [id, lives])
	if hp_multiplier <= 0.0:
		errors.append("MapDefinition[%s]: hp_multiplier must be positive (%.2f)" % [id, hp_multiplier])

	for i in range(wave_set.size()):
		if wave_set[i] == null:
			errors.append("MapDefinition[%s]: wave %d is null" % [id, i])
			continue
		var wave_errors := wave_set[i].validate()
		for err in wave_errors:
			errors.append("MapDefinition[%s] W%d: %s" % [id, i, err])

	return errors
