extends SceneTree
## Captures enemies arriving through the entrance (dust) and falling/sinking when defeated.
## godot --path . --resolution 1280x720 -s res://tools/capture_npc.gd -- --stage=2
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var stage_index: int = 2
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="): stage_index = int(argument.trim_prefix("--stage="))
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_%02d.json" % stage_index
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.starting_coins = 5000 # Art fixture; never a campaign reference.
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	while battle._warming_up: await process_frame
	battle.apply_graphics_profile("quality")
	for pad in range(4): battle.simulation.build(pad, str(battle.stage.allowed_towers[pad % battle.stage.allowed_towers.size()]))
	await _advance(battle, 500)
	battle.simulation.start_first_wave()
	await _advance(battle, 200)
	await _save("res://test-results/npc-arrival.png")
	var corpse_seen: bool = false
	for step in range(200):
		await _advance(battle, 10)
		if not battle._corpses.is_empty() and float(battle._corpses[0].remaining) < BattleViewV2.CORPSE_SINK:
			corpse_seen = true
			break
	await _save("res://test-results/npc-defeat.png")
	print("corpse captured: ", corpse_seen)
	battle.queue_free()
	await process_frame
	quit()

func _advance(battle: BattleViewV2, ticks: int) -> void:
	for tick in range(ticks):
		battle._physics_process(1.0 / 60)
		if tick % 2 == 0: await process_frame

func _save(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
