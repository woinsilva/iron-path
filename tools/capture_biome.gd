extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + path + ".png")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_04.json"
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	while battle._warming_up: await process_frame
	for frame in range(15): await process_frame
	var captain: SimEnemyV2 = battle.simulation.spawn_enemy("boss_captain")
	captain.distance = 27
	var elite: SimEnemyV2 = battle.simulation.spawn_enemy("grunt_elite")
	elite.distance = 20
	for index in range(4):
		var guard: SimEnemyV2 = battle.simulation.spawn_enemy("armored")
		guard.distance = 24 + index * 2
	for frame in range(181):
		battle._physics_process(1.0 / 60)
		await process_frame
	battle._hint.text = "Inspeção visual P6: chefe e guardiões posicionados por fixture; não é partida de campanha."
	await capture("p6-captain-windup")
	for frame in range(108):
		battle._physics_process(1.0 / 60)
		await process_frame
	await capture("p6-captain-rally")
	battle._show_help()
	await capture("p6-help")
	battle._dismiss_help()
	battle.queue_free()
	await process_frame
	var tutorial: BattleViewV2 = BattleViewV2.new()
	tutorial.stage_path = "res://data/campaign/stage_01.json"
	root.add_child(tutorial)
	current_scene = tutorial
	for frame in range(15): await process_frame
	tutorial._select_pad(0)
	await capture("p6-tutorial")
	tutorial.queue_free()
	await process_frame
	var app: CampaignAppV2 = CampaignAppV2.new()
	root.add_child(app)
	current_scene = app
	app._show_guide()
	for frame in range(5): await process_frame
	var guide: CanvasLayer = app.get_node("GuideLayer") as CanvasLayer
	var captain_entry: Label = guide.find_child("EnemyGuide_boss_captain", true, false) as Label
	var parent: Node = captain_entry.get_parent()
	while not parent is ScrollContainer: parent = parent.get_parent()
	(parent as ScrollContainer).ensure_control_visible(captain_entry)
	await capture("p6-compendium")
	app.queue_free()
	await process_frame
	quit()
