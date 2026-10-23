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
	var catalog: Dictionary = BattleSimV2.load_catalog()
	check(str(catalog.towers.cannon.name) == "Canhão" and str(catalog.towers.frost.name) == "Cristal Gélido", "Campaign catalog preserves Portuguese UTF-8 accents")
	var total_waves: int = 0
	for index in range(1, 4):
		var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_%02d.json" % index)
		var sim: BattleSimV2 = StageSessionV2.create(stage)
		total_waves += sim.waves.size()
		var layout_clear: bool = true
		for pad: Vector3 in sim.pads:
			layout_clear = layout_clear and pad.distance_to(sim.routes[0].get_closest_point(pad)) >= 2.2
		check(layout_clear, "Stage %d keeps building pads off the road" % index)
	check(total_waves == 36, "Alpha contains thirty-six authored waves")
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage = StageSessionV2.read_stage("res://data/campaign/stage_03.json")
	battle.stage.starting_coins = 2000 # Explicit isolated rendering fixture, not a campaign strategy.
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	await process_frame
	var ui_fits: bool = true
	for button: Button in battle._purchase_buttons.values():
		ui_fits = ui_fits and button.get_global_rect().end.x <= root.get_visible_rect().size.x and button.size.y >= 96
	ui_fits = ui_fits and battle._start.get_global_rect().end.x <= root.get_visible_rect().size.x
	check(ui_fits, "Five-family purchase controls stay on screen with touch-sized buttons")
	var types: Array[String] = ["archer", "cannon", "frost", "venom", "anti_air"]
	for pad in range(types.size()): battle.simulation.build(pad, types[pad])
	for index in range(400): battle._physics_process(1.0 / 60)
	battle.simulation.upgrade(2)
	for index in range(400): battle._physics_process(1.0 / 60)
	var frost_display: Node3D = battle.tower_views[battle.simulation.tower_on_pad(2).id]
	var level_two_geometry: int = frost_display.get_node("LevelDecor").get_child_count()
	battle.simulation.upgrade(2)
	for index in range(500): battle._physics_process(1.0 / 60)
	check(battle.simulation.tower_on_pad(2).level == 3 and frost_display.get_node("LevelDecor").get_child_count() > level_two_geometry, "L3 adds real upgrade modules beyond L2 geometry")
	check(battle.tower_views.size() == 5, "Five families have actual 3D displays")
	check(battle.simulation.routes.size() == 2, "Air and ground use separate authored routes")
	var flyer: SimEnemyV2 = battle.simulation.spawn_enemy("flyer", 1)
	var crawler: SimEnemyV2 = battle.simulation.spawn_enemy("swarm")
	battle._physics_process(1.0 / 60)
	check(battle.enemy_views[flyer.id] is FlyingActorV2, "Airborne unit has a distinct volumetric winged model")
	check(battle.enemy_views[crawler.id] is CrawlerActorV2, "Crawler has a distinct jointed ground model")
	var flying_view: RiggedActor3D = battle.enemy_views[flyer.id]
	check(flying_view.position.y > 2, "Airborne presentation preserves real altitude")
	battle.simulation.damage(flyer.id, 10000)
	# Corpses lie and sink for BattleViewV2.CORPSE_SECONDS before returning to the pool.
	for index in range(ceili(BattleViewV2.CORPSE_SECONDS * 60) + 10): battle._physics_process(1.0 / 60)
	var replacement: SimEnemyV2 = battle.simulation.spawn_enemy("flyer", 1)
	battle._physics_process(1.0 / 60)
	check(battle.enemy_views[replacement.id] == flying_view and not flying_view.dead, "Pool reuses the correct family and resets death state")
	var ground: SimEnemyV2 = battle.simulation.spawn_enemy("grunt")
	var airborne: SimEnemyV2 = battle.simulation.spawn_enemy("flyer", 1)
	ground.position = Vector3.ZERO
	airborne.position = Vector3(0, 2.2, 0)
	var cannon: SimTowerV2 = battle.simulation.tower_on_pad(1)
	battle.simulation._release(cannon, ground)
	var shot: Dictionary = battle.simulation.projectiles.values().back()
	shot.position = Vector3.ZERO
	battle.simulation._update_projectiles()
	check(airborne.health == airborne.maximum_health and ground.health < ground.maximum_health, "Ground splash cannot damage airborne targets in the same XZ area")
	battle.simulation.projectiles.clear()
	battle._sync_projectiles()
	var archer: SimTowerV2 = battle.simulation.tower_on_pad(0)
	battle.simulation._release(archer, ground)
	battle._sync_projectiles()
	var first_arrow: Node3D = battle.projectile_views.values()[0]
	battle.simulation.projectiles.clear()
	battle._sync_projectiles()
	check(not first_arrow.visible, "Resolved projectile returns to a hidden pool")
	battle.simulation._release(archer, ground)
	battle._sync_projectiles()
	check(battle.projectile_views.values()[0] == first_arrow and first_arrow.visible, "Next projectile reuses the same family model")
	battle._make_impact({"position": Vector3.ZERO, "splash": 1.2, "family": "cannon"})
	var first_impact: MeshInstance3D = battle._effects.back().node
	battle._physics_process(0.2)
	battle._make_impact({"position": Vector3.ZERO, "splash": 1.2, "family": "cannon"})
	check(battle._effects.back().node == first_impact and first_impact.scale == Vector3.ONE, "Impact pool resets scale before reuse")
	battle.queue_free()
	await process_frame
	print("P4 alpha integration: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
