extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func tick(battle: BattleViewV2, count: int) -> void:
	for index in range(count): battle._physics_process(1.0 / 60)
func run() -> void:
	for branch: String in ["A", "B"]:
		var battle: BattleViewV2 = BattleViewV2.new()
		battle.stage_path = "res://data/campaign/arsenal_lab.json"
		root.add_child(battle)
		current_scene = battle
		battle.set_physics_process(false)
		while battle._warming_up: await process_frame
		for pad in range(8): battle.simulation.build(pad, str(battle.stage.allowed_towers[pad]))
		tick(battle, 500)
		for pad in range(8): battle.simulation.upgrade(pad)
		tick(battle, 600)
		for pad in range(8): battle.simulation.upgrade(pad)
		tick(battle, 700)
		battle._select_pad(0)
		for index in range(5): await process_frame
		if branch == "A":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test-results/p5-branches.png")
		for pad in range(8): battle.simulation.upgrade(pad, branch)
		tick(battle, 850)
		for pad in range(8): battle.simulation.upgrade(pad)
		tick(battle, 1100)
		for index in range(5):
			var air: SimEnemyV2 = battle.simulation.spawn_enemy("flyer", 1)
			air.distance = 12 + index * 1.1
			air.health = 10000
			air.maximum_health = 10000
			var swarm: SimEnemyV2 = battle.simulation.spawn_enemy("swarm")
			swarm.distance = 14 + index * 0.7
			swarm.health = 10000
			swarm.maximum_health = 10000
		for pair: Array in [["dummy_armored", 18], ["dummy_resistant", 23], ["dummy_brute", 28]]:
			var dummy: SimEnemyV2 = battle.simulation.spawn_enemy(str(pair[0]))
			dummy.distance = float(pair[1])
			dummy.health = 10000
			dummy.maximum_health = 10000
		for index in range(100):
			battle._physics_process(1.0 / 60)
			await process_frame
		battle._hint.text = "Galeria de inspeção: oito famílias L5" + branch + ", recursos e HP de fixture. Não é uma partida da campanha."
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/p5-arsenal-" + branch + ".png")
		battle.diorama.camera.size = 15
		battle.diorama.camera.position = Vector3(5, 22, 19)
		battle.diorama.camera.look_at(Vector3(5, 0, 0))
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/p5-detail-" + branch + ".png")
		battle.queue_free()
		await process_frame
	quit()
