extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	var app: CampaignAppV2 = CampaignAppV2.new()
	root.add_child(app)
	current_scene = app
	var save: SaveServiceNode = SaveServiceNode.new()
	save.save_path = "user://test_release_flow_only.json"
	app._save = save
	app.progress = save._create_default_data()
	app._prepare_stage("res://data/campaign/stage_01.json")
	var confirm: Button = app.get_node("FormationLayer").find_child("FormationConfirm",true,false) as Button
	confirm.pressed.emit()
	await process_frame
	var battle: BattleViewV2 = app.battle
	battle.set_physics_process(false)
	check(save.load_game().progress.formations.stage_01.size() == 2, "Formation confirmation persists the actual selected families")
	battle._select_pad(0)
	battle._purchase("archer")
	battle._select_pad(1)
	battle._purchase("archer")
	check(battle.simulation.spent == 2 * int(battle.simulation.catalog.towers.archer.levels[0].cost), "Build controls spend authored money without test grants")
	for tick in range(180): battle.simulation.step()
	battle.simulation.consume_events()
	battle._start_or_early()
	check(save.load_game().tutorial_completed, "Starting the first defense records tutorial completion")
	var sim: BattleSimV2 = battle.simulation
	for tick in range(72000):
		if sim._terminal(): break
		if tick % 30 == 0:
			for pad in range(2,9):
				if sim.tower_on_pad(pad) == null: sim.build(pad,"archer" if pad % 3 != 2 else "cannon")
			for pad in range(9): sim.upgrade(pad)
		sim.step()
		var events: Array[Dictionary] = sim.consume_events()
		if sim._terminal(): battle._handle_events(events)
	check(sim.state == BattleSimV2.State.VICTORY and sim.wave_index == 10 and sim.spawned == StageSessionV2.authored_enemy_count(battle.stage), "Full first stage resolves all automatic waves through a legal defense")
	check(is_instance_valid(battle._result) and battle._result.visible, "Real terminal event opens the result interface")
	var loaded: Dictionary = save.load_game()
	check(int(loaded.progress.campaign["stage_01:normal"].stars) > 0, "Victory signal commits the result atomically to the isolated campaign save")
	check(app.stage_unlocked(2) and not app.stage_unlocked(3), "Winning the candidate flow unlocks exactly the next stage")
	app._restart_stage()
	app.battle.set_physics_process(false)
	check(app.battle.simulation.ticks == 0 and app.battle.simulation.wave_index == 0, "Retry begins a fresh preparation after victory")
	app._show_menu()
	await process_frame
	app.progress = save.load_game()
	check(app.stage_unlocked(2) and app.progress.tutorial_completed, "Returning to menu and reloading preserves progression and onboarding")
	app._save = root.get_node("SaveService") as SaveServiceNode
	save.free()
	app.queue_free()
	await process_frame
	print("P10 release flow: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
