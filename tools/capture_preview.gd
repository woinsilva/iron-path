extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var battle: Node = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	await process_frame
	for pad in battle.get_node("MapRoot/Map01/Pads").get_children():
		battle._on_pad_selected(pad)
		pad.finish_build()
	battle.wave_manager.start_wave()
	battle.wave_manager.enemies_to_spawn = 0
	for index in range(5):
		battle.wave_manager.spawn_enemy()
		var enemies: Array[Node] = get_nodes_in_group("enemies")
		var enemy: Enemy = enemies.back() as Enemy
		enemy.progress = 200.0 + index * 170.0
		if index % 2 == 0:
			enemy.health_component.take_damage(5.0)
	paused = true
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/preview.png")
	if "--motion" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://test-results/motion")
		paused = false
		for index in range(60):
			await process_frame
			await RenderingServer.frame_post_draw
			if index % 2 == 0:
				root.get_texture().get_image().save_png("res://test-results/motion/frame_%03d.png" % (index >> 1))
	quit()
