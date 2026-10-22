extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var service: SaveServiceNode = SaveServiceNode.new()
	service.save_path = "user://test_campaign_save.json"
	for suffix: String in ["", ".tmp", ".backup", ".corrupt"]:
		if FileAccess.file_exists(service.save_path + suffix):
			DirAccess.remove_absolute(service.save_path + suffix)
	var data: Dictionary = service.load_game()
	check(data.schema_version == 2 and data.progress.campaign.is_empty(), "New campaign has versioned defaults")
	check(service.save_game(data), "Initial atomic save succeeds")
	check(service.load_game().schema_version == 2, "JSON numeric schema roundtrip is accepted")
	var result: Dictionary = {"state": BattleSimV2.State.VICTORY, "stage": "stage_01", "difficulty": "normal", "stars": 3, "ticks": 20000}
	check(service.record_battle(data, result), "Victory writes campaign progress")
	result.stars = 1
	result.ticks = 22000
	check(service.record_battle(data, result), "Later weaker victory can be recorded")
	var loaded: Dictionary = service.load_game()
	check(loaded.progress.campaign["stage_01:normal"].stars == 3 and loaded.progress.campaign["stage_01:normal"].best_ticks == 20000, "Best stars and time never regress")
	var malformed: Dictionary = loaded.duplicate(true)
	malformed.progress.campaign["stage_01:normal"].best_ticks = []
	check(not service._validate_data(malformed), "Malformed record time is rejected before numeric conversion")
	malformed.progress.campaign["stage_01:normal"].best_ticks = 0
	check(not service._validate_data(malformed), "Nonpositive record time cannot silently replace a valid best result")
	result.state = BattleSimV2.State.DEFEAT
	check(not service.record_battle(data, result), "Defeat does not unlock campaign progress")
	var file: FileAccess = FileAccess.open(service.save_path, FileAccess.WRITE)
	file.store_string("damaged save")
	file.close()
	check(service.load_game().progress.campaign["stage_01:normal"].stars == 3, "Damaged primary recovers valid backup")
	check(FileAccess.file_exists(service.save_path + ".corrupt"), "Corrupt source is preserved for diagnosis")
	var legacy: Dictionary = {"schema_version": 1.0, "progress": {"stars": {"old_map": 2}}, "settings": {}}
	check(service._migrate(legacy).progress.stars.old_map == 2, "Migration preserves legacy progress")
	legacy.schema_version = 99
	check(not service._validate_data(legacy), "Unknown future schema is rejected")
	var final_result: Dictionary = {"state": BattleSimV2.State.VICTORY, "stage":"stage_12", "difficulty":"normal", "stars":3, "ticks":88860}
	check(service.record_battle(data, final_result), "Final campaign result persists through the same atomic save path")
	check(service.load_game().progress.campaign["stage_12:normal"].stars == 3, "Reload preserves the completed final stage and its best result")
	service.free()
	var app: CampaignAppV2 = CampaignAppV2.new()
	root.add_child(app)
	current_scene = app
	var defaults_service: SaveServiceNode = SaveServiceNode.new()
	app.progress = defaults_service._create_default_data()
	defaults_service.free()
	check(app.stage_unlocked(1) and not app.stage_unlocked(2), "Campaign starts with only the first stage unlocked")
	app.progress.progress.campaign["stage_01:adventure"] = {"stars": 1, "best_ticks": 20000}
	check(app.stage_unlocked(2) and not app.stage_unlocked(3), "Victory unlocks exactly the next stage across difficulty choices")
	app._launch_stage()
	check(app.battle != null and app.battle.simulation.wave_index == 0, "Campaign menu opens preparation scene")
	app.battle.apply_graphics_profile("economy")
	check(not app.battle.diorama.sunlight.shadow_enabled and is_equal_approx(root.scaling_3d_scale, 0.7), "Economy profile reduces render scale and shadows")
	app.battle.apply_graphics_profile("quality")
	check(app.battle.diorama.sunlight.shadow_enabled and root.msaa_3d == Viewport.MSAA_4X, "Quality profile restores shadows and four-sample antialiasing")
	app._restart_stage()
	check(app.battle.simulation.coins == 200 and app.battle.simulation.ticks == 0, "Retry resets battle instead of returning to menu")
	app._show_menu()
	check(app.battle == null and not paused and Engine.time_scale == 1.0, "Return to map restores application state")
	app._prepare_stage("res://data/campaign/stage_03.json")
	var formation_layer: CanvasLayer = app.get_node("FormationLayer") as CanvasLayer
	var confirm: Button = formation_layer.find_child("FormationConfirm", true, false) as Button
	var venom: Button = formation_layer.find_child("Formation_venom", true, false) as Button
	check(not confirm.disabled, "Formation defaults to the available five families")
	venom.pressed.emit()
	check(confirm.disabled, "Incomplete formation cannot enter battle")
	venom.pressed.emit()
	check(not confirm.disabled, "Completing formation re-enables battle entry")
	formation_layer.queue_free()
	await process_frame
	app._prepare_stage("res://data/campaign/arsenal_lab.json")
	formation_layer = app.get_node("FormationLayer") as CanvasLayer
	confirm = formation_layer.find_child("FormationConfirm", true, false) as Button
	venom = formation_layer.find_child("Formation_venom", true, false) as Button
	var arcane_choice: Button = formation_layer.find_child("Formation_arcane", true, false) as Button
	check(arcane_choice.disabled and not confirm.disabled, "Eight-family formation enforces the five-slot limit")
	venom.pressed.emit()
	check(not arcane_choice.disabled and confirm.disabled, "Removing a family opens a slot for a new role")
	arcane_choice.pressed.emit()
	check(not confirm.disabled and arcane_choice.text.begins_with("✓"), "Player can replace one of five families with an unlocked alternative")
	formation_layer.queue_free()
	await process_frame
	app._show_guide()
	var guide: CanvasLayer = app.get_node("GuideLayer") as CanvasLayer
	check(guide.find_child("EnemyGuide_boss_captain", true, false) != null and guide.find_child("EnemyGuide_armored", true, false) != null, "Compendium includes the captain and guardian")
	check(guide.find_child("EnemyGuide_dummy_armored", true, false) == null, "Compendium excludes internal laboratory targets")
	app.progress.progress.campaign["stage_04:normal"] = {"stars": 2, "best_ticks": 74223}
	check(app.stage_unlocked(5), "Defeating the first biome opens the next region prerequisite")
	var challenges: Array = StageSessionV2.read_stage("res://data/campaign/challenges.json").challenges
	check(challenges.size() == 3 and not app.challenge_completed(challenges[0]), "Each biome offers an optional perfect-defense replay without granting unearned completion")
	app.progress.progress.campaign["stage_04:normal"].stars = 3
	check(app.challenge_completed(challenges[0]), "Optional challenge reads the actual best three-star result")
	app.difficulty = "veteran"
	check(not app.challenge_completed(challenges[0]), "Optional replay records remain specific to the selected difficulty")
	app.difficulty = "normal"
	app.progress.progress.campaign["stage_08:normal"] = {"stars": 1, "best_ticks": 74000}
	check(app.stage_unlocked(9) and not app.stage_unlocked(10), "Defeating the Colossus opens only the first swamp stage")
	app.progress.progress.campaign["stage_12:normal"] = {"stars": 3, "best_ticks": 88000}
	check(app.stage_unlocked(13) and app.challenge_completed(challenges[2]), "Final guardian completion exposes the ending and final biome challenge result")
	app._show_menu()
	await process_frame
	check(app.menu.find_child("Challenge_vale_perfect", true, false) != null and app.menu.find_child("Challenge_swamp_perfect", true, false) != null, "Unlocked optional replays appear as actionable menu controls")
	app.queue_free()
	await process_frame
	for suffix: String in ["", ".tmp", ".backup", ".corrupt"]:
		if FileAccess.file_exists("user://test_campaign_save.json" + suffix):
			DirAccess.remove_absolute("user://test_campaign_save.json" + suffix)
	print("P3 campaign/save: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
