extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + name + ".png")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_08.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.allowed_towers = ["cannon", "arcane", "frost", "anti_air", "banner"]
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	while battle._warming_up: await process_frame
	var boss: SimEnemyV2 = battle.simulation.spawn_enemy("boss_colossus", 0, 22)
	battle.simulation.spawn_enemy("standardbearer", 0, 14)
	battle.simulation.spawn_enemy("flyer_heavy", 1, 19)
	battle.simulation.spawn_enemy("shieldbearer", 0, 17)
	for frame in range(241):
		battle._physics_process(1.0 / 60)
		await process_frame
	battle._hint.text = "Inspeção P7: Colosso, aura e vespa pesada posicionados por fixture."
	await capture("p7-colossus-warning")
	for frame in range(120):
		battle._physics_process(1.0 / 60)
		await process_frame
	battle.simulation.damage(boss.id, 120, "pure")
	battle._physics_process(1.0 / 60)
	await capture("p7-colossus-barrier")
	var clear_layout: bool = true
	for pad: Vector3 in battle.simulation.pads:
		for route_id in [0, 2]: clear_layout = clear_layout and battle.simulation.routes[route_id].get_closest_point(pad).distance_to(pad) >= 2.2
	print("FORGE_BASES_CLEAR ", clear_layout, " BRIDGES ", battle.diorama.bridge_centers.size())
	battle.queue_free()
	await process_frame
	quit()
