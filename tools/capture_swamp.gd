extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	var final_guardian: bool = "--ruin" in OS.get_cmdline_user_args()
	battle.stage_path = "res://data/campaign/stage_12.json" if final_guardian else "res://data/campaign/stage_09.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.allowed_towers = ["cannon", "bleed", "frost", "banner", "anti_air"]
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	while battle._warming_up: await process_frame
	for i in range(6): battle.simulation.spawn_enemy("resistant", 0, 15 + i * 3)
	if final_guardian: battle.simulation.spawn_enemy("boss_ruin", 0, 40)
	for frame in range(120):
		battle._physics_process(1.0 / 60)
		await process_frame
	battle._hint.text = "Inspeção P9: cena preparada para revisar modelos e mapa; não é partida real."
	await process_frame
	await process_frame
	print("CONTEXT_RECT ",battle._context.get_global_rect(), " COLUMN ",battle._context.get_parent().get_global_rect(), " HINT_MIN ",battle._hint.get_combined_minimum_size())
	print("CAPTURE_VIEWPORT ", root.get_visible_rect(), " BOTTOM ", battle._context.get_parent().get_parent().get_global_rect(), " ACTION_MIN ",battle._start.get_parent().get_combined_minimum_size())
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p9-guardian.png" if final_guardian else "res://test-results/p9-ruins.png")
	battle.queue_free()
	await process_frame
	quit()
