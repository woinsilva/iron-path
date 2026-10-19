## Tests for Resource definitions and ResourceValidator.
## Covers: valid creation, invalid field rejection, cost ordering, unique IDs.
extends TestBase


func _init() -> void:
	super("ResourceValidation")


func run_tests() -> void:
	_test_tower_level_valid()
	_test_tower_level_invalid()
	_test_tower_definition_valid()
	_test_tower_definition_empty_id()
	_test_tower_definition_cost_ordering()
	_test_enemy_definition_valid()
	_test_enemy_definition_invalid()
	_test_wave_group_valid()
	_test_wave_group_invalid()
	_test_wave_definition_valid()
	_test_map_definition_valid()
	_test_map_definition_invalid()
	_test_validator_duplicate_tower_ids()
	_test_validator_duplicate_enemy_ids()
	_test_validator_wave_unknown_enemy()
	_test_validator_map_unknown_unlock()


# -- TowerLevel --

func _test_tower_level_valid() -> void:
	var level := TowerLevel.new()
	level.cost = 70
	level.build_time = 3.0
	level.damage = 12
	level.damage_type = &"physical"
	level.attacks_per_second = 1.25
	level.range_radius = 210.0
	level.projectile_speed = 400.0
	level.visual_level = 1
	var errors := level.validate()
	assert_empty(errors, "Valid TowerLevel should produce no errors")


func _test_tower_level_invalid() -> void:
	var level := TowerLevel.new()
	level.cost = -10
	level.build_time = -1.0
	level.damage = -5
	level.attacks_per_second = 0.0
	level.range_radius = 0.0
	level.visual_level = 0
	var errors := level.validate()
	assert_gt(errors.size(), 0, "Invalid TowerLevel should produce errors")
	# Expect at least: cost, build_time, damage, aps, range, visual_level
	assert_gte(errors.size(), 5, "Should catch multiple invalid fields")


# -- TowerDefinition --

func _test_tower_definition_valid() -> void:
	var td := TowerDefinition.new()
	td.id = &"archer"
	td.display_name_key = &"TOWER_ARCHER"
	td.target_layer = TowerDefinition.TargetLayer.BOTH

	var l1 := TowerLevel.new()
	l1.cost = 70
	l1.build_time = 3.0
	l1.damage = 12
	l1.attacks_per_second = 1.25
	l1.range_radius = 210.0
	l1.visual_level = 1

	var l2 := TowerLevel.new()
	l2.cost = 95
	l2.build_time = 5.0
	l2.damage = 22
	l2.attacks_per_second = 1.4
	l2.range_radius = 225.0
	l2.visual_level = 2

	td.levels = [l1, l2]
	var errors := td.validate()
	assert_empty(errors, "Valid TowerDefinition should produce no errors")


func _test_tower_definition_empty_id() -> void:
	var td := TowerDefinition.new()
	td.id = &""
	td.display_name_key = &"TOWER_TEST"
	var l1 := TowerLevel.new()
	l1.cost = 50
	l1.build_time = 2.0
	l1.damage = 10
	l1.attacks_per_second = 1.0
	l1.range_radius = 100.0
	l1.visual_level = 1
	td.levels = [l1]
	var errors := td.validate()
	assert_not_empty(errors, "Empty id should produce errors")


func _test_tower_definition_cost_ordering() -> void:
	var td := TowerDefinition.new()
	td.id = &"test_tower"
	td.display_name_key = &"TOWER_TEST"

	var l1 := TowerLevel.new()
	l1.cost = 100
	l1.build_time = 3.0
	l1.damage = 10
	l1.attacks_per_second = 1.0
	l1.range_radius = 200.0
	l1.visual_level = 1

	var l2 := TowerLevel.new()
	l2.cost = 50  # Cheaper than level 1 — should fail!
	l2.build_time = 5.0
	l2.damage = 20
	l2.attacks_per_second = 1.2
	l2.range_radius = 220.0
	l2.visual_level = 2

	td.levels = [l1, l2]
	var errors := td.validate()
	assert_not_empty(errors, "Decreasing costs across levels should fail")


# -- EnemyDefinition --

func _test_enemy_definition_valid() -> void:
	var ed := EnemyDefinition.new()
	ed.id = &"grunt"
	ed.display_name_key = &"ENEMY_GRUNT"
	ed.movement_layer = EnemyDefinition.MovementLayer.GROUND
	ed.base_hp = 70
	ed.base_speed = 70.0
	ed.armor = 0
	ed.reward = 6
	ed.leak_damage = 1
	var errors := ed.validate()
	assert_empty(errors, "Valid EnemyDefinition should produce no errors")


func _test_enemy_definition_invalid() -> void:
	var ed := EnemyDefinition.new()
	ed.id = &""
	ed.display_name_key = &""
	ed.base_hp = 0
	ed.base_speed = -5.0
	ed.armor = -1
	ed.reward = -2
	ed.leak_damage = -1
	var errors := ed.validate()
	assert_gte(errors.size(), 6, "Multiple invalid fields should produce errors")


