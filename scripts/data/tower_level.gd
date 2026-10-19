## Resource: TowerLevel
## Holds stats for a single level of a tower.
class_name TowerLevel
extends Resource

## Cost in coins to build/upgrade to this level.
@export var cost: int = 0
## Build/upgrade time in seconds.
@export var build_time: float = 0.0
## Base damage per hit.
@export var damage: int = 0
## Damage type: "physical", "magical", "pure".
@export var damage_type: StringName = &"physical"
## Attacks per second (cadence).
@export var attacks_per_second: float = 1.0
## Targeting range in game units.
@export var range_radius: float = 200.0
## Speed of projectile in game units/second. 0 = instant.
@export var projectile_speed: float = 400.0
## Splash/explosion radius. 0 = single target.
@export var splash_radius: float = 0.0
## Optional effect applied on hit (slow, poison, bleed). Null = none.
@export var effect_id: StringName = &""
## Effect potency (e.g., slow percentage 0.0–1.0, or DPS for DoTs).
@export var effect_potency: float = 0.0
## Effect duration in seconds.
@export var effect_duration: float = 0.0
## Visual tier for sprite selection.
@export var visual_level: int = 1


## Validates this level's data. Returns an array of error strings.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if cost < 0:
		errors.append("TowerLevel: cost cannot be negative (%d)" % cost)
	if build_time < 0.0:
		errors.append("TowerLevel: build_time cannot be negative (%.2f)" % build_time)
	if damage < 0:
		errors.append("TowerLevel: damage cannot be negative (%d)" % damage)
	if attacks_per_second <= 0.0:
		errors.append("TowerLevel: attacks_per_second must be positive (%.2f)" % attacks_per_second)
	if range_radius <= 0.0:
		errors.append("TowerLevel: range_radius must be positive (%.2f)" % range_radius)
	if projectile_speed < 0.0:
		errors.append("TowerLevel: projectile_speed cannot be negative (%.2f)" % projectile_speed)
	if splash_radius < 0.0:
		errors.append("TowerLevel: splash_radius cannot be negative (%.2f)" % splash_radius)
	if visual_level < 1:
		errors.append("TowerLevel: visual_level must be >= 1 (%d)" % visual_level)
	return errors
