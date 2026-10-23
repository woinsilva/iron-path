extends SceneTree
## Captures a tower evolving: halfway through the work and just after it completes.
## godot --path . --resolution 1280x720 -s res://tools/capture_evolution.gd
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_09.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.starting_coins = 9000 # Art fixture; never a campaign reference.
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	while battle._warming_up: await process_frame
	battle.apply_graphics_profile("quality")
	for pad in range(4): battle.simulation.build(pad, ["cannon", "arcane", "frost", "bleed"][pad])
	await _advance(battle, 400)
	for pad in range(4): battle.simulation.upgrade(pad)
	await _advance(battle, 300)
	await _save("res://test-results/evolution-working.png")
	await _advance(battle, 1200)
	for pad in range(4): battle.simulation.upgrade(pad)
	var tower: SimTowerV2 = battle.simulation.tower_on_pad(0)
	var remaining: int = tower.work_ticks - tower.work_elapsed
	await _advance(battle, remaining + 8)
	await _save("res://test-results/evolution-complete.png")
	battle.queue_free()
	await process_frame
	quit()

func _advance(battle: BattleViewV2, ticks: int) -> void:
	for tick in range(ticks):
		battle._physics_process(1.0 / 60)
		if tick % 4 == 0: await process_frame

func _save(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