# -- WaveGroup --

func _test_wave_group_valid() -> void:
	var wg := WaveGroup.new()
	wg.enemy_id = &"grunt"
	wg.count = 8
	wg.spawn_interval = 0.8
	wg.start_delay = 0.0
	var errors := wg.validate()
	assert_empty(errors, "Valid WaveGroup should produce no errors")


func _test_wave_group_invalid() -> void:
	var wg := WaveGroup.new()
	wg.enemy_id = &""
	wg.count = -1
	wg.spawn_interval = -0.5
	wg.start_delay = -1.0
	var errors := wg.validate()
	assert_gte(errors.size(), 3, "Invalid WaveGroup should produce errors")


# -- WaveDefinition --

func _test_wave_definition_valid() -> void:
	var wd := WaveDefinition.new()
	wd.wave_number = 1
	var g := WaveGroup.new()
	g.enemy_id = &"grunt"
	g.count = 8
	g.spawn_interval = 0.8
	wd.groups = [g]
	var errors := wd.validate()
	assert_empty(errors, "Valid WaveDefinition should produce no errors")


# -- MapDefinition --

func _test_map_definition_valid() -> void:
	var md := MapDefinition.new()
	md.id = &"vale_verde"
	md.display_name_key = &"MAP_VALE_VERDE"
	md.starting_coins = 200
	md.lives = 20
	md.hp_multiplier = 1.0
	var errors := md.validate()
	assert_empty(errors, "Valid MapDefinition should produce no errors")


func _test_map_definition_invalid() -> void:
	var md := MapDefinition.new()
	md.id = &""
	md.display_name_key = &""
	md.starting_coins = -10
	md.lives = 0
	md.hp_multiplier = 0.0
	var errors := md.validate()
	assert_gte(errors.size(), 4, "Invalid MapDefinition should produce errors")


# -- ResourceValidator cross-checks --

func _test_validator_duplicate_tower_ids() -> void:
	var t1 := TowerDefinition.new()
	t1.id = &"archer"
	t1.display_name_key = &"TOWER_ARCHER"
	var l := TowerLevel.new()
	l.cost = 70
	l.build_time = 3.0
	l.damage = 12
	l.attacks_per_second = 1.25
	l.range_radius = 210.0
	l.visual_level = 1
	t1.levels = [l]

	var t2 := TowerDefinition.new()
	t2.id = &"archer"  # Duplicate!
	t2.display_name_key = &"TOWER_ARCHER2"
	var l2 := TowerLevel.new()
	l2.cost = 50
	l2.build_time = 2.0
	l2.damage = 8
	l2.attacks_per_second = 1.0
	l2.range_radius = 180.0
	l2.visual_level = 1
	t2.levels = [l2]

	var towers: Array[TowerDefinition] = [t1, t2]
	var errors := ResourceValidator.validate_towers(towers)
	assert_not_empty(errors, "Duplicate tower IDs should produce errors")


func _test_validator_duplicate_enemy_ids() -> void:
	var e1 := EnemyDefinition.new()
	e1.id = &"grunt"
	e1.display_name_key = &"ENEMY_GRUNT"
	e1.base_hp = 70
	e1.base_speed = 70.0

	var e2 := EnemyDefinition.new()
	e2.id = &"grunt"  # Duplicate!
	e2.display_name_key = &"ENEMY_GRUNT2"
	e2.base_hp = 50
	e2.base_speed = 80.0

	var enemies: Array[EnemyDefinition] = [e1, e2]
	var errors := ResourceValidator.validate_enemies(enemies)
	assert_not_empty(errors, "Duplicate enemy IDs should produce errors")


func _test_validator_wave_unknown_enemy() -> void:
	var wd := WaveDefinition.new()
	wd.wave_number = 1
	var g := WaveGroup.new()
	g.enemy_id = &"unknown_enemy"
	g.count = 5
	g.spawn_interval = 1.0
	wd.groups = [g]

	var waves: Array[WaveDefinition] = [wd]
	var known: PackedStringArray = [&"grunt", &"runner"]
	var errors := ResourceValidator.validate_waves(waves, known)
	assert_not_empty(errors, "Unknown enemy_id in wave should produce errors")


func _test_validator_map_unknown_unlock() -> void:
	var m1 := MapDefinition.new()
	m1.id = &"map_1"
	m1.display_name_key = &"MAP_1"
	m1.starting_coins = 200
	m1.lives = 20
	m1.hp_multiplier = 1.0
	m1.unlock_requirement = &"nonexistent_map"

	var maps: Array[MapDefinition] = [m1]
	var errors := ResourceValidator.validate_maps(maps)
	assert_not_empty(errors, "Unknown unlock_requirement should produce errors")
