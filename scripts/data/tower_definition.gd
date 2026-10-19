## Resource: TowerDefinition
## Describes a tower family with all its levels.
class_name TowerDefinition
extends Resource

## Target layer filter.
enum TargetLayer { GROUND, AIR, BOTH }

## Unique identifier for this tower type.
@export var id: StringName = &""
## Localization key for display name.
@export var display_name_key: StringName = &""
## Localization key for description.
@export var description_key: StringName = &""
## Which enemies this tower can target.
@export var target_layer: TargetLayer = TargetLayer.BOTH
## Ordered array of levels (index 0 = level 1).
@export var levels: Array[TowerLevel] = []
## Icon texture resource path.
@export var icon: Texture2D = null
## Scene resource path for this tower.
@export var scene: PackedScene = null
## Tags for categorization and filtering.
@export var tags: PackedStringArray = []


## Validates this definition. Returns an array of error strings.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if id.is_empty():
		errors.append("TowerDefinition: id cannot be empty")
	if display_name_key.is_empty():
		errors.append("TowerDefinition[%s]: display_name_key is empty" % id)
	if levels.is_empty():
		errors.append("TowerDefinition[%s]: must have at least one level" % id)

	# Validate each level.
	for i in range(levels.size()):
		if levels[i] == null:
			errors.append("TowerDefinition[%s]: level %d is null" % [id, i + 1])
			continue
		var level_errors := levels[i].validate()
		for err in level_errors:
			errors.append("TowerDefinition[%s] L%d: %s" % [id, i + 1, err])

	# Check costs are non-decreasing across levels.
	for i in range(1, levels.size()):
		if levels[i] != null and levels[i - 1] != null:
			if levels[i].cost < levels[i - 1].cost:
				errors.append(
					"TowerDefinition[%s]: level %d cost (%d) < level %d cost (%d)" %
					[id, i + 1, levels[i].cost, i, levels[i - 1].cost]
				)

	return errors


## Returns the TowerLevel for the given 1-based level number, or null.
func get_level(level_number: int) -> TowerLevel:
	var idx: int = level_number - 1
	if idx < 0 or idx >= levels.size():
		return null
	return levels[idx]


## Returns the maximum level number available.
func get_max_level() -> int:
	return levels.size()
