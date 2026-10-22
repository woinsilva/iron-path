extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_12.json"
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	var before: int = battle.simulation.ticks
	if battle._warming_up:
		battle._physics_process(1)
		battle._start_or_early()
		check(battle.simulation.ticks == before and battle.simulation.wave_index == 0, "Rendered preparation blocks battle clocks and first-wave input")
	while battle._warming_up: await process_frame
	check(battle.simulation.ticks == 0 and battle.simulation.coins == 1900 and battle.simulation.spawned == 0 and battle.simulation.consume_events().is_empty(), "Model preparation cannot advance time spend coins or create logical enemies")
	check(battle._enemy_pool.has("boss_ruin") and battle._enemy_pool.has("swarm"), "Preparation includes the final guardian and its bounded reinforcement model")
	var actors_hidden: bool = true
	for pool: Array in battle._enemy_pool.values():
		for actor: RiggedActor3D in pool: actors_hidden = actors_hidden and not actor.visible and actor.process_mode == Node.PROCESS_MODE_DISABLED
	check(actors_hidden, "Prepared actors wait invisibly without animation processing")
	var primed: RiggedActor3D = (battle._enemy_pool["resistant"] as Array)[0] as RiggedActor3D
	var enemy: SimEnemyV2 = battle.simulation.spawn_enemy("resistant")
	battle._physics_process(1.0/60)
	check(battle.enemy_views[enemy.id] == primed and primed.visible and not primed.dead, "First spawn reuses its prepared model with live state restored")
	check(battle.simulation.ticks == 1 and battle.simulation.spawned == 1, "World still creates exactly one enemy for one authoritative spawn")
	battle.queue_free()
	await process_frame
	print("P9 preparation: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
