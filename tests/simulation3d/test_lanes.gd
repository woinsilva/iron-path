extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func crowd() -> BattleSimV2:
	var sim: BattleSimV2 = StageSessionV2.create(StageSessionV2.read_stage("res://data/campaign/stage_05.json"))
	for index in range(3): sim.spawn_enemy("brute", 0, 6.0 + index * 1.2)
	for index in range(6): sim.spawn_enemy("runner", 0, 0.4 + index * 0.5)
	sim.spawn_enemy("boss_captain", 0, 9.5)
	return sim
func trace(sim: BattleSimV2, ticks: int) -> Dictionary:
	var overlap: Dictionary = {}
	var backwards: bool = false
	var off_road: bool = false
	var drifted: bool = false
	var limit: float = float(sim.movement_rules.lane_spacing) + 0.001
	for tick in range(ticks):
		var before: Dictionary = {}
		for enemy: SimEnemyV2 in sim.enemies.values(): before[enemy.id] = enemy.distance
		sim.step()
		var walkers: Array = sim.enemies.values()
		for enemy: SimEnemyV2 in walkers:
			if before.has(enemy.id) and enemy.distance + 0.00001 < float(before[enemy.id]): backwards = true
			if absf(enemy.lateral) > limit: off_road = true
			var route: Curve3D = sim.routes[enemy.route_id]
			if enemy.position.distance_to(route.sample_baked(minf(enemy.distance, route.get_baked_length()))) > 0.001: drifted = true
		for a in range(walkers.size()):
			for b in range(a + 1, walkers.size()):
				var first: SimEnemyV2 = walkers[a]
				var second: SimEnemyV2 = walkers[b]
				if BattleSimV2.distance_xz(sim.display_position(first), sim.display_position(second)) < float(sim.movement_rules.body_radius):
					var key: String = "%d-%d" % [first.id, second.id]
					overlap[key] = int(overlap.get(key, 0)) + 1
	var worst: int = 0
	for key: String in overlap: worst = maxi(worst, int(overlap[key]))
	return {"worst": worst, "backwards": backwards, "off_road": off_road, "drifted": drifted}
func snapshot(sim: BattleSimV2) -> Array:
	var rows: Array = []
	for enemy: SimEnemyV2 in sim.enemies.values(): rows.append([enemy.id, snappedf(enemy.distance, 0.0001), snappedf(enemy.lateral, 0.0001)])
	return rows
func _initialize() -> void:
	var sim: BattleSimV2 = crowd()
	var result: Dictionary = trace(sim, 900)
	check(result.worst <= 20, "Walkers never stay inside each other for more than a third of a second (worst %d ticks)" % result.worst)
	check(not result.backwards, "Queueing never pushes a walker back along the road")
	check(not result.off_road, "Side lanes stay within the road width")
	check(not result.drifted, "Rules keep using the road centre line, so tower reach is unchanged")
	var runner_ahead: bool = false
	for enemy: SimEnemyV2 in sim.enemies.values():
		if enemy.type_id == "runner":
			for other: SimEnemyV2 in sim.enemies.values():
				if other.type_id == "brute" and enemy.distance > other.distance: runner_ahead = true
	check(runner_ahead, "Fast runners overtake slower brutes through a side lane")
	var again: BattleSimV2 = crowd()
	trace(again, 900)
	check(snapshot(again) == snapshot(sim), "Lane choices are deterministic for the same spawns")
	var doubled: BattleSimV2 = crowd()
	for frame in range(450): doubled.advance(2.0 * BattleSimV2.STEP)
	check(snapshot(doubled) == snapshot(sim), "Double speed reaches exactly the same lanes and distances")
	var jam: BattleSimV2 = StageSessionV2.create(StageSessionV2.read_stage("res://data/campaign/stage_05.json"))
	for lane in range(3):
		var blocker: SimEnemyV2 = jam.spawn_enemy("brute", 0, 4.0)
		blocker.lateral = (lane - 1) * float(jam.movement_rules.lane_spacing)
		blocker.target_lateral = blocker.lateral
	var chaser: SimEnemyV2 = jam.spawn_enemy("runner", 0, 2.0)
	for tick in range(240): jam.step()
	var slowest_brute: float = INF
	for enemy: SimEnemyV2 in jam.enemies.values():
		if enemy.type_id == "brute": slowest_brute = minf(slowest_brute, enemy.distance)
	check(chaser.distance < slowest_brute, "With every lane taken the runner queues behind instead of walking through")
	print("P11 lanes: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
