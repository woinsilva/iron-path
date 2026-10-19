## ResourceValidator
## Utility to validate collections of game data resources.
## Checks for unique IDs, valid references, and cross-resource consistency.
class_name ResourceValidator
extends RefCounted


## Validates a set of TowerDefinitions. Returns all errors found.
static func validate_towers(towers: Array[TowerDefinition]) -> PackedStringArray:
	var errors: PackedStringArray = []
	var seen_ids: Dictionary = {}

	for tower in towers:
		if tower == null:
			errors.append("ResourceValidator: null TowerDefinition in array")
			continue

		# Check unique IDs.
		if seen_ids.has(tower.id):
			errors.append("ResourceValidator: duplicate tower id '%s'" % tower.id)
		seen_ids[tower.id] = true

		# Delegate to resource's own validation.
		var tower_errors := tower.validate()
		errors.append_array(tower_errors)

	return errors


## Validates a set of EnemyDefinitions. Returns all errors found.
static func validate_enemies(enemies: Array[EnemyDefinition]) -> PackedStringArray:
	var errors: PackedStringArray = []
	var seen_ids: Dictionary = {}

	for enemy in enemies:
		if enemy == null:
			errors.append("ResourceValidator: null EnemyDefinition in array")
			continue

		if seen_ids.has(enemy.id):
			errors.append("ResourceValidator: duplicate enemy id '%s'" % enemy.id)
		seen_ids[enemy.id] = true

		var enemy_errors := enemy.validate()
		errors.append_array(enemy_errors)

	return errors


## Validates a set of WaveDefinitions. Returns all errors found.
## Optionally checks that enemy_ids reference known enemies.
static func validate_waves(
	waves: Array[WaveDefinition],
	known_enemy_ids: PackedStringArray = []
) -> PackedStringArray:
	var errors: PackedStringArray = []
	var enemy_set: Dictionary = {}
	for eid in known_enemy_ids:
		enemy_set[eid] = true

	for wave in waves:
		if wave == null:
			errors.append("ResourceValidator: null WaveDefinition in array")
			continue

		var wave_errors := wave.validate()
		errors.append_array(wave_errors)

		# Cross-reference enemy ids if known enemies are provided.
		if not known_enemy_ids.is_empty():
			for group in wave.groups:
				if group != null and not enemy_set.has(group.enemy_id):
					errors.append(
						"ResourceValidator: wave %d references unknown enemy '%s'" %
						[wave.wave_number, group.enemy_id]
					)

	return errors


## Validates a set of MapDefinitions. Returns all errors found.
static func validate_maps(maps: Array[MapDefinition]) -> PackedStringArray:
	var errors: PackedStringArray = []
	var seen_ids: Dictionary = {}

	for map_def in maps:
		if map_def == null:
			errors.append("ResourceValidator: null MapDefinition in array")
			continue

		if seen_ids.has(map_def.id):
			errors.append("ResourceValidator: duplicate map id '%s'" % map_def.id)
		seen_ids[map_def.id] = true

		var map_errors := map_def.validate()
		errors.append_array(map_errors)

	# Verify unlock requirements reference existing maps.
	for map_def in maps:
		if map_def != null and not map_def.unlock_requirement.is_empty():
			if not seen_ids.has(map_def.unlock_requirement):
				errors.append(
					"ResourceValidator: map '%s' requires unknown map '%s'" %
					[map_def.id, map_def.unlock_requirement]
				)

	return errors
