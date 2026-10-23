extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_07.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.allowed_towers = ["cannon", "arcane", "frost", "anti_air", "banner"]
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	var clear_layout: bool = true
	for pad: Vector3 in battle.simulation.pads: clear_layout = clear_layout and battle.simulation.routes[0].get_closest_point(pad).distance_to(pad) >= 2.2
	check(clear_layout, "Fortress bases stay off the mirrored road")
	var guard: SimEnemyV2 = battle.simulation.spawn_enemy("shieldbearer")
	battle._physics_process(1.0 / 60)
	var actor: RiggedActor3D = battle.enemy_views[guard.id]
	check(actor.model_path.ends_with("skeleton_warrior.glb") and str(actor.get_meta("equipment")).contains("shield_round_color"), "Shield bearer uses its skeletal guardian model and distinct round shield")
	battle.simulation.damage(guard.id, 50, "pure")
	battle._physics_process(1.0 / 60)
	check(is_equal_approx(actor.health_ratio, 1) and guard.shield == 30, "Projected life remains full while the separate shield absorbs a hit")
	battle.simulation.damage(guard.id, 30, "pure")
	for frame in range(301): battle._physics_process(1.0 / 60)
	check(guard.shield == 80 and guard.shield_recharges_left == 0, "Shield recovers once during real world integration")
	battle.queue_free()
	await process_frame
	print("P7 fortress world: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
