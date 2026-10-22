extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var stage_index: int = 1
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="): stage_index = int(argument.trim_prefix("--stage="))
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_%02d.json" % stage_index
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.allowed_towers = (battle.stage.allowed_towers as Array).slice(0,5)
	if stage_index >= 5: battle.stage.allowed_towers = ["cannon","arcane","frost","anti_air","bleed"]
	battle.stage.starting_coins = 5000 # Explicit art fixture; never a legal campaign reference.
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	while battle._warming_up: await process_frame
	battle.apply_graphics_profile("quality")
	for pad in range(6): battle.simulation.build(pad,str(battle.stage.allowed_towers[pad % battle.stage.allowed_towers.size()]))
	for tick in range(500): battle._physics_process(1.0/60)
	for pad in range(6): battle.simulation.upgrade(pad)
	for tick in range(600): battle._physics_process(1.0/60)
	if int(battle.stage.max_level) >= 3:
		for pad in range(6): battle.simulation.upgrade(pad)
		for tick in range(720): battle._physics_process(1.0/60)
	var kinds: Array[String] = []
	for wave: Dictionary in battle.stage.waves:
		for group: Dictionary in wave.groups:
			if str(group.enemy) not in kinds: kinds.append(str(group.enemy))
	for index in range(mini(8,kinds.size())):
		var type_id: String = kinds[index]
		var airborne: bool = str(battle.simulation.catalog.enemies[type_id].layer) == "air"
		battle.simulation.spawn_enemy(type_id,1 if airborne and battle.simulation.routes.size()>1 else 0,5 + index % 3 * 3 if airborne else 10 + index * 4)
	for type_id: String in kinds:
		if bool(battle.simulation.catalog.enemies[type_id].get("boss",false)): battle.simulation.spawn_enemy(type_id,0,45)
	for frame in range(45):
		battle._physics_process(1.0/60)
		await process_frame
	battle._select_pad(-1)
	battle._hint.text = "Galeria de acabamento P9 · cenário preparado com recursos de inspeção; não é partida real."
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p9-polish-stage%02d.png" % stage_index)
	battle.queue_free()
	await process_frame
	quit()
