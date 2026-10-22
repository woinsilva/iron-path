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
func tick(battle: BattleViewV2, count: int) -> void:
	for index in range(count): battle._physics_process(1.0 / 60)
func promote(battle: BattleViewV2, pad: int, branch: String) -> void:
	battle.simulation.upgrade(pad, branch)
	tick(battle, battle.simulation.tower_on_pad(pad).work_ticks)
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/arsenal_lab.json"
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	var types: Array = battle.stage.allowed_towers
	for pad in range(types.size()): battle.simulation.build(pad, str(types[pad]))
	tick(battle, 500)
	for pad in range(types.size()): battle.simulation.upgrade(pad)
	tick(battle, 600)
	for pad in range(types.size()): battle.simulation.upgrade(pad)
	tick(battle, 700)
	check(battle.tower_views.size() == 8, "All eight families have a volumetric display")
	check(battle.tower_views[battle.simulation.tower_on_pad(5).id] is BallistaDisplayV2, "Ballista has its own aiming and recoil model")
	check(battle.tower_views[battle.simulation.tower_on_pad(7).id] is BannerDisplayV2, "Support has an animated cloth standard")
	battle._select_pad(0)
	check((battle._branch_buttons.A as Button).visible and (battle._branch_buttons.B as Button).visible and not battle._upgrade.visible, "L3 presents two exclusive branch choices")
	var tower: SimTowerV2 = battle.simulation.tower_on_pad(0)
	(battle._branch_buttons.B as Button).pressed.emit()
	tick(battle, tower.work_ticks)
	check(tower.branch == "B" and tower.level == 4, "Branch button starts and completes the selected specialization")
	check((battle.tower_views[tower.id] as Node3D).has_node("LevelDecor/BranchModule"), "Specialization creates its own visible equipment module")
	battle._priority.pressed.emit()
	check(tower.priority == "last", "Priority button changes authoritative targeting")
	battle._toggle_pause()
	battle._priority.pressed.emit()
	check(tower.priority == "last", "Paused battle rejects targeting changes")
	battle._toggle_pause()
	promote(battle, 1, "A")
	promote(battle, 1, "")
	var cannon: SimTowerV2 = battle.simulation.tower_on_pad(1)
	var dummy: SimEnemyV2 = battle.simulation.spawn_enemy("dummy_brute")
	dummy.distance = 9
	battle._physics_process(1.0 / 60)
	battle.simulation._release(cannon, dummy)
	battle._handle_events(battle.simulation.consume_events())
	battle._sync_projectiles()
	var shot: Dictionary = battle.simulation.projectiles.values().back()
	var projectile: Node3D = battle.projectile_views[int(shot.id)]
	var emitter: Vector3 = projectile.get_meta("emitter")
	check(emitter.is_equal_approx((battle.tower_views[cannon.id] as CannonDisplay3D).muzzle_position()), "Projectile originates at the actual moving barrel muzzle")
	check(battle._impact_markers.has(int(shot.id)), "Mortar shows an announced ground impact marker")
	var marker: Node3D = battle._impact_markers[int(shot.id)]
	shot.position = shot.impact_point
	battle.simulation._update_projectiles()
	battle._handle_events(battle.simulation.consume_events())
	battle._sync_projectiles()
	check(not marker.visible and not battle._impact_markers.has(int(shot.id)), "Impact marker retires when its projectile resolves")
	promote(battle, 2, "A")
	promote(battle, 2, "")
	var frost: SimTowerV2 = battle.simulation.tower_on_pad(2)
	dummy = battle.simulation.spawn_enemy("dummy_brute")
	dummy.distance = 12
	battle._physics_process(1.0 / 60)
	battle.simulation._release(frost, dummy)
	shot = battle.simulation.projectiles.values().back()
	shot.position = dummy.position
	battle.simulation._update_projectiles()
	battle._sync_fields()
	check(not battle._field_views.is_empty(), "Persistent frost field has a matching ground visual")
	battle.simulation.fields.clear()
	battle._sync_fields()
	check(battle._field_views.is_empty() and not battle._area_pool.is_empty(), "Expired field visuals are pooled")
	var banner: BannerDisplayV2 = battle.tower_views[battle.simulation.tower_on_pad(7).id]
	await process_frame
	await process_frame
	await process_frame
	var phase: float = float(banner._cloth.get_shader_parameter("phase"))
	check(phase > 0, "Cloth animation advances before pause")
	battle._toggle_pause()
	await process_frame
	await process_frame
	check(is_equal_approx(float(banner._cloth.get_shader_parameter("phase")), phase), "Pausing freezes cloth simulation and shader phase")
	battle._toggle_pause()
	battle.queue_free()
	await process_frame
	print("P5 arsenal world: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
