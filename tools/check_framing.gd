extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_12.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.allowed_towers = (battle.stage.allowed_towers as Array).slice(0,5)
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	await process_frame
	for config: Vector2 in [Vector2(27,0),Vector2(30.5,0),Vector2(30.5,-1.2),Vector2(30.5,1.2)]:
		battle.diorama.camera.size = config.x
		battle.diorama.camera.v_offset = config.y
		var low: float = 9999
		var high: float = 0
		for pad: Vector3 in battle.simulation.pads:
			var projected: Vector2 = battle.diorama.camera.unproject_position(pad)
			low = minf(low, projected.y)
			high = maxf(high, projected.y)
		print("CAMERA ",config," padY ",low," ",high," viewport ",root.get_visible_rect())
	battle.queue_free()
	await process_frame
	quit()
