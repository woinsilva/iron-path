## Resource: WaveDefinition
## Describes a complete wave as a list of WaveGroups.
class_name WaveDefinition
extends Resource

## Wave number (1-based, for display).
@export var wave_number: int = 1
## List of enemy groups that make up this wave.
@export var groups: Array[WaveGroup] = []
## Whether to show an air warning before this wave.
@export var air_warning: bool = false
## Seconds before the wave to show the air warning.
@export var air_warning_lead_time: float = 8.0
## Whether to show a boss warning before this wave.
@export var boss_warning: bool = false


## Validates this wave definition. Returns an array of error strings.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if wave_number < 1:
		errors.append("WaveDefinition: wave_number must be >= 1 (%d)" % wave_number)
	if groups.is_empty():
		errors.append("WaveDefinition[%d]: must have at least one group" % wave_number)

	for i in range(groups.size()):
		if groups[i] == null:
			errors.append("WaveDefinition[%d]: group %d is null" % [wave_number, i])
			continue
		var group_errors := groups[i].validate()
		for err in group_errors:
			errors.append("WaveDefinition[%d] G%d: %s" % [wave_number, i, err])

	return errors
