extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage = StageSessionV2.read_stage("res://data/campaign/stage_03.json")
	battle.stage.starting_coins = 2000 # Visual inspection fixture, not a campaign run.
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	while battle._warming_up: await process_frame
	for index in range(20): await process_frame
	var families: Array[String] = ["archer", "cannon", "frost", "venom", "anti_air"]
	for index in range(families.size()): battle.simulation.build(index, families[index])
	for index in range(400): battle._physics_process(1.0 / 60)
	for index in range(5):
		var flyer: SimEnemyV2 = battle.simulation.spawn_enemy("flyer", 1)
		flyer.distance = 10 + index * 2
		var crawler: SimEnemyV2 = battle.simulation.spawn_enemy("swarm")
		crawler.distance = 8 + index * 2
	battle._select_pad(3)
	for index in range(120):
		battle._physics_process(1.0 / 60)
		await process_frame
	battle._hint.text = "Cenário de inspeção visual: 5 famílias, rota aérea dourada e modelos distintos."
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p4-gallery.png")
	battle.queue_free()
	await process_frame
	var orchard: BattleViewV2 = BattleViewV2.new()
	orchard.stage_path = "res://data/campaign/stage_02.json"
	root.add_child(orchard)
	current_scene = orchard
	for index in range(15): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/p4-orchard.png")
	quit()
