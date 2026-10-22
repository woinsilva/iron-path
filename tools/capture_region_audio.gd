extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var app: CampaignAppV2 = CampaignAppV2.new()
	root.add_child(app)
	current_scene = app
	# Inspection fixture: five selected families in memory, no progress/settings writes.
	app.progress.progress.formations["stage_06"] = ["cannon", "arcane", "frost", "anti_air", "banner"]
	app._launch_stage("res://data/campaign/stage_06.json")
	app.battle._show_help()
	for frame in range(90): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p7-region-help-wide.png")
	app.battle._dismiss_help()
	app._show_menu()
	for frame in range(30): await process_frame
	for index in range(12):
		app._audio.play_region("canyon" if index % 2 == 0 else "vale")
		await process_frame
	await app._request_quit()
