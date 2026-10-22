extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var app: CampaignAppV2 = CampaignAppV2.new()
	root.add_child(app)
	current_scene = app
	for index in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p3-menu.png")
	app._launch_stage()
	app.battle.set_physics_process(false)
	while app.battle._warming_up: await process_frame
	app.battle._select_pad(0)
	app.battle._purchase("archer")
	app.battle._select_pad(1)
	app.battle._purchase("cannon")
	app.battle._start_or_early()
	for index in range(1080):
		app.battle._physics_process(1.0 / 60.0)
		if index % 12 == 0: await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p3-battle.png")
	quit()
