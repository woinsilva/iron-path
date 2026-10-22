extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	var fortress: bool = "--fortress" in OS.get_cmdline_user_args()
	var quarry: bool = "--quarry" in OS.get_cmdline_user_args()
	battle.stage_path = "res://data/campaign/stage_07.json" if fortress else ("res://data/campaign/stage_06.json" if quarry else "res://data/campaign/stage_05.json")
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.allowed_towers = ["archer", "cannon", "frost", "anti_air", "arcane"]
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	while battle._warming_up: await process_frame
	for frame in range(15): await process_frame
	for route in [0] if quarry or fortress else [0, 2]:
		var healer: SimEnemyV2 = battle.simulation.spawn_enemy("healer", route)
		healer.distance = 25
		for index in range(3):
			var guard: SimEnemyV2 = battle.simulation.spawn_enemy("shieldbearer" if fortress else "armored", route)
			guard.distance = 22 + index * 2
	if quarry:
		var brute: SimEnemyV2 = battle.simulation.spawn_enemy("brute")
		brute.distance = 35
		var runner: SimEnemyV2 = battle.simulation.spawn_enemy("runner_veteran")
		runner.distance = 40
	for enemy: SimEnemyV2 in battle.simulation.enemies.values():
		if enemy.type_id in ["armored", "shieldbearer"]: enemy.health -= 35
	for frame in range(241):
		battle._physics_process(1.0 / 60)
		await process_frame
	battle._hint.text = "Inspeção P7: modelos posicionados por fixture; não é partida real."
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p7-fortress.png" if fortress else ("res://test-results/p7-quarry.png" if quarry else "res://test-results/p7-twin-bridges.png"))
	var clear_layout: bool = true
	for pad: Vector3 in battle.simulation.pads:
		for route_id in [0] if quarry or fortress else [0, 2]:
			var clearance: float = battle.simulation.routes[route_id].get_closest_point(pad).distance_to(pad)
			if clearance < 2.2:
				clear_layout = false
				print("PAD_CLEARANCE ", pad, " ROUTE ", route_id, " ", clearance)
	print("HUD_BOUNDS ", battle._top_stats.get_parent().get_global_rect(), " PREVIEW ", battle._next_wave.get_global_rect(), " VIEWPORT ", root.get_visible_rect())
	print("P7 ground bases clear: ", clear_layout, " Bridges: ", battle.diorama.bridge_centers.size())
	battle.queue_free()
	await process_frame
	quit()
