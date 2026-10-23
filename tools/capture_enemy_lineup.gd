extends SceneTree
## Close-up of every humanoid enemy side by side, walking, for art review.
## godot --path . --resolution 1600x700 -s res://tools/capture_enemy_lineup.gd
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var stage: Node3D = Node3D.new()
	root.add_child(stage)
	var catalog: Dictionary = BattleSimV2.load_catalog()
	var kinds: Array[String] = ["grunt", "grunt_elite", "runner", "runner_veteran", "armored", "armored_elite", "shieldbearer", "standardbearer", "resistant", "healer", "summoner", "brute"]
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.shadow_enabled = true
	stage.add_child(light)
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("2d3b40")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a9c4d2")
	environment.environment.ambient_light_energy = 0.6
	stage.add_child(environment)
	SceneCraft3D.box(stage, Vector3(40, 0.1, 8), Vector3(0, -0.05, 0), SceneCraft3D.material(Color("789558")))
	var actors: Array[RiggedActor3D] = []
	for index in range(kinds.size()):
		var definition: Dictionary = catalog.enemies[kinds[index]]
		var actor: RiggedActor3D = RiggedActor3D.new()
		actor.set_meta("type_id", kinds[index])
		actor.model_path = "res://art/models/%s.glb" % str(definition.get("model", "goblin"))
		actor.set_meta("equipment", definition.get("equipment", []))
		actor.position = Vector3((index - (kinds.size() - 1) * 0.5) * 1.55, 0, 0)
		stage.add_child(actor)
		actor.scale = Vector3.ONE * float(definition.scale)
		actor.set_heading(Vector3(0, 0, 1))
		actors.append(actor)
		var label: Label3D = Label3D.new()
		label.text = str(definition.name)
		label.font_size = 40
		label.pixel_size = 0.004
		label.position = actor.position + Vector3(0, 0.15, 1.0)
		label.rotation.x = -0.6
		stage.add_child(label)
	var camera: Camera3D = Camera3D.new()
	camera.position = Vector3(0, 4.2, 9.5)
	camera.fov = 52
	stage.add_child(camera)
	camera.look_at(Vector3(0, 1.0, 0))
	camera.current = true
	for frame in range(40):
		for actor: RiggedActor3D in actors: actor.animate_motion(Vector3(0, 0, 0.6) * actor.scale.y, 1.0 / 60)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/enemy-lineup.png")
	quit()
