extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var app: CampaignAppV2 = CampaignAppV2.new()
	root.add_child(app)
	current_scene = app
	for index in range(12): await process_frame
	await RenderingServer.frame_post_draw
	var suffix: String = "wide" if root.size.x > 1400 else "standard"
	root.get_texture().get_image().save_png("res://test-results/p4-menu-" + suffix + ".png")
	app._prepare_stage("res://data/campaign/arsenal_lab.json" if "--arsenal" in OS.get_cmdline_user_args() else "res://data/campaign/stage_03.json")
	for index in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(("res://test-results/p5-formation-" if "--arsenal" in OS.get_cmdline_user_args() else "res://test-results/p4-formation-") + suffix + ".png")
	quit()
