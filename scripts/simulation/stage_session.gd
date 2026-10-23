class_name StageSessionV2 extends RefCounted

static func read_stage(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path).trim_prefix("\ufeff")) as Dictionary

static func curve_from_points(points: PackedVector3Array) -> Curve3D:
	var curve: Curve3D = Curve3D.new()
	curve.bake_interval = 0.12
	for index in range(points.size()):
		var previous: Vector3 = points[maxi(index - 1, 0)]
		var following: Vector3 = points[mini(index + 1, points.size() - 1)]
		var tangent: Vector3 = (following - previous) * 0.17
		curve.add_point(points[index], -tangent, tangent)
	return curve

static func create(stage: Dictionary, difficulty: String = "normal") -> BattleSimV2:
	var pads: PackedVector3Array = PackedVector3Array()
	for point: Array in stage.pads:
		pads.append(Vector3(float(point[0]), 0, float(point[2])))
	var points: PackedVector3Array = PackedVector3Array()
	for point: Array in stage.route_points:
		points.append(Vector3(float(point[0]), float(point[1]), float(point[2])))
	var definitions: Dictionary = BattleSimV2.load_catalog().duplicate(true)
	var profiles: Dictionary = read_stage("res://data/campaign/difficulties.json").profiles
	assert(profiles.has(difficulty), "Difficulty must reference a declared profile")
	var profile: Dictionary = profiles[difficulty]
	var initial_money: int = int(round(float(stage.starting_coins) * float(profile.starting_coins)))
	var initial_health: int = int(stage.lives) if int(profile.lives) == 0 else int(profile.lives)
	for key: String in definitions.towers.keys():
		if key not in stage.allowed_towers:
			definitions.towers.erase(key)
		else:
			definitions.towers[key].levels = (definitions.towers[key].levels as Array).slice(0, mini(3, int(stage.max_level)))
			if int(stage.max_level) <= 3:
				definitions.towers[key].erase("branches")
			elif definitions.towers[key].has("branches"):
				for branch: Dictionary in definitions.towers[key].branches.values():
					branch.levels = (branch.levels as Array).slice(0, int(stage.max_level) - 3)
	for definition: Dictionary in definitions.enemies.values():
		definition.hp = ceilf(float(definition.hp) * float(profile.hp))
		definition.speed = float(definition.speed) * float(profile.speed)
	var waves: Array = stage.waves.duplicate(true)
	for wave: Dictionary in waves:
		wave.interval = float(profile.intermission) if float(profile.intermission) > 0 else float(wave.interval)
	var routes: Array[Curve3D] = [curve_from_points(points)]
	if stage.has("air_route_points"):
		var air: PackedVector3Array = PackedVector3Array()
		for point: Array in stage.air_route_points:
			air.append(Vector3(float(point[0]), float(point[1]), float(point[2])))
		routes.append(curve_from_points(air))
	for extra: Array in stage.get("extra_route_points", []):
		var branch_points: PackedVector3Array = PackedVector3Array()
		for point: Array in extra: branch_points.append(Vector3(float(point[0]), float(point[1]), float(point[2])))
		routes.append(curve_from_points(branch_points))
	var sim: BattleSimV2 = BattleSimV2.new(definitions, routes, pads, waves, initial_money, initial_health)
	if stage.has("air_route_points"): sim.air_routes.append(1)
	for zone: Array in stage.get("blocked_zones", []):
		sim.blocked_zones.append(Rect2(float(zone[0]), float(zone[1]), float(zone[2]), float(zone[3])))
	if stage.has("bounds"): sim.placement_rules.bounds = stage.bounds
	return sim

## Enemies written in the stage's waves (optionally of one type), before summons add any of their own.
static func authored_enemy_count(stage: Dictionary, enemy_id: String = "") -> int:
	var total: int = 0
	for wave: Dictionary in stage.waves:
		for group: Dictionary in wave.groups:
			if enemy_id.is_empty() or str(group.enemy) == enemy_id: total += int(group.count)
	return total
