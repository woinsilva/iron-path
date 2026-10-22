extends SceneTree
## Renders the menu backdrops (one per biome) and the tower portraits used by the campaign menus.
## Run windowed at 1920x1080: Godot --path . --resolution 1920x1080 -s res://tools/render_menu_art.gd
const OUT: String = "res://art/ui/"
func _initialize() -> void:
	call_deferred("run")
func open(stage_path: String) -> BattleViewV2:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = stage_path
	battle.tutorial_enabled = false
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	await process_frame
	while battle._warming_up: await process_frame
	for layer: Node in battle.find_children("*", "CanvasLayer", true, false): (layer as CanvasLayer).hide()
	for pad: Node3D in battle._pads: (pad.get_child(2) as Label3D).hide()
	battle.simulation.coins = 99999
	return battle
func advance(battle: BattleViewV2, seconds: float) -> void:
	for frame in range(int(seconds * 60)):
		battle._physics_process(1.0 / 60)
		if frame % 4 == 0: await process_frame
func raise(battle: BattleViewV2, pad: int, level: int, branch: String = "A") -> void:
	for step in range(level - 1):
		battle.simulation.upgrade(pad, branch if step == 2 else "")
		await advance(battle, 6)
func save(name: String, region: Rect2i = Rect2i(), size: Vector2i = Vector2i(1280, 720)) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if region.size != Vector2i.ZERO: image = image.get_region(region)
	image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	image.save_jpg(OUT + name + ".jpg", 0.88)
	print("saved ", name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for entry: Array in [["vale", "res://data/campaign/stage_04.json"], ["canyon", "res://data/campaign/stage_07.json"], ["swamp", "res://data/campaign/stage_10.json"]]:
		var battle: BattleViewV2 = await open(str(entry[1]))
		var allowed: Array = battle.stage.allowed_towers
		for pad in range(mini(6, battle.simulation.pads.size())):
			battle.simulation.build(pad, str(allowed[pad % allowed.size()]))
		await advance(battle, 6)
		for pad in range(mini(6, battle.simulation.pads.size())): await raise(battle, pad, 1 + pad % 3)
		for index in range(7):
			var enemy: SimEnemyV2 = battle.simulation.spawn_enemy(["grunt", "runner", "armored", "grunt_elite"][index % 4])
			enemy.distance = 6.0 + index * 2.6
		await advance(battle, 1.5)
		await save("backdrop_" + str(entry[0]))
		battle.queue_free()
		await process_frame
	var lab: BattleViewV2 = await open("res://data/campaign/arsenal_lab.json")
	var types: Array = lab.stage.allowed_towers
	for index in range(types.size()): lab.simulation.build(index, str(types[index]))
	await advance(lab, 8)
	for index in range(types.size()): await raise(lab, index, 3)
	var camera: Camera3D = lab.diorama.camera
	var offset: Vector3 = camera.position - Vector3.ZERO
	camera.v_offset = 0
	camera.size = 5.2
	for index in range(types.size()):
		var focus: Vector3 = lab.simulation.pads[index] + Vector3(0, 1.5, 0)
		camera.position = focus + offset
		camera.look_at(focus)
		for id: int in lab.tower_views:
			(lab.tower_views[id] as Node3D).visible = lab.simulation.towers[id].pad == index
		await advance(lab, 0.3)
		var view: Vector2i = root.get_texture().get_size()
		var side: int = mini(view.x, view.y)
		await save("tower_" + str(types[index]), Rect2i((view.x - side) / 2, (view.y - side) / 2, side, side), Vector2i(384, 384))
	quit()
