extends SceneTree
var failures: int = 0
var checks: int = 0
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
	battle.stage_path = "res://data/campaign/stage_06.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.allowed_towers = ["cannon", "arcane", "frost", "banner", "anti_air"]
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	var clear_layout: bool = true
	for pad: Vector3 in battle.simulation.pads: clear_layout = clear_layout and battle.simulation.routes[0].get_closest_point(pad).distance_to(pad) >= 2.2
	check(clear_layout, "Quarry building bases remain off its complete route")
	var brute: SimEnemyV2 = battle.simulation.spawn_enemy("brute")
	var runner: SimEnemyV2 = battle.simulation.spawn_enemy("runner_veteran")
	battle.simulation.build(12, "banner")
	battle.simulation.build(7, "arcane")
	for frame in range(420): battle._physics_process(1.0 / 60)
	var brute_view: RiggedActor3D = battle.enemy_views[brute.id]
	var veteran_view: RiggedActor3D = battle.enemy_views[runner.id]
	check(brute_view.model_path.ends_with("captain.glb") and brute_view.scale.x > 1.3, "Brute is a distinct larger skeletal actor")
	check(veteran_view.find_child("EliteArmor", true, false) != null and veteran_view.current_state == &"Run", "Veteran has visible equipment and its running animation")
	check(float(battle.simulation.buffs_for(battle.simulation.tower_on_pad(7)).haste) > 0, "Quarry layout offers real support coverage for its Arcane tower")
	check(battle.tower_views.has(battle.simulation.tower_on_pad(12).id), "Banner has an actual world display")
	battle.simulation.wave_index = 17
	battle._update_hud()
	await process_frame
	var header_rect: Rect2 = (battle._top_stats.get_parent() as Control).get_global_rect()
	check(header_rect.position.x >= 0 and header_rect.end.x <= root.get_visible_rect().size.x, "Long quarry title and final-wave preview stay inside the viewport")
	check(battle._next_wave.text.contains("Bruto") and battle._next_wave.text.contains("Xamã"), "Late-wave preview preserves tank and healer information")
	battle.queue_free()
	await process_frame
	print("P7 quarry world: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
