extends SceneTree
var failures: int = 0
func check(value: bool, message: String) -> void:
	if value: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.get_node("SaveService").set("save_path","user://test_exported_candidate_only.json")
	var app: Node = load("res://scenes/campaign.tscn").instantiate()
	root.add_child(app)
	current_scene = app
	check(is_instance_valid(app.get("menu")),"Exported binary opens campaign with packaged JSON")
	app.call("_prepare_stage","res://data/campaign/stage_01.json")
	var confirm: Button = app.get_node("FormationLayer").find_child("FormationConfirm",true,false) as Button
	confirm.pressed.emit()
	await process_frame
	var battle: Node = app.get("battle")
	while bool(battle.get("_warming_up")): await process_frame
	battle.call("_select_pad",0)
	battle.call("_purchase","archer")
	check(int(battle.get("simulation").get("coins")) == 130,"Exported build creates a tower with real authored cost")
	battle.call("_select_pad",-1)
	if paused: battle.call("_toggle_pause")
	await process_frame
	root.go_back_requested.emit()
	check(paused,"Exported UI pauses through Back")
	await process_frame
	root.go_back_requested.emit()
	check(not paused,"Exported UI resumes through Back")
	for profile: String in ["economy","balanced","quality"]:
		battle.call("apply_graphics_profile",profile)
		await process_frame
	check(is_instance_valid(battle.get("diorama")),"Three graphics profiles retain the loaded 3D field")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Dev/TowerDefense/test-results/p10-windows-exported-field.png")
	app.call("_restart_stage")
	for frame in range(8): await process_frame
	check(int(app.get("battle").get("simulation").get("coins")) == 200,"Exported restart releases the old field and restores preparation")
	app.call("_show_menu")
	await process_frame
	app.call("_show_credits")
	await process_frame
	check(app.has_node("CreditsLayer"),"Packaged license text opens in exported credits")
	print("EXPORTED_CANDIDATE_CHECKS ", "PASS" if failures == 0 else "FAIL")
	app.call("_request_quit")
