class_name TowerUpgradeDecorV2 extends RefCounted
static func apply(display: Node3D, level: int, family: String, branch: String = "") -> void:
	var old: Node3D = display.get_node_or_null("LevelDecor") as Node3D
	if old:
		display.remove_child(old)
		old.queue_free()
	var decor: Node3D = Node3D.new()
	decor.name = "LevelDecor"
	display.add_child(decor)
	if level < 2: return
	var metal: StandardMaterial3D = SceneCraft3D.material(Color("b99d59"), 0.5, 0.45)
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("7b8883"))
	for x: float in [-0.67, 0.67]:
		for z: float in [-0.67, 0.67]:
			SceneCraft3D.box(decor, Vector3(0.18, 0.65, 0.18), Vector3(x, 0.45, z), stone)
			SceneCraft3D.box(decor, Vector3(0.24, 0.08, 0.24), Vector3(x, 0.8, z), metal)
	if level < 3: return
	var color: Color = Color("449a9a") if family in ["archer", "cannon"] else (Color("76cfed") if family == "frost" else (Color("92c968") if family == "venom" else Color("e6ce8a")))
	var cloth: StandardMaterial3D = SceneCraft3D.material(color)
	SceneCraft3D.cylinder(decor, 0.045, 1.8, Vector3(-0.75, 0.9, -0.6), metal, 8)
	SceneCraft3D.box(decor, Vector3(0.45, 0.5, 0.05), Vector3(-0.52, 1.45, -0.6), cloth)
	for z: float in [-0.3, 0.3]:
		SceneCraft3D.box(decor, Vector3(0.14, 0.08, 1.45), Vector3(0, 0.3, z), metal)

	if level < 4: return
	var module: Node3D = Node3D.new()
	module.name = "BranchModule"
	decor.add_child(module)
	var accent: StandardMaterial3D = SceneCraft3D.material(Color("91b5d4") if branch == "A" else Color("c8a471"), 0.5, 0.3)
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("74563c"))
	if family == "cannon":
		module.position.y = 1.0
		var cannon: CannonDisplay3D = display as CannonDisplay3D
		cannon.barrel.rotation.x = -0.55 if branch == "A" else 0.0
		cannon.barrel.scale = Vector3(1.22, 1.22, 0.85) if branch == "A" else Vector3(1.08, 1.08, 1.15)
		module.rotation.x = cannon.barrel.rotation.x
		for z: float in [0.25, 0.85]:
			var band: MeshInstance3D = SceneCraft3D.cylinder(module, 0.47 if branch == "A" else 0.42, 0.14, Vector3(0, 0, z), accent, 16)
			band.rotation.x = PI / 2
	elif family == "archer" or family == "bleed":
		module.position.y = 3.15 if family == "archer" else 1.5
		if branch == "A":
			var scope: MeshInstance3D = SceneCraft3D.cylinder(module, 0.13, 0.8, Vector3(0.3, 0.15, 0.5), accent, 12)
			scope.rotation.x = PI / 2
			SceneCraft3D.sphere(module, 0.11, Vector3(0.3, 0.15, 0.93), cloth)
		else:
			for index in range(3):
				SceneCraft3D.box(module, Vector3(0.1, 0.14, 0.95), Vector3(-0.35 + index * 0.18, 0.05, 0.25), accent)
	elif family == "frost":
		for index in range(3 if branch == "A" else 1):
			var angle: float = index * TAU / 3
			var crystal: PrismMesh = PrismMesh.new()
			crystal.size = Vector3(0.28, 0.65 if branch == "A" else 1.25, 0.28)
			SceneCraft3D.mesh(module, crystal, Vector3(sin(angle) * 0.65 if branch == "A" else 0, 2.0 if branch == "A" else 2.6, cos(angle) * 0.65 if branch == "A" else 0), accent)
	elif family == "venom":
		for index in range(3 if branch == "A" else 1):
			var x: float = -0.5 + index * 0.5 if branch == "A" else 0.5
			SceneCraft3D.cylinder(module, 0.12, 1.3, Vector3(x, 1.3, -0.4), accent, 10)
			SceneCraft3D.cylinder(module, 0.2, 0.15, Vector3(x, 2.0, -0.4), metal, 10)
	elif family == "anti_air":
		for index in range(3 if branch == "A" else 1):
			var angle: float = index * TAU / 3
			var point: Vector3 = Vector3(sin(angle) * 0.65, 3.35, cos(angle) * 0.65) if branch == "A" else Vector3(0, 3.75, 0)
			SceneCraft3D.cylinder(module, 0.065, 0.7 if branch == "A" else 1.1, point, accent, 8)
	elif family == "arcane":
		if branch == "A":
			var lens: TorusMesh = TorusMesh.new()
			lens.inner_radius = 0.56
			lens.outer_radius = 0.68
			lens.rings = 24
			lens.ring_segments = 6
			var ring: MeshInstance3D = SceneCraft3D.mesh(module, lens, Vector3(0, 2.3, 0), accent)
			ring.rotation.x = PI / 2
		else:
			for index in range(3):
				var angle: float = index * TAU / 3
				SceneCraft3D.sphere(module, 0.2, Vector3(sin(angle) * 0.7, 2.3, cos(angle) * 0.7), accent)
	elif family == "banner":
		if branch == "A":
			SceneCraft3D.box(module, Vector3(0.8, 0.75, 0.05), Vector3(-0.45, 3.1, 0), accent)
			SceneCraft3D.box(module, Vector3(0.9, 0.08, 0.08), Vector3(-0.4, 3.5, 0), wood)
		else:
			SceneCraft3D.sphere(module, 0.28, Vector3(0, 4.05, 0), accent)
	if level == 5:
		for index in range(3):
			SceneCraft3D.sphere(decor, 0.105, Vector3(-0.22 + index * 0.22, 0.52, 0.82), metal)
