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
	save.save_path = "user://test_lifecycle_only.json"
	app._save = save
	app.progress = save._create_default_data()
	check(not quit_on_go_back, "Android Back remains under campaign control")
	app._prepare_stage("res://data/campaign/stage_01.json")
	app._prepare_stage("res://data/campaign/stage_01.json")
	var formations: int = 0
	for child: Node in app.get_children():
		if child.name == "FormationLayer": formations += 1
	check(formations == 1, "Repeated stage selection opens only one formation panel")
	app._handle_back()
	await process_frame
	check(app.get_node_or_null("FormationLayer") == null, "Back dismisses formation without closing campaign")
	app._show_credits()
	check(app.has_node("CreditsLayer"), "Credits include the bundled licenses and engine notice")
	app._handle_back()
	await process_frame
	check(not app.has_node("CreditsLayer"), "Back dismisses credits without quitting")
	app._launch_stage()
	var battle: BattleViewV2 = app.battle
	battle.set_physics_process(false)
	app._launch_stage()
	check(app.battle == battle, "Repeated confirmation cannot create a second live battle")
	root.go_back_requested.emit()
	check(paused and battle.simulation.paused, "Android Back pauses an active battle")
	var tick: int = battle.simulation.ticks
	battle.simulation.advance(1)
	check(battle.simulation.ticks == tick, "Pause prevents simulation advancement")
	await process_frame
	var escape: InputEventKey = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	check(not paused and not battle.simulation.paused, "Escape resumes a battle even while its world is paused")
	battle._show_forecast()
	await process_frame
	root.go_back_requested.emit()
	await process_frame
	check(not paused and not is_instance_valid(battle._help_layer), "Back closes forecast and restores the prior running state")
	battle._select_pad(0)
	await process_frame
	root.go_back_requested.emit()
	check(battle._selected_pad == -1 and not paused, "Back first dismisses selected build controls")
	app.progress.settings.music_volume = 37
	app._audio_save_timer.start()
	app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	battle.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(paused and battle.simulation.paused, "Mobile suspension freezes an active battle")
	check(app._audio_save_timer.is_stopped() and save.load_game().settings.music_volume == 37, "Suspension flushes pending audio preferences to the isolated save")
	await process_frame
	root.go_back_requested.emit()
	check(not paused, "Back resumes safely after mobile suspension")
	app._restart_stage()
	app.battle.set_physics_process(false)
	check(not paused and app.battle != battle and app.battle.simulation.ticks == 0, "Restart creates one clean battle with no residual pause")
	app._show_menu()
	await process_frame
	check(not paused and not is_instance_valid(app.battle), "Return to menu releases the battle and resets pause")
	app._save = root.get_node("SaveService") as SaveServiceNode
	save.free()
	app.queue_free()
	await process_frame
	print("P9 lifecycle: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
