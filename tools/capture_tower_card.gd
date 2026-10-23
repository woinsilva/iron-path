extends SceneTree
## Captures the selected-tower card (stats, next level and actions) on a mid-campaign stage.
## godot --path . --resolution 1280x720 -s res://tools/capture_tower_card.gd
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_06.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.starting_coins = 5000 # Art fixture; never a campaign reference.
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	while battle._warming_up: await process_frame
	battle.simulation.build(7, "frost")
	for tick in range(400): battle._physics_process(1.0 / 60)
	battle.simulation.upgrade(7)
	for tick in range(900): battle._physics_process(1.0 / 60)
	battle._select_pad(7)
	battle._toggle_speed()
	battle._toggle_speed()
	battle._update_hud()
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/tower-card.png")
	print("speed ", Engine.time_scale)
	battle.queue_free()
	await process_frame
	quit()
