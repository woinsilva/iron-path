extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app: CampaignAppV2 = CampaignAppV2.new()
	root.add_child(app)
	current_scene = app
	for frame in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p10-menu.png")
	app._show_credits()
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p10-credits.png")
	var file: FileAccess = FileAccess.open("res://test-results/p10-godot-license.txt",FileAccess.WRITE)
	file.store_string(Engine.get_license_text())
	file.close()
	await app._audio.shutdown()
	quit()
