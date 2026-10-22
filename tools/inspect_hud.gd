extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_12.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.allowed_towers = ["cannon","bleed","frost","banner","anti_air"]
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	await process_frame
	battle.simulation.spawn_enemy("boss_ruin",0,40)
	battle._physics_process(1.0/60)
	await process_frame
	await process_frame
	print("BOTTOM ",battle._context.get_parent().get_parent().get_global_rect(), " ACTION_MIN ", battle._start.get_parent().get_combined_minimum_size())
	for key: String in battle._purchase_buttons:
		var button: Button = battle._purchase_buttons[key]
		print("BUTTON ",key," rect ",button.get_global_rect()," minimum ",button.get_combined_minimum_size())
	battle.queue_free()
	await process_frame
	quit()
