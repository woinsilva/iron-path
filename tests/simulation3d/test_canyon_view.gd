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
	battle.stage_path = "res://data/campaign/stage_05.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.allowed_towers = ["archer", "cannon", "frost", "anti_air", "arcane"]
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	check(battle.diorama.all_ground_routes.size() == 2 and battle.diorama.bridge_centers.size() == 2, "Twin bridges draw both ground entries with exactly two unique crossings")
	var clear_layout: bool = true
	for pad: Vector3 in battle.simulation.pads:
		for route_id in [0, 2]: clear_layout = clear_layout and battle.simulation.routes[route_id].get_closest_point(pad).distance_to(pad) >= float(battle.simulation.placement_rules.road_clearance)
		clear_layout = clear_layout and absf(pad.x) >= 2.2
	check(clear_layout, "Every build base clears both roads and the river")
	check(battle._next_wave.text.contains("Ponte Norte"), "Upcoming wave announces its entry before spawning")
	var healer: SimEnemyV2 = battle.simulation.spawn_enemy("healer", 2)
	var ally: SimEnemyV2 = battle.simulation.spawn_enemy("grunt", 2)
	ally.health = 20
	battle._physics_process(1.0 / 60)
	var actor: RiggedActor3D = battle.enemy_views[healer.id]
	check(actor.model_path.ends_with("skeleton_mage.glb") and actor.skeleton.get_bone_count() >= 23, "Shaman uses its imported animated skeleton mage model")
	battle.simulation.ticks = 240
	battle._physics_process(1.0 / 60)
	check(ally.health == 30 and not battle._effects.is_empty(), "Healing creates an independent visible effect and restores health")
	var pulse: MeshInstance3D = battle._effects.back().node as MeshInstance3D
	check(pulse.mesh.get_surface_count() == 2 and str(pulse.get_meta("pool_key")) == "heal", "Healing uses a cross silhouette distinct from poison impacts")
	for frame in range(30): battle._physics_process(1.0 / 60)
	check(not pulse.visible, "Healing effect returns to a hidden reusable pool")
	battle.queue_free()
	await process_frame
	print("P7 canyon world: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
