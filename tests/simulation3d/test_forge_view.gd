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
	battle.stage_path = "res://data/campaign/stage_08.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.allowed_towers = ["cannon", "arcane", "frost", "anti_air", "banner"]
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	var clear_layout: bool = true
	for pad: Vector3 in battle.simulation.pads:
		for route_id in [0, 2]: clear_layout = clear_layout and battle.simulation.routes[route_id].get_closest_point(pad).distance_to(pad) >= 2.2
	check(clear_layout and battle.diorama.bridge_centers.size() == 2, "Forge offers clear building sites and two unique ground crossings")
	var boss: SimEnemyV2 = battle.simulation.spawn_enemy("boss_colossus", 0, 22)
	var source: SimEnemyV2 = battle.simulation.spawn_enemy("standardbearer", 0, 14)
	var heavy: SimEnemyV2 = battle.simulation.spawn_enemy("flyer_heavy", 1)
	var light: SimEnemyV2 = battle.simulation.spawn_enemy("flyer", 1)
	for frame in range(241): battle._physics_process(1.0 / 60)
	var colossus: ColossusActorV2 = battle.enemy_views[boss.id] as ColossusActorV2
	check(colossus != null and colossus.skeleton.get_bone_count() == 23 and colossus.current_state == &"Walk", "Colossus stone body follows a real animated skeletal rig")
	check(colossus.core_material.emission_energy_multiplier > 1 and battle._boss_label.text.contains("Preparando Barreira"), "Forge windup changes the core emission and explicit boss HUD")
	var standard: RiggedActor3D = battle.enemy_views[source.id]
	check(standard._flag_material != null and battle._enemy_areas.has(source.id), "Enemy standard carries animated cloth and its actual aura ring")
	var heavy_view: FlyingActorV2 = battle.enemy_views[heavy.id] as FlyingActorV2
	var light_view: FlyingActorV2 = battle.enemy_views[light.id] as FlyingActorV2
	check(heavy_view != null and heavy_view.model.get_child_count() > light_view.model.get_child_count(), "Heavy wasp is airborne and adds visible armor geometry")
	for frame in range(120): battle._physics_process(1.0 / 60)
	check(boss.shield == 300 and str((battle._enemy_areas[boss.id] as Node3D).get_meta("pool_key")) == "shield", "Activation switches the warning to the blue barrier signal")
	battle.simulation.damage(boss.id, 120, "pure")
	battle._physics_process(1.0 / 60)
	check(boss.shield == 180 and battle._boss_health.value == boss.maximum_health, "Boss health and temporary shield remain separate in the actual HUD")
	battle.simulation.damage(boss.id, 180, "pure")
	battle._physics_process(1.0 / 60)
	check(boss.shield == 0 and not battle._enemy_areas.has(boss.id) and battle._hint.text.contains("Barreira rompida"), "Breaking the barrier immediately clears its world signal and announces the opening")
	var summoned: SimEnemyV2 = battle.simulation.spawn_enemy("swarm", 0, boss.distance, boss.id)
	battle._physics_process(1.0 / 60)
	check((battle.enemy_views[summoned.id] as CrawlerActorV2)._summon_rune.visible and summoned.reward == 0, "Summoned crawler carries a visible no-reward seal")
	battle._toggle_pause()
	var before: int = battle.simulation.ticks
	await create_timer(0.05, true).timeout
	check(battle.simulation.ticks == before and not colossus.can_process(), "Pause freezes the boss actor and ability clock")
	battle._toggle_pause()
	battle.simulation.damage(boss.id, 100000, "pure")
	battle._physics_process(1.0 / 60)
	check(not battle._boss_panel.visible and not battle._enemy_areas.has(boss.id), "Boss death clears its dedicated bar and area signal")
	battle.queue_free()
	await process_frame
	print("P7 forge world: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
