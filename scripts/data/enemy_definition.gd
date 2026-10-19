## Resource: EnemyDefinition
## Describes an enemy type with base stats before wave/map/difficulty scaling.
class_name EnemyDefinition
extends Resource

## Movement layer for targeting.
enum MovementLayer { GROUND, AIR }

## Unique identifier for this enemy type.
@export var id: StringName = &""
## Localization key for display name.
@export var display_name_key: StringName = &""
## Whether this enemy uses ground or air path.
@export var movement_layer: MovementLayer = MovementLayer.GROUND
## Base hit points before scaling.
@export var base_hp: int = 1
## Base movement speed in game units/second.
@export var base_speed: float = 70.0
## Armor value (reduces physical damage).
@export var armor: int = 0
## Coins awarded on kill.
@export var reward: int = 1
## Lives removed on reaching the exit.
@export var leak_damage: int = 1
## Effect resistance multipliers. Key = effect id, Value = duration multiplier (0.0–1.0).
@export var effect_resistances: Dictionary = {}
## Special abilities (e.g., "healer", "boss_aura"). Empty for basic enemies.
@export var abilities: PackedStringArray = []
## Scene resource for this enemy.
@export var scene: PackedScene = null
## Icon texture.
@export var icon: Texture2D = null


## Validates this definition. Returns an array of error strings.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if id.is_empty():
		errors.append("EnemyDefinition: id cannot be empty")
	if display_name_key.is_empty():
		errors.append("EnemyDefinition[%s]: display_name_key is empty" % id)
	if base_hp <= 0:
		errors.append("EnemyDefinition[%s]: base_hp must be positive (%d)" % [id, base_hp])
	if base_speed <= 0.0:
		errors.append("EnemyDefinition[%s]: base_speed must be positive (%.2f)" % [id, base_speed])
	if armor < 0:
		errors.append("EnemyDefinition[%s]: armor cannot be negative (%d)" % [id, armor])
	if reward < 0:
		errors.append("EnemyDefinition[%s]: reward cannot be negative (%d)" % [id, reward])
	if leak_damage < 0:
		errors.append("EnemyDefinition[%s]: leak_damage cannot be negative (%d)" % [id, leak_damage])

	# Validate resistance values are in valid range.
	for key in effect_resistances:
		var val: Variant = effect_resistances[key]
		if val is float or val is int:
			var fval: float = float(val)
			if fval < 0.0 or fval > 1.0:
				errors.append(
					"EnemyDefinition[%s]: resistance '%s' out of range (%.2f)" %
					[id, str(key), fval]
				)

	return errors


## Returns true if this enemy is airborne.
func is_air() -> bool:
	return movement_layer == MovementLayer.AIR


## Returns the effective duration multiplier for a given effect.
## Returns 1.0 if no resistance is defined.
func get_resistance(effect_id: StringName) -> float:
	if effect_resistances.has(effect_id):
		return float(effect_resistances[effect_id])
	return 1.0
