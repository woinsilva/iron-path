extends SceneTree
## One tower of each level side by side (L1-L6) for art review of the evolution marks.
## godot --path . --resolution 1600x700 -s res://tools/capture_tower_levels.gd -- --family=cannon
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var family: String = "cannon"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--family="): family = argument.trim_prefix("--family=")
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_09.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.starting_coins = 99999 # Art fixture; never a campaign reference.
	battle.stage.allowed_towers = [family]
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	while battle._warming_up: await process_frame
	battle.apply_graphics_profile("quality")
	var spots: Array[Vector3] = []
	for z: float in [-1.5, 0.0, 1.5, -3.0, 3.0, -4.5, 4.5]:
		for x in range(-16, 14):
			var spot: Vector3 = Vector3(x, 0, z)
			var spaced: bool = true
			for other: Vector3 in spots: spaced = spaced and other.distance_to(spot) >= 4.0
			if spots.size() < 6 and spaced and battle.simulation.can_build_at(spot): spots.append(spot)
	var pads: Array[int] = []
	for spot: Vector3 in spots: pads.append(battle.simulation.build_at(spot, family))
	for round_index in range(6):
		for tick in range(1500): battle._physics_process(1.0 / 60)
		for index in range(6):
			if pads[index] >= 0 and battle.simulation.tower_on_pad(pads[index]).level < index + 1: battle.simulation.upgrade(pads[index], "A" if battle.simulation.tower_on_pad(pads[index]).level == 3 else "")
	for tick in range(1500): battle._physics_process(1.0 / 60)
	await create_timer(2.5).timeout
	var levels: Array[int] = []
	for pad: int in pads: levels.append(battle.simulation.tower_on_pad(pad).level if pad >= 0 else -1)
	print("levels ", levels)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/tower-levels-%s.png" % family)
	battle.queue_free()
	await process_frame
	quit()
