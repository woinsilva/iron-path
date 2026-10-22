extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var scene: Node = load("res://scenes/lab3d/quality_lab.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for index in range(90):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p1-lab.png")
	var diorama: Diorama3D = scene.diorama
	diorama.camera.size = 11.0
	diorama.camera.position = Vector3(-8, 12, 11)
	diorama.camera.look_at(scene.actors[1].position + Vector3(0, 0.7, 0))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p1-detail.png")
	quit()
