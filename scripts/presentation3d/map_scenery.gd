## Hand-dressed set pieces for the redesigned maps (one per biome): border hills or cliffs, a lived-in
## landmark with moving parts (smoke, flags, water, swaying plants) and dense props. Presentation only;
## every placement keeps clear of the roads, the build area rule and the authored reference spots.
class_name MapSceneryV2
extends RefCounted

const FLAG_SHADER: String = "res://scripts/presentation3d/flag.gdshader"
## Decorative props that step aside (hide) when a tower is built on top of them.
const SCENERY_GROUP: StringName = &"scenery_prop"


static func build(diorama: Diorama3D, scenery: String) -> void:
	match scenery:
		"vale_meadow": _vale_meadow(diorama)
		"canyon_bridges": _canyon_bridges(diorama)
		"swamp_lake": _swamp_lake(diorama)
		"vale_terraces": _vale_terraces(diorama)
		"vale_river": _vale_river(diorama)
		"vale_hillfort": _vale_hillfort(diorama)
		"canyon_quarry": _canyon_quarry(diorama)
		"canyon_fortress": _canyon_fortress(diorama)
		"canyon_forge": _canyon_forge(diorama)
		"swamp_causeway": _swamp_causeway(diorama)
		"swamp_nest": _swamp_nest(diorama)
		"swamp_heart": _swamp_heart(diorama)
	_frame(diorama)


## Beyond the playable board the camera still sees ground on wide screens; fill it so the map never
## ends in an empty plain (forest for the vale, rock shelves for the canyon, dead woods for the swamp).
static func _frame(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4242
	var files: Array = ["Tree_1_A_Color1", "Tree_1_B_Color1", "Tree_2_A_Color1", "Tree_4_A_Color1", "Tree_4_B_Color1", "Bush_1_A_Color1", "Bush_4_A_Color1"]
	if diorama.biome == "canyon": files = ["Rock_3_A_Color1", "Rock_3_C_Color1", "Rock_3_F_Color1", "Rock_1_D_Color1", "Tree_Bare_1_A_Color1"]
	elif diorama.biome == "swamp": files = ["Tree_3_A_Color1", "Tree_1_B_Color1", "Tree_4_B_Color1", "Bush_2_C_Color1"]
	var bands: Array[Rect2] = [Rect2(-31, -19, 9.5, 38), Rect2(21.5, -19, 9.5, 38), Rect2(-22, 11.6, 44, 7), Rect2(-22, -19, 44, 6.5)]
	# The stylised vale stays open: only a sparse wood beyond the back edge and flanks.
	if diorama.biome == "vale": bands = [Rect2(-31, -19, 62, 5.5), Rect2(-31, -13, 8, 24), Rect2(22.5, -13, 8, 24)]
	for band: Rect2 in bands:
		var count: int = int(band.get_area() / 7.0)
		for index in range(count):
			var point: Vector3 = Vector3(rng.randf_range(band.position.x, band.end.x), 0.06, rng.randf_range(band.position.y, band.end.y))
			if absf(point.x - diorama.river_x) < diorama.river_width * 0.5 + 0.8: continue
			if diorama._distance_from_route(point) < 2.4: continue
			if point.distance_to(diorama.route.sample_baked(diorama.route.get_baked_length())) < 7.0: continue
			var size: float = rng.randf_range(0.8, 1.4) * (1.6 if diorama.biome == "canyon" else 1.0)
			if diorama.biome == "vale" and (rng.randf() < 0.45 or _hides_road(diorama, point, 4.2 * size)): continue
			_prop(diorama, str(files[rng.randi() % files.size()]), point, size, rng.randf_range(-PI, PI), diorama.biome != "canyon")


# --- shared pieces -------------------------------------------------------------------------

static func _on_ground(diorama: Diorama3D, point: Vector3) -> Vector3:
	return Vector3(point.x, point.y + diorama.terrain_height(point), point.z)


static func _free(diorama: Diorama3D, point: Vector3, road: float, reserved: float) -> bool:
	if diorama._distance_from_route(point) < road: return false
	if diorama._is_reserved(point, reserved): return false
	return absf(point.x - diorama.river_x) > diorama.river_width * 0.5 + 0.6


static func _prop(diorama: Diorama3D, file: String, point: Vector3, size: float, angle: float, sway: bool = true) -> Node3D:
	var node: Node3D = (load("res://art/models/%s.glb" % file) as PackedScene).instantiate() as Node3D
	node.position = Vector3(point.x, point.y + diorama.terrain_height(point), point.z)
	node.add_to_group(SCENERY_GROUP)
	node.rotation.y = angle
	node.scale = Vector3.ONE * size
	diorama.add_child(node)
	if sway: diorama._style_foliage(node)
	return node


## A band of props along the board edges and in the given clusters, never on roads or build spots.
static func _scatter(diorama: Diorama3D, rng: RandomNumberGenerator, files: Array, count: int, area: Rect2, road: float, size: Vector2, sway: bool = true) -> void:
	var placed: int = 0
	var attempts: int = 0
	while placed < count and attempts < count * 12:
		attempts += 1
		var point: Vector3 = Vector3(rng.randf_range(area.position.x, area.end.x), 0.08, rng.randf_range(area.position.y, area.end.y))
		if not _free(diorama, point, road, 2.0): continue
		var scale: float = rng.randf_range(size.x, size.y)
		var file: String = str(files[rng.randi() % files.size()])
		if file.begins_with("Tree") and _hides_road(diorama, point, 4.2 * scale): continue
		_prop(diorama, file, point, scale, rng.randf_range(-PI, PI), sway)
		placed += 1


static func _hill(diorama: Diorama3D, center: Vector3, radius: Vector2, height: float, color: Color) -> MeshInstance3D:
	var dome: SphereMesh = SphereMesh.new()
	dome.radius = 1.0
	dome.height = 2.0
	dome.radial_segments = 24
	dome.rings = 12
	var hill: MeshInstance3D = SceneCraft3D.mesh(diorama, dome, center, SceneCraft3D.material(color, 0.95))
	hill.scale = Vector3(radius.x, height, radius.y)
	return hill


## Cloth on a pole that ripples in the wind (flag.gdshader animates it on the GPU).
static func _flag(diorama: Node3D, base: Vector3, color: Color, height: float = 3.2) -> void:
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("6b4d33"))
	SceneCraft3D.cylinder(diorama, 0.06, height, base + Vector3(0, height / 2, 0), wood, 8)
	SceneCraft3D.sphere(diorama, 0.1, base + Vector3(0, height + 0.05, 0), SceneCraft3D.material(Color("d9b45a"), 0.4, 0.6))
	var cloth: QuadMesh = QuadMesh.new()
	cloth.size = Vector2(1.2, 0.75)
	cloth.subdivide_width = 10
	cloth.subdivide_depth = 4
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load(FLAG_SHADER) as Shader
	material.set_shader_parameter("tint", color)
	var flag: MeshInstance3D = SceneCraft3D.mesh(diorama, cloth, base + Vector3(0.62, height - 0.45, 0), material)
	flag.rotation.y = -0.35


## Rising soft puffs, used for chimneys and campfires.
static func _smoke(parent: Node3D, point: Vector3, color: Color = Color(0.85, 0.85, 0.82, 0.55)) -> void:
	var puff: SphereMesh = SphereMesh.new()
	puff.radius = 0.18
	puff.height = 0.36
	puff.radial_segments = 8
	puff.rings = 4
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	puff.material = material
	var smoke: CPUParticles3D = CPUParticles3D.new()
	smoke.mesh = puff
	smoke.amount = 10
	smoke.lifetime = 3.2
	smoke.direction = Vector3(0.25, 1, 0)
	smoke.spread = 12
	smoke.gravity = Vector3(0.12, 0.25, 0)
	smoke.initial_velocity_min = 0.35
	smoke.initial_velocity_max = 0.6
	smoke.scale_amount_min = 0.8
	smoke.scale_amount_max = 1.6
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.9))
	fade.set_color(1, Color(1, 1, 1, 0))
	smoke.color_ramp = fade
	smoke.position = point
	parent.add_child(smoke)
	smoke.add_to_group(BiomeDressingV2.DETAIL_GROUP)


static func _house(diorama: Diorama3D, point: Vector3, angle: float, roof_color: Color, smoke: bool) -> void:
	var house: Node3D = Node3D.new()
	house.position = point
	house.rotation.y = angle
	diorama.add_child(house)
	var wall: StandardMaterial3D = SceneCraft3D.material(Color("e8dcc0"))
	var beam: StandardMaterial3D = SceneCraft3D.material(Color("7a5634"))
	var roof: StandardMaterial3D = SceneCraft3D.material(roof_color)
	SceneCraft3D.box(house, Vector3(2.4, 1.6, 1.8), Vector3(0, 0.8, 0), wall)
	for x: float in [-1.15, 1.15]: SceneCraft3D.box(house, Vector3(0.14, 1.65, 1.85), Vector3(x, 0.82, 0), beam)
	SceneCraft3D.box(house, Vector3(0.55, 0.95, 0.06), Vector3(0.4, 0.48, 0.92), beam)
	SceneCraft3D.box(house, Vector3(0.45, 0.4, 0.06), Vector3(-0.6, 1.0, 0.92), SceneCraft3D.material(Color("8fc4d6"), 0.2))
	var gable: PrismMesh = PrismMesh.new()
	gable.size = Vector3(2.8, 1.25, 2.2)
	SceneCraft3D.mesh(house, gable, Vector3(0, 2.2, 0), roof)
	SceneCraft3D.box(house, Vector3(0.32, 0.9, 0.32), Vector3(0.75, 2.4, -0.35), SceneCraft3D.material(Color("8f8273")))
	if smoke: _smoke(house, Vector3(0.75, 3.0, -0.35))


static func _pond(diorama: Diorama3D, center: Vector3, radius: Vector2) -> void:
	var bank: MeshInstance3D = SceneCraft3D.cylinder(diorama, 1.0, 0.06, center + Vector3(0, 0.05, 0), SceneCraft3D.material(Color("7d6b4b")), 28)
	bank.scale = Vector3(radius.x + 0.35, 1, radius.y + 0.35)
	var water: MeshInstance3D = SceneCraft3D.cylinder(diorama, 1.0, 0.04, center + Vector3(0, 0.1, 0), diorama._water_surface, 28)
	water.scale = Vector3(radius.x, 1, radius.y)


## Tall reeds whose tips bend with the wind (they go through the foliage shader).
static func _reeds(diorama: Diorama3D, rng: RandomNumberGenerator, center: Vector3, radius: float, count: int) -> void:
	for index in range(count):
		var angle: float = rng.randf_range(0, TAU)
		var point: Vector3 = center + Vector3(cos(angle), 0, sin(angle)) * radius * rng.randf_range(0.85, 1.1)
		if not _free(diorama, point, 1.6, 1.4): continue
		_prop(diorama, "Grass_2_A_Color1", point, rng.randf_range(0.9, 1.4), angle)


## Where raiders come in: a log palisade across the road with an open gate, two watch platforms and a
## wrecked cart outside, so the spawn point reads as a breached border instead of the map edge.
static func _entrance_gate(diorama: Diorama3D, rng: RandomNumberGenerator, road: Curve3D = null) -> void:
	var gate: Node3D = _entrance_frame(diorama, road if road != null else diorama.route, "EntranceGate")
	var bark: StandardMaterial3D = SceneCraft3D.material(Color("5b4632"), 0.95)
	var cut: StandardMaterial3D = SceneCraft3D.material(Color("8a6b4a"), 0.9)
	var plank: StandardMaterial3D = SceneCraft3D.material(Color("6e5338"), 0.92)
	var iron: StandardMaterial3D = SceneCraft3D.material(Color("3b3a38"), 0.5, 0.7)
	# Palisade: sharpened logs either side of a 3 m opening.
	for sign: float in [-1.0, 1.0]:
		var x: float = 1.6
		while x < 7.5:
			var height: float = rng.randf_range(2.0, 2.6)
			var radius: float = rng.randf_range(0.15, 0.2)
			var log: MeshInstance3D = SceneCraft3D.cylinder(gate, radius, height, Vector3(sign * x, height / 2, rng.randf_range(-0.05, 0.05)), bark, 7)
			log.rotation.z = rng.randf_range(-0.04, 0.04)
			var tip: CylinderMesh = CylinderMesh.new()
			tip.top_radius = 0.0
			tip.bottom_radius = radius
			tip.height = 0.4
			tip.radial_segments = 7
			SceneCraft3D.mesh(gate, tip, Vector3(sign * x, height + 0.2, 0), cut)
			x += radius * 2.05
		SceneCraft3D.box(gate, Vector3(6.0, 0.14, 0.12), Vector3(sign * 4.5, 1.2, 0.22), plank)
	# Gate frame and towers.
	for sign: float in [-1.0, 1.0]:
		for z: float in [-0.5, 0.5]:
			SceneCraft3D.cylinder(gate, 0.17, 3.6, Vector3(sign * 1.5, 1.8, z), bark, 8)
		SceneCraft3D.box(gate, Vector3(1.3, 0.12, 1.3), Vector3(sign * 1.5, 3.0, 0), plank)
		var roof: PrismMesh = PrismMesh.new()
		roof.size = Vector3(1.6, 0.7, 1.6)
		SceneCraft3D.mesh(gate, roof, Vector3(sign * 1.5, 3.95, 0), SceneCraft3D.material(Color("4a3a2c"), 0.95))
		# Open doors swung outward.
		var door: Node3D = Node3D.new()
		door.position = Vector3(sign * 1.35, 0, -0.5)
		door.rotation.y = sign * 1.15
		gate.add_child(door)
		for board in range(4):
			SceneCraft3D.box(door, Vector3(0.3, 2.1, 0.08), Vector3(-sign * (0.17 + board * 0.32), 1.05, 0), plank)
		for y: float in [0.5, 1.6]: SceneCraft3D.box(door, Vector3(1.3, 0.1, 0.1), Vector3(-sign * 0.65, y, -0.06), iron)
	SceneCraft3D.box(gate, Vector3(3.6, 0.3, 0.3), Vector3(0, 3.35, 0), cut)
	_flag(gate, Vector3(1.5, 4.25, 0), Color("8c2f28"), 1.4)
	# Tipped cart and spilled crates just outside the gate.
	var cart: Node3D = Node3D.new()
	cart.position = Vector3(-3.2, 0, -2.6)
	cart.rotation = Vector3(0, 0.6, 0.35)
	gate.add_child(cart)
	SceneCraft3D.box(cart, Vector3(1.8, 0.5, 1.0), Vector3(0, 0.75, 0), plank)
	for x: float in [-0.6, 0.6]:
		for z: float in [-0.55, 0.55]:
			var wheel: MeshInstance3D = SceneCraft3D.cylinder(cart, 0.38, 0.1, Vector3(x, 0.38, z), cut, 12)
			wheel.rotation.x = PI / 2
	for index in range(3):
		var crate: MeshInstance3D = SceneCraft3D.box(gate, Vector3(0.5, 0.5, 0.5), Vector3(-2.0 - index * 0.7, 0.25, -3.6 + index * 0.4), plank)
		crate.rotation.y = rng.randf_range(0, 1.2)


## A node standing on the road 2.2 m in, facing along it (local -z points into the map, x across it).
static func _entrance_frame(diorama: Diorama3D, road: Curve3D, label: String) -> Node3D:
	var start: Vector3 = road.sample_baked(2.2)
	var forward: Vector3 = (road.sample_baked(3.2) - road.sample_baked(1.2))
	forward.y = 0
	forward = forward.normalized()
	var side: Vector3 = Vector3(-forward.z, 0, forward.x)
	var frame: Node3D = Node3D.new()
	frame.name = label
	frame.position = Vector3(start.x, diorama.terrain_height(start), start.z)
	frame.basis = Basis(side, Vector3.UP, -forward)
	diorama.add_child(frame)
	return frame


## Every ground entrance gets the biome's landmark: palisade gates in the vale, timbered mine mouths in
## the canyon, ruined rune arches in the swamp. Tunnels (burrowers) have no surface entrance.
static func _entrances(diorama: Diorama3D, rng: RandomNumberGenerator) -> void:
	for index in range(diorama.all_ground_routes.size()):
		if index in diorama.burrow_routes: continue
		var road: Curve3D = diorama.all_ground_routes[index]
		match diorama.biome:
			"canyon": _mine_mouth(diorama, rng, road, index)
			"swamp": _rune_arch(diorama, rng, road, index)
			_: _entrance_gate(diorama, rng, road)


## A tunnel portal cut into a rock outcrop: dark mouth, timber frame, lanterns and an ore cart on rails.
static func _mine_mouth(diorama: Diorama3D, rng: RandomNumberGenerator, road: Curve3D, index: int) -> void:
	var mouth: Node3D = _entrance_frame(diorama, road, "MineEntrance%d" % index)
	var rock: StandardMaterial3D = SceneCraft3D.material(Color("a5603f"), 0.95)
	var dark_rock: StandardMaterial3D = SceneCraft3D.material(Color("74402e"), 0.95)
	var timber: StandardMaterial3D = SceneCraft3D.material(Color("6b4a2e"), 0.92)
	var shadow: StandardMaterial3D = SceneCraft3D.material(Color("140d0a"), 1.0)
	var iron: StandardMaterial3D = SceneCraft3D.material(Color("3d3b39"), 0.5, 0.7)
	# Outcrop: stacked boulders either side and over the mouth, behind the entrance (+z is outside the map).
	for sign: float in [-1.0, 1.0]:
		for layer in range(3):
			var boulder: MeshInstance3D = SceneCraft3D.sphere(mouth, rng.randf_range(1.3, 1.7) - layer * 0.2, Vector3(sign * rng.randf_range(2.6, 3.2), 0.6 + layer * 1.05, 1.6 + layer * 0.2), rock if layer % 2 == 0 else dark_rock)
			boulder.scale = Vector3(1.3, 0.85, 1.1)
		var flank: MeshInstance3D = SceneCraft3D.sphere(mouth, 1.6, Vector3(sign * 4.8, 0.4, 2.2), dark_rock)
		flank.scale = Vector3(1.4, 0.7, 1.2)
	var crown: MeshInstance3D = SceneCraft3D.sphere(mouth, 2.2, Vector3(0, 3.6, 2.4), rock)
	crown.scale = Vector3(1.6, 0.6, 1.0)
	SceneCraft3D.box(mouth, Vector3(3.0, 3.0, 2.2), Vector3(0, 1.5, 1.5), shadow)
	# Timber portal.
	for sign: float in [-1.0, 1.0]:
		SceneCraft3D.box(mouth, Vector3(0.32, 3.1, 0.32), Vector3(sign * 1.55, 1.55, 0.35), timber)
		var brace: MeshInstance3D = SceneCraft3D.box(mouth, Vector3(0.18, 1.0, 0.18), Vector3(sign * 1.25, 2.75, 0.35), timber)
		brace.rotation.z = sign * 0.7
	SceneCraft3D.box(mouth, Vector3(3.8, 0.36, 0.4), Vector3(0, 3.2, 0.35), timber)
	# Lanterns that glow at the frame.
	var glow: StandardMaterial3D = SceneCraft3D.material(Color("ffcf7a"))
	glow.emission_enabled = true
	glow.emission = Color("ff9f3d")
	glow.emission_energy_multiplier = 1.6
	for sign: float in [-1.0, 1.0]: SceneCraft3D.sphere(mouth, 0.14, Vector3(sign * 1.55, 2.45, 0.05), glow)
	# Rails running out of the mine and a tipped ore cart beside the road.
	for sign: float in [-1.0, 1.0]: SceneCraft3D.box(mouth, Vector3(0.06, 0.05, 3.0), Vector3(sign * 0.45 - 2.4, 0.04, -0.6), iron)
	var cart: Node3D = Node3D.new()
	cart.position = Vector3(-2.4, 0, -1.3)
	cart.rotation = Vector3(0, 0.2, 0.25)
	mouth.add_child(cart)
	SceneCraft3D.box(cart, Vector3(0.9, 0.55, 1.2), Vector3(0, 0.45, 0), iron)
	for z: float in [-0.4, 0.4]:
		for sign: float in [-1.0, 1.0]:
			var wheel: MeshInstance3D = SceneCraft3D.cylinder(cart, 0.16, 0.08, Vector3(sign * 0.45, 0.16, z), timber, 10)
			wheel.rotation.z = PI / 2
	for ore in range(4): SceneCraft3D.sphere(cart, 0.16, Vector3(rng.randf_range(-0.2, 0.2), 0.8, rng.randf_range(-0.35, 0.35)), SceneCraft3D.material(Color("c9a45a"), 0.5, 0.4))


## Two leaning rune pillars with a cracked lintel, moss and a breath of mist rolling out between them.
static func _rune_arch(diorama: Diorama3D, rng: RandomNumberGenerator, road: Curve3D, index: int) -> void:
	var arch: Node3D = _entrance_frame(diorama, road, "RuneArch%d" % index)
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("6f7d76"), 0.95)
	var moss: StandardMaterial3D = SceneCraft3D.material(Color("536a40"))
	var rune: StandardMaterial3D = SceneCraft3D.material(Color("c1aef0"))
	rune.emission_enabled = true
	rune.emission = Color("9a7be0")
	rune.emission_energy_multiplier = 1.3
	for sign: float in [-1.0, 1.0]:
		var pillar: Node3D = Node3D.new()
		pillar.position = Vector3(sign * 1.75, 0, 0.3)
		pillar.rotation.z = sign * rng.randf_range(0.03, 0.08)
		arch.add_child(pillar)
		SceneCraft3D.box(pillar, Vector3(1.0, 0.35, 1.0), Vector3(0, 0.17, 0), stone)
		for block in range(5): SceneCraft3D.box(pillar, Vector3(0.7 - block * 0.03, 0.62, 0.7 - block * 0.03), Vector3(rng.randf_range(-0.04, 0.04), 0.66 + block * 0.64, 0), stone)
		SceneCraft3D.box(pillar, Vector3(0.75, 0.12, 0.75), Vector3(0, 3.6, 0), moss)
		for y: float in [1.2, 2.4]:
			var glyph: MeshInstance3D = SceneCraft3D.box(pillar, Vector3(0.22, 0.22, 0.05), Vector3(0, y, -0.37), rune)
			glyph.rotation.z = PI / 4
		# Rubble at the foot.
		for chunk in range(3):
			var piece: MeshInstance3D = SceneCraft3D.box(arch, Vector3(0.45, 0.3, 0.4), Vector3(sign * rng.randf_range(2.6, 3.6), 0.15, rng.randf_range(-0.6, 1.2)), stone)
			piece.rotation.y = rng.randf_range(0, PI)
	var lintel: MeshInstance3D = SceneCraft3D.box(arch, Vector3(4.6, 0.55, 0.85), Vector3(0.2, 3.95, 0.3), stone)
	lintel.rotation.z = -0.06
	SceneCraft3D.box(arch, Vector3(3.6, 0.12, 0.7), Vector3(0.1, 4.28, 0.3), moss)
	var keystone: MeshInstance3D = SceneCraft3D.box(arch, Vector3(0.5, 0.5, 0.06), Vector3(0.2, 3.95, -0.14), rune)
	keystone.rotation.z = PI / 4
	_smoke(arch, Vector3(0, 0.3, 0.6), Color(0.78, 0.9, 0.84, 0.3))
	# Dead trees leaning over the arch.
	for sign: float in [-1.0, 1.0]:
		var tree: Node3D = _prop(diorama, "Tree_Bare_1_A_Color1", Vector3.ZERO, rng.randf_range(0.8, 1.0), rng.randf_range(-PI, PI), false)
		tree.global_position = arch.to_global(Vector3(sign * 4.3, 0, 1.4))
		tree.global_position.y = diorama.terrain_height(tree.global_position)


# --- Vale Verde: farm valley with a village, windmill, pond and forest edges ---------------

static func _vale_meadow(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1101
	_entrance_gate(diorama, rng)
	var exit: Vector3 = diorama.route.sample_baked(diorama.route.get_baked_length())
	var trees: Array = ["Tree_1_A_Color1", "Tree_1_B_Color1", "Tree_2_A_Color1", "Tree_2_B_Color1", "Tree_3_A_Color1", "Tree_4_A_Color1", "Tree_4_B_Color1"]
	# Wood line behind the board and loose groves on the flanks; nothing tall may hide the road.
	_scatter(diorama, rng, trees, 34, Rect2(-30, -18, 60, 6.4), 2.6, Vector2(0.65, 1.05))
	_scatter(diorama, rng, trees, 12, Rect2(-30, -11, 8.5, 20), 2.6, Vector2(0.6, 1.0))
	_scatter(diorama, rng, trees, 10, Rect2(22, -11, 8, 20), 2.6, Vector2(0.6, 1.0))
	_scatter(diorama, rng, trees, 8, Rect2(-20, -10, 37, 20), 3.4, Vector2(0.55, 0.85))
	_scatter(diorama, rng, ["Bush_1_A_Color1", "Bush_1_C_Color1", "Bush_2_C_Color1", "Bush_3_A_Color1", "Bush_4_A_Color1"], 44, Rect2(-21, -11, 40, 22), 2.0, Vector2(0.6, 1.1))
	_scatter(diorama, rng, ["Rock_1_A_Color1", "Rock_1_D_Color1", "Rock_3_A_Color1", "Rock_3_C_Color1"], 18, Rect2(-21, -11, 40, 22), 2.2, Vector2(0.5, 0.9), false)
	# Village around the exit: cottages with chimney smoke and the guard flag.
	for entry: Array in [[Vector3(-3.6, 0, 1.5), 0.3, Color("a8543c")], [Vector3(-3.2, 0, -2.6), -0.2, Color("4f6f9a")], [Vector3(2.6, 0, 2.4), 2.6, Color("a8543c")]]:
		var spot: Vector3 = exit + (entry[0] as Vector3)
		spot.y = diorama.terrain_height(spot)
		if _free(diorama, spot, 2.4, 2.4): _house(diorama, spot, float(entry[1]), entry[2], true)
	var pole: Vector3 = exit + Vector3(-1.2, 0.1, -1.2)
	pole.y += diorama.terrain_height(pole)
	_flag(diorama, pole, Color("2f7f86"))
	# Fences on stretches of the road, following the ground.
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("8a6a45"))
	var road: Curve3D = diorama.route
	var distance: float = 6.0
	while distance < road.get_baked_length() - 6.0:
		var here: Vector3 = road.sample_baked(distance)
		var ahead: Vector3 = road.sample_baked(distance + 0.6)
		var side: Vector3 = Vector3(-(ahead - here).z, 0, (ahead - here).x).normalized() * 1.7
		for sign: float in [-1.0, 1.0]:
			var post: Vector3 = here + side * sign
			var next: Vector3 = road.sample_baked(distance + 1.1) + side * sign
			if diorama._distance_from_route(post) < 1.55 or diorama._is_reserved(post, 1.6): continue
			post.y = diorama.terrain_height(post)
			next.y = diorama.terrain_height(next)
			SceneCraft3D.box(diorama, Vector3(0.1, 0.55, 0.1), post + Vector3(0, 0.3, 0), wood)
			SceneCraft3D.beam(diorama, post + Vector3(0, 0.42, 0), next + Vector3(0, 0.42, 0), 0.05, wood)
		distance += 1.1 if int(distance / 9.0) % 2 == 0 else 4.0


## Realistic surfaces for the hand-built pieces: brown materials get the CC0 weathered wood texture,
## stone and plaster keep their tint with a grain, and saturated roof colours are toned down.
static func weather(root: Node) -> void:
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var source: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		if source == null or source.albedo_texture != null or source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: continue
		var color: Color = source.albedo_color
		var material: StandardMaterial3D = source.duplicate() as StandardMaterial3D
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		var wooden: bool = color.r > color.b * 1.15 and color.r < 0.75 and color.s > 0.2 and color.v < 0.75
		material.albedo_texture = load("res://art/textures/wood_planks_grey_Diffuse.jpg" if wooden else "res://art/textures/rocky_trail_Diffuse.jpg") as Texture2D
		material.normal_enabled = true
		material.normal_texture = load("res://art/textures/wood_planks_grey_nor_gl.jpg" if wooden else "res://art/textures/rocky_trail_nor_gl.jpg") as Texture2D
		material.uv1_scale = Vector3.ONE * (0.9 if wooden else 0.6)
		material.albedo_color = (color.lightened(0.25) if wooden else Color.from_hsv(color.h, color.s * 0.55, minf(1.0, color.v * 1.1)))
		material.roughness = 0.92
		mesh.material_override = material


## The camera looks down at ~49° from the south, so a prop of height H covers the ground up to about
## 0.9·H behind it (towards -z). Reject props whose silhouette would fall on a road.
static func _hides_road(diorama: Diorama3D, point: Vector3, height: float) -> bool:
	var reach: float = height * 0.9 + 1.2
	var step: float = 0.0
	while step <= reach:
		if diorama._distance_from_route(point - Vector3(0, 0, step)) < 1.8: return true
		step += 0.6
	return false


## Sprite props spread over an area on the terrain, clear of roads, build spots and a radius around a point.
static func _sprite_scatter(diorama: Diorama3D, rng: RandomNumberGenerator, names: Array, count: int, area: Rect2, road: float, height: Vector2, keep_clear: Array[Vector3], clear_radius: float) -> void:
	var placed: int = 0
	var attempts: int = 0
	while placed < count and attempts < count * 10:
		attempts += 1
		var point: Vector3 = Vector3(rng.randf_range(area.position.x, area.end.x), 0, rng.randf_range(area.position.y, area.end.y))
		if not _free(diorama, point, road, 2.0): continue
		var size: float = rng.randf_range(height.x, height.y)
		if _hides_road(diorama, point, size): continue
		var crowded: bool = false
		for spot: Vector3 in keep_clear: crowded = crowded or point.distance_to(Vector3(spot.x, 0, spot.z)) < clear_radius
		if crowded: continue
		point.y = diorama.terrain_height(point)
		SpritePropsV2.place(diorama, str(names[rng.randi() % names.size()]), point, size, rng.randf() < 0.5)
		placed += 1


# --- Garganta Rubra: red canyon split by a river, with cliffs and a waterfall ---------------

static func _canyon_bridges(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5505
	_entrances(diorama, rng)
	var rock: StandardMaterial3D = SceneCraft3D.material(Color("b06a46"))
	var stratum: StandardMaterial3D = SceneCraft3D.material(Color("7d4836"))
	var crest: StandardMaterial3D = SceneCraft3D.material(Color("c2804f"))
	# Layered mesas crowding the top and bottom edges, like the canyon walls closing in.
	for edge: float in [-1.0, 1.0]:
		var x: float = -23.0
		while x < 23.0:
			var radius: float = rng.randf_range(1.5, 2.4)
			var point: Vector3 = Vector3(x, 0, edge * rng.randf_range(11.8, 13.6))
			x += radius * 1.35
			if diorama._distance_from_route(point) < radius + 1.4 or absf(point.x - diorama.river_x) < diorama.river_width * 0.5 + radius: continue
			var height: float = rng.randf_range(2.4, 4.6) * (0.65 if edge > 0 else 1.0)
			var mesa: Node3D = Node3D.new()
			mesa.position = _on_ground(diorama, point)
			mesa.rotation.y = rng.randf_range(0, TAU)
			diorama.add_child(mesa)
			for layer in range(4):
				var band: float = height / 4.0
				SceneCraft3D.cylinder(mesa, radius * (1.0 - layer * 0.09) * rng.randf_range(0.95, 1.05), band, Vector3(0, band * (layer + 0.5), 0), [rock, stratum, rock, crest][layer], 7)
	# Waterfall where the river enters from the top cliff.
	var fall: QuadMesh = QuadMesh.new()
	fall.size = Vector2(diorama.river_width * 0.9, 3.6)
	var spray: ShaderMaterial = ShaderMaterial.new()
	spray.shader = load("res://scripts/presentation3d/waterfall.gdshader") as Shader
	var curtain: MeshInstance3D = SceneCraft3D.mesh(diorama, fall, Vector3(diorama.river_x, 1.8, -11.6), spray)
	curtain.rotation.x = -0.15
	var foam: CPUParticles3D = CPUParticles3D.new()
	var bubble: SphereMesh = SphereMesh.new()
	bubble.radius = 0.12
	bubble.height = 0.24
	var white: StandardMaterial3D = SceneCraft3D.material(Color(1, 1, 1))
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bubble.material = white
	foam.mesh = bubble
	foam.amount = 24
	foam.lifetime = 1.2
	foam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	foam.emission_box_extents = Vector3(diorama.river_width * 0.4, 0.1, 0.3)
	foam.direction = Vector3(0, 1, 0.6)
	foam.spread = 35
	foam.initial_velocity_min = 0.6
	foam.initial_velocity_max = 1.3
	foam.position = Vector3(diorama.river_x, 0.2, -10.8)
	diorama.add_child(foam)
	foam.add_to_group(BiomeDressingV2.DETAIL_GROUP)
	_scatter(diorama, rng, ["Tree_Bare_1_A_Color1", "Tree_Bare_2_A_Color1"], 12, Rect2(-21, -11, 42, 22), 2.6, Vector2(0.5, 0.85))
	_scatter(diorama, rng, ["Rock_1_A_Color1", "Rock_1_D_Color1", "Rock_2_A_Color1", "Rock_3_A_Color1", "Rock_3_C_Color1", "Rock_3_F_Color1"], 40, Rect2(-21, -11, 42, 22), 2.0, Vector2(0.6, 1.3), false)
	_scatter(diorama, rng, ["Bush_4_A_Color1", "Bush_3_A_Color1"], 20, Rect2(-21, -11, 42, 22), 2.0, Vector2(0.5, 0.8))
	var exit: Vector3 = diorama.route.sample_baked(diorama.route.get_baked_length())
	_flag(diorama, _on_ground(diorama, exit + Vector3(-1.4, 0.1, -1.4)), Color("b8442e"))
	_flag(diorama, _on_ground(diorama, exit + Vector3(1.4, 0.1, -1.4)), Color("b8442e"))
	for spot: Vector3 in [Vector3(15, 0.1, -9.5), Vector3(-17, 0.1, 10.0)]:
		var camp: Vector3 = _on_ground(diorama, spot)
		if _free(diorama, camp, 2.2, 2.0):
			SceneCraft3D.cylinder(diorama, 0.45, 0.12, camp, stratum, 10)
			_smoke(diorama, camp + Vector3(0, 0.3, 0), Color(0.6, 0.55, 0.5, 0.5))


# --- Pântano Sombrio: drowned ruins around a misty lake -----------------------------------

static func _swamp_lake(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9909
	_entrances(diorama, rng)
	var lake_center: Vector3 = Vector3(-14, 0, -0.5)
	_pond(diorama, lake_center, Vector2(3.2, 2.0))
	_reeds(diorama, rng, lake_center, 3.5, 26)
	var pad: StandardMaterial3D = SceneCraft3D.material(Color("4f7a43"))
	for index in range(9):
		var angle: float = rng.randf_range(0, TAU)
		var leaf: MeshInstance3D = SceneCraft3D.cylinder(diorama, rng.randf_range(0.18, 0.3), 0.02, lake_center + Vector3(cos(angle) * rng.randf_range(0.4, 2.6), 0.14, sin(angle) * rng.randf_range(0.3, 1.6)), pad, 10)
		leaf.scale.z = 0.8
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("6f7d76"), 0.95)
	var moss: StandardMaterial3D = SceneCraft3D.material(Color("5d7046"))
	var rune: StandardMaterial3D = SceneCraft3D.material(Color("b9a4e0"))
	rune.emission_enabled = true
	rune.emission = Color("8c6fd0")
	rune.emission_energy_multiplier = 0.9
	# Broken colonnade framing the board; glowing runes pulse in the mist.
	for index in range(16):
		var point: Vector3 = Vector3(-20 + index * 2.7, 0.1, -11.8 if index % 2 == 0 else 11.6)
		if not _free(diorama, point, 2.6, 2.2): continue
		var column: Node3D = Node3D.new()
		column.name = "RunicRuin%d" % index
		column.position = _on_ground(diorama, point)
		column.rotation.z = rng.randf_range(-0.12, 0.12)
		diorama.add_child(column)
		var height: float = rng.randf_range(1.2, 3.0)
		SceneCraft3D.box(column, Vector3(1.2, 0.25, 1.2), Vector3(0, 0.12, 0), stone)
		SceneCraft3D.cylinder(column, 0.42, height, Vector3(0, height / 2, 0), stone, 8)
		SceneCraft3D.box(column, Vector3(0.95, 0.2, 0.95), Vector3(0, height, 0), moss)
		var glyph: MeshInstance3D = SceneCraft3D.box(column, Vector3(0.2, 0.2, 0.04), Vector3(0, height * 0.6, 0.43), rune)
		glyph.rotation.z = PI / 4
	_scatter(diorama, rng, ["Tree_3_A_Color1", "Tree_1_B_Color1", "Tree_4_B_Color1"], 12, Rect2(-21, -11.5, 42, 23), 3.0, Vector2(0.55, 0.9))
	_scatter(diorama, rng, ["Bush_1_C_Color1", "Grass_2_A_Color1"], 26, Rect2(-21, -11, 42, 22), 1.9, Vector2(0.6, 1.1))
	_scatter(diorama, rng, ["Rock_1_D_Color1", "Rock_3_C_Color1"], 14, Rect2(-21, -11, 42, 22), 2.0, Vector2(0.5, 0.9), false)
	diorama._build_swamp_hero()
	var exit: Vector3 = diorama.route.sample_baked(diorama.route.get_baked_length())
	_flag(diorama, _on_ground(diorama, exit + Vector3(-1.3, 0.1, 1.3)), Color("6a4f9c"))
	_smoke(diorama, _on_ground(diorama, exit + Vector3(1.6, 0.4, 1.4)), Color(0.7, 0.9, 0.75, 0.35))


# --- shared vale pieces --------------------------------------------------------------------

## Woods and undergrowth common to the vale maps: a sparse wood line, groves on the flanks, bushes and
## rocks, none of it tall enough to hide a road from the camera.
static func _vale_woods(diorama: Diorama3D, rng: RandomNumberGenerator, groves: int) -> void:
	var trees: Array = ["Tree_1_A_Color1", "Tree_1_B_Color1", "Tree_2_A_Color1", "Tree_2_B_Color1", "Tree_3_A_Color1", "Tree_4_A_Color1", "Tree_4_B_Color1"]
	_scatter(diorama, rng, trees, 30, Rect2(-30, -18, 60, 6.4), 2.6, Vector2(0.65, 1.05))
	_scatter(diorama, rng, trees, 10, Rect2(-30, -11, 8.5, 20), 2.6, Vector2(0.6, 1.0))
	_scatter(diorama, rng, trees, 8, Rect2(22, -11, 8, 20), 2.6, Vector2(0.6, 1.0))
	_scatter(diorama, rng, trees, groves, Rect2(-20, -10, 37, 20), 3.4, Vector2(0.55, 0.85))
	_scatter(diorama, rng, ["Bush_1_A_Color1", "Bush_1_C_Color1", "Bush_2_C_Color1", "Bush_3_A_Color1", "Bush_4_A_Color1"], 40, Rect2(-21, -11, 40, 22), 2.0, Vector2(0.6, 1.1))
	_scatter(diorama, rng, ["Rock_1_A_Color1", "Rock_1_D_Color1", "Rock_3_A_Color1", "Rock_3_C_Color1"], 16, Rect2(-21, -11, 40, 22), 2.2, Vector2(0.5, 0.9), false)


## Split-rail fences along stretches of every road, following the ground.
static func _road_fences(diorama: Diorama3D, color: Color) -> void:
	var wood: StandardMaterial3D = SceneCraft3D.material(color)
	for road: Curve3D in diorama.all_ground_routes:
		var distance: float = 6.0
		while distance < road.get_baked_length() - 6.0:
			var here: Vector3 = road.sample_baked(distance)
			var ahead: Vector3 = road.sample_baked(distance + 0.6)
			var side: Vector3 = Vector3(-(ahead - here).z, 0, (ahead - here).x).normalized() * 1.7
			for sign: float in [-1.0, 1.0]:
				var post: Vector3 = here + side * sign
				var next: Vector3 = road.sample_baked(distance + 1.1) + side * sign
				if diorama._distance_from_route(post) < 1.55 or diorama._is_reserved(post, 1.6): continue
				if absf(post.x - diorama.river_x) < diorama.river_width * 0.5 + 1.0: continue
				post.y = diorama.terrain_height(post)
				next.y = diorama.terrain_height(next)
				SceneCraft3D.box(diorama, Vector3(0.1, 0.55, 0.1), post + Vector3(0, 0.3, 0), wood)
				SceneCraft3D.beam(diorama, post + Vector3(0, 0.42, 0), next + Vector3(0, 0.42, 0), 0.05, wood)
			distance += 1.1 if int(distance / 9.0) % 2 == 0 else 4.0


## A small fruit tree: KayKit crown with red fruit, stepping aside for towers like other scenery.
static func _fruit_tree(diorama: Diorama3D, rng: RandomNumberGenerator, point: Vector3, fruit: StandardMaterial3D) -> void:
	var size: float = rng.randf_range(0.42, 0.52)
	var tree: Node3D = _prop(diorama, "Tree_1_A_Color1" if rng.randf() < 0.5 else "Tree_2_A_Color1", point, size, rng.randf_range(-PI, PI))
	for index in range(6):
		var angle: float = index * TAU / 6 + rng.randf_range(-0.3, 0.3)
		SceneCraft3D.sphere(tree, 0.22, Vector3(sin(angle) * 1.7, rng.randf_range(2.6, 3.6), cos(angle) * 1.7), fruit)


static func _haystack(diorama: Diorama3D, point: Vector3) -> void:
	var stack: Node3D = Node3D.new()
	stack.position = _on_ground(diorama, point)
	stack.add_to_group(SCENERY_GROUP)
	diorama.add_child(stack)
	var hay: StandardMaterial3D = SceneCraft3D.material(Color("d8b45c"), 0.95)
	SceneCraft3D.cylinder(stack, 0.55, 0.7, Vector3(0, 0.35, 0), hay, 12)
	var top: CylinderMesh = CylinderMesh.new()
	top.top_radius = 0.05
	top.bottom_radius = 0.6
	top.height = 0.6
	top.radial_segments = 12
	SceneCraft3D.mesh(stack, top, Vector3(0, 1.0, 0), hay)


static func _barn(diorama: Diorama3D, point: Vector3, angle: float) -> void:
	var barn: Node3D = Node3D.new()
	barn.position = _on_ground(diorama, point)
	barn.rotation.y = angle
	barn.add_to_group(SCENERY_GROUP)
	diorama.add_child(barn)
	var red: StandardMaterial3D = SceneCraft3D.material(Color("9c3b2f"))
	var trim: StandardMaterial3D = SceneCraft3D.material(Color("efe6d0"))
	var roof: StandardMaterial3D = SceneCraft3D.material(Color("5b4a3d"))
	SceneCraft3D.box(barn, Vector3(3.4, 2.2, 2.6), Vector3(0, 1.1, 0), red)
	var gable: PrismMesh = PrismMesh.new()
	gable.size = Vector3(3.8, 1.6, 3.0)
	var top: MeshInstance3D = SceneCraft3D.mesh(barn, gable, Vector3(0, 3.0, 0), roof)
	top.rotation.y = PI / 2
	SceneCraft3D.box(barn, Vector3(1.4, 1.6, 0.08), Vector3(0, 0.8, 1.31), trim)
	SceneCraft3D.box(barn, Vector3(1.2, 1.4, 0.1), Vector3(0, 0.8, 1.33), red)
	for sign: float in [-1.0, 1.0]: SceneCraft3D.beam(barn, Vector3(sign * 0.6, 0.15, 1.36), Vector3(-sign * 0.6, 1.45, 1.36), 0.08, trim)


# --- Pomar Cercado: an orchard hillside the road crosses in switchbacks ----------------------

static func _vale_terraces(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2202
	_entrances(diorama, rng)
	_vale_woods(diorama, rng, 4)
	var fruit: StandardMaterial3D = SceneCraft3D.material(Color("c8452f"), 0.6)
	# Orchard rows on the open slopes and in loose lines along the terraces.
	for row_z: float in [-10.6, 7.6, 9.2, 10.8]:
		var x: float = -20.0
		while x < 17.0:
			var point: Vector3 = Vector3(x + rng.randf_range(-0.3, 0.3), 0, row_z + rng.randf_range(-0.25, 0.25))
			if _free(diorama, point, 2.4, 2.4) and not _hides_road(diorama, point, 2.0): _fruit_tree(diorama, rng, point, fruit)
			x += 2.6
	for zone: Rect2 in [Rect2(-20, -6, 4.5, 9), Rect2(14.5, -1, 3, 8)]:
		var z: float = zone.position.y
		while z < zone.end.y:
			var x: float = zone.position.x
			while x < zone.end.x:
				var point: Vector3 = Vector3(x, 0, z)
				if _free(diorama, point, 2.4, 2.4): _fruit_tree(diorama, rng, point, fruit)
				x += 2.4
			z += 2.6
	# Dry-stone walls hold each terrace: a low wall on the downhill (south) side of the long legs.
	var wall: StandardMaterial3D = SceneCraft3D.material(Color("a39c86"), 0.95)
	var road: Curve3D = diorama.route
	var distance: float = 4.0
	while distance < road.get_baked_length() - 4.0:
		var here: Vector3 = road.sample_baked(distance)
		var tangent: Vector3 = road.sample_baked(distance + 0.5) - here
		if absf(tangent.x) > absf(tangent.z) * 2.5:
			var stone: Vector3 = here + Vector3(0, 0, 1.75)
			if diorama._distance_from_route(stone) > 1.5 and not diorama._is_reserved(stone, 1.4):
				var block: MeshInstance3D = SceneCraft3D.box(diorama, Vector3(0.62, 0.32, 0.36), _on_ground(diorama, stone) + Vector3(0, 0.1, 0), wall)
				block.rotation.y = atan2(-tangent.z, tangent.x) + rng.randf_range(-0.08, 0.08)
		distance += 0.6
	# Farm at the bottom of the hill where the road ends: barn, farmhouse, haystacks and beehives.
	var exit: Vector3 = diorama.route.sample_baked(diorama.route.get_baked_length())
	var barn_spot: Vector3 = exit + Vector3(-1.6, 0, -3.2)
	if _free(diorama, barn_spot, 2.2, 2.2): _barn(diorama, barn_spot, 0.15)
	var house_spot: Vector3 = exit + Vector3(-5.0, 0, -2.6)
	if _free(diorama, house_spot, 2.2, 2.2): _house(diorama, _on_ground(diorama, house_spot), -0.25, Color("a8543c"), true)
	for offset: Vector3 in [Vector3(-3.5, 0, 1.6), Vector3(-4.6, 0, 2.2), Vector3(1.8, 0, -1.6)]:
		if _free(diorama, exit + offset, 1.8, 1.8): _haystack(diorama, exit + offset)
	var hive: StandardMaterial3D = SceneCraft3D.material(Color("e2c37a"))
	for index in range(4):
		var spot: Vector3 = Vector3(-18.5 + index * 1.2, 0, 6.2)
		if _free(diorama, spot, 1.6, 1.6):
			var box: Node3D = Node3D.new()
			box.position = _on_ground(diorama, spot)
			box.add_to_group(SCENERY_GROUP)
			diorama.add_child(box)
			for level in range(3): SceneCraft3D.box(box, Vector3(0.5 - level * 0.04, 0.22, 0.42), Vector3(0, 0.12 + level * 0.23, 0), hive)
	_flag(diorama, _on_ground(diorama, exit + Vector3(1.2, 0.1, -1.4)), Color("2f7f86"))
	_road_fences(diorama, Color("8a6a45"))


# --- Travessia do Rio: a wavy road down to a river crossing, with a watermill and ponds --------

static func _vale_river(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3303
	_entrances(diorama, rng)
	_vale_woods(diorama, rng, 6)
	# Watermill on the east bank with a turning wheel in the current.
	var mill: Node3D = Node3D.new()
	mill.name = "Watermill"
	mill.position = _on_ground(diorama, Vector3(diorama.river_x + diorama.river_width * 0.5 + 1.6, 0, -2.0))
	mill.add_to_group(SCENERY_GROUP)
	diorama.add_child(mill)
	var plaster: StandardMaterial3D = SceneCraft3D.material(Color("e5d8bb"))
	var timber: StandardMaterial3D = SceneCraft3D.material(Color("6e5136"))
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("9d978a"), 0.95)
	SceneCraft3D.box(mill, Vector3(2.6, 0.5, 2.4), Vector3(0, 0.25, 0), stone)
	SceneCraft3D.box(mill, Vector3(2.4, 1.8, 2.2), Vector3(0, 1.4, 0), plaster)
	for x: float in [-1.15, 1.15]: SceneCraft3D.box(mill, Vector3(0.14, 1.85, 2.25), Vector3(x, 1.4, 0), timber)
	var gable: PrismMesh = PrismMesh.new()
	gable.size = Vector3(2.9, 1.3, 2.7)
	SceneCraft3D.mesh(mill, gable, Vector3(0, 2.95, 0), SceneCraft3D.material(Color("8c4b36")))
	var wheel: Node3D = Node3D.new()
	wheel.position = Vector3(-1.75, 1.0, 0)
	mill.add_child(wheel)
	for spoke in range(8):
		var arm: Node3D = Node3D.new()
		arm.rotation.x = spoke * TAU / 8
		wheel.add_child(arm)
		SceneCraft3D.box(arm, Vector3(0.12, 0.08, 1.9), Vector3(0, 0, 0), timber)
		SceneCraft3D.box(arm, Vector3(0.5, 0.35, 0.08), Vector3(0, 0, 0.95), timber)
	var hub: MeshInstance3D = SceneCraft3D.cylinder(wheel, 0.2, 0.4, Vector3.ZERO, stone, 10)
	hub.rotation.z = PI / 2
	var turning: Tween = wheel.create_tween().set_loops()
	turning.tween_property(wheel, "rotation:x", -TAU, 6.0).as_relative()
	_smoke(mill, Vector3(0.7, 3.4, -0.6))
	# Ponds with reeds and lily pads in the open ground on both banks.
	var pad: StandardMaterial3D = SceneCraft3D.material(Color("4f7a43"))
	for center: Vector3 in [Vector3(-5.5, 0, -1.5), Vector3(5.0, 0, 2.0)]:
		if not _free(diorama, center, 3.2, 2.6): continue
		var pond_center: Vector3 = _on_ground(diorama, center)
		_pond(diorama, pond_center, Vector2(1.9, 1.3))
		_reeds(diorama, rng, pond_center, 2.1, 10)
		for leaf in range(4):
			var angle: float = rng.randf_range(0, TAU)
			SceneCraft3D.cylinder(diorama, 0.2, 0.02, pond_center + Vector3(cos(angle) * 1.0, 0.14, sin(angle) * 0.7), pad, 10)
	# Fishing dock and a rowboat on the west bank.
	var dock: Vector3 = _on_ground(diorama, Vector3(diorama.river_x - diorama.river_width * 0.5 - 0.4, 0, 3.2))
	var plank: StandardMaterial3D = SceneCraft3D.material(Color("8a6a45"))
	SceneCraft3D.box(diorama, Vector3(2.2, 0.1, 1.0), dock + Vector3(0.6, 0.25, 0), plank)
	for z: float in [-0.4, 0.4]: SceneCraft3D.cylinder(diorama, 0.07, 0.6, dock + Vector3(1.5, 0.05, z), timber, 6)
	var boat: MeshInstance3D = SceneCraft3D.box(diorama, Vector3(0.7, 0.25, 1.6), Vector3(diorama.river_x - 0.2, 0.2, 4.6), timber)
	boat.rotation.y = 0.3
	# Wildflower meadow patches.
	var petals: Array[StandardMaterial3D] = [SceneCraft3D.material(Color("f2e05c")), SceneCraft3D.material(Color("e8f0f4")), SceneCraft3D.material(Color("c86ab8"))]
	for index in range(160):
		var point: Vector3 = Vector3(rng.randf_range(-20, 17), 0, rng.randf_range(-10, 10))
		if not _free(diorama, point, 1.7, 1.4): continue
		SceneCraft3D.sphere(diorama, 0.07, _on_ground(diorama, point) + Vector3(0, 0.12, 0), petals[index % 3])
	var exit: Vector3 = diorama.route.sample_baked(diorama.route.get_baked_length())
	for spot: Vector3 in [exit + Vector3(-2.6, 0, 2.6), exit + Vector3(1.0, 0, 3.2)]:
		if _free(diorama, spot, 2.3, 2.3): _house(diorama, _on_ground(diorama, spot), rng.randf_range(-0.4, 0.4), Color("4f6f9a"), true)
	_flag(diorama, _on_ground(diorama, exit + Vector3(-1.2, 0.1, 1.3)), Color("2f7f86"))
	_road_fences(diorama, Color("8a6a45"))


# --- Portão da Guarda: the road spirals up a hill to the guard fort at its top ---------------

static func _vale_hillfort(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4404
	_entrances(diorama, rng)
	_vale_woods(diorama, rng, 3)
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("a3a48f"), 0.95)
	var dark: StandardMaterial3D = SceneCraft3D.material(Color("7b7d70"), 0.95)
	var roof: StandardMaterial3D = SceneCraft3D.material(Color("506c76"))
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("72543b"))
	var road: Curve3D = diorama.route
	var exit: Vector3 = road.sample_baked(road.get_baked_length())
	var arrival: Vector3 = (exit - road.sample_baked(road.get_baked_length() - 2.0))
	arrival.y = 0
	arrival = arrival.normalized()
	# Keep: a squat tower with a slate cone past the end of the road.
	var keep: Node3D = Node3D.new()
	keep.name = "GuardKeep"
	keep.position = _on_ground(diorama, exit + arrival * 2.4)
	diorama.add_child(keep)
	SceneCraft3D.cylinder(keep, 1.5, 3.6, Vector3(0, 1.8, 0), stone, 12)
	SceneCraft3D.cylinder(keep, 1.7, 0.4, Vector3(0, 3.7, 0), dark, 12)
	for index in range(8):
		var angle: float = index * TAU / 8
		SceneCraft3D.box(keep, Vector3(0.45, 0.45, 0.45), Vector3(cos(angle) * 1.5, 4.1, sin(angle) * 1.5), dark)
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.3
	cone.height = 1.8
	cone.radial_segments = 12
	SceneCraft3D.mesh(keep, cone, Vector3(0, 5.0, 0), roof)
	_flag(keep, Vector3(0, 5.6, 0), Color("2f5f8c"), 1.6)
	# Gatehouse across the last stretch of road: two round towers and a raised portcullis.
	var gate: Node3D = _entrance_frame(diorama, road, "GuardGate")
	gate.position = _on_ground(diorama, road.sample_baked(road.get_baked_length() - 1.2))
	gate.basis = Basis(Vector3(-arrival.z, 0, arrival.x), Vector3.UP, -arrival)
	for sign: float in [-1.0, 1.0]:
		SceneCraft3D.cylinder(gate, 0.66, 3.0, Vector3(sign * 1.65, 1.5, 0), stone, 10)
		SceneCraft3D.cylinder(gate, 0.78, 0.25, Vector3(sign * 1.65, 3.0, 0), dark, 10)
		var cap: CylinderMesh = CylinderMesh.new()
		cap.top_radius = 0
		cap.bottom_radius = 0.85
		cap.height = 1.2
		cap.radial_segments = 10
		SceneCraft3D.mesh(gate, cap, Vector3(sign * 1.65, 3.7, 0), roof)
	SceneCraft3D.box(gate, Vector3(3.1, 0.7, 0.75), Vector3(0, 2.6, 0), stone)
	for x: float in [-1.0, -0.5, 0.0, 0.5, 1.0]: SceneCraft3D.box(gate, Vector3(0.1, 0.5, 0.1), Vector3(x, 2.05, 0), wood)
	# Ring of curtain wall around the hilltop, broken where the road climbs in.
	var radius: float = 4.2
	for index in range(28):
		var angle: float = index * TAU / 28
		var point: Vector3 = exit + arrival * 2.4 + Vector3(cos(angle), 0, sin(angle)) * radius
		if diorama._distance_from_route(point) < 1.8 or diorama._is_reserved(point, 1.7): continue
		var piece: MeshInstance3D = SceneCraft3D.box(diorama, Vector3(1.0, 1.4, 0.6), _on_ground(diorama, point) + Vector3(0, 0.6, 0), stone)
		piece.rotation.y = -angle + PI / 2
		if index % 2 == 0: SceneCraft3D.box(diorama, Vector3(0.4, 0.35, 0.6), _on_ground(diorama, point) + Vector3(0, 1.45, 0), dark)
	# Army camp below the hill: tents, a campfire and straw targets.
	var canvas: Array[StandardMaterial3D] = [SceneCraft3D.material(Color("d9cfb4")), SceneCraft3D.material(Color("b55b45"))]
	for index in range(6):
		var point: Vector3 = Vector3(rng.randf_range(-19, 16), 0, rng.randf_range(-10, 10))
		if not _free(diorama, point, 2.6, 2.6) or point.distance_to(Vector3(exit.x, 0, exit.z)) < 8.0: continue
		var tent: PrismMesh = PrismMesh.new()
		tent.size = Vector3(1.6, 1.2, 1.9)
		var shelter: MeshInstance3D = SceneCraft3D.mesh(diorama, tent, _on_ground(diorama, point) + Vector3(0, 0.6, 0), canvas[index % 2])
		shelter.rotation.y = rng.randf_range(-PI, PI)
		shelter.add_to_group(SCENERY_GROUP)
	var fire: Vector3 = Vector3(-17.5, 0, 0.5)
	if _free(diorama, fire, 2.0, 2.0):
		SceneCraft3D.cylinder(diorama, 0.4, 0.1, _on_ground(diorama, fire) + Vector3(0, 0.05, 0), dark, 10)
		_smoke(diorama, _on_ground(diorama, fire) + Vector3(0, 0.3, 0), Color(0.6, 0.58, 0.55, 0.5))
	_road_fences(diorama, Color("7a5c3e"))


# --- shared canyon pieces ------------------------------------------------------------------

static func _first_free(diorama: Diorama3D, candidates: Array, road: float, reserved: float) -> Vector3:
	for candidate: Vector3 in candidates:
		if _free(diorama, candidate, road, reserved): return candidate
	return Vector3.INF


## Layered mesas along the top and bottom of the board, as if the canyon walls close in.
static func _canyon_walls(diorama: Diorama3D, rng: RandomNumberGenerator, palette: Array) -> void:
	for edge: float in [-1.0, 1.0]:
		var x: float = -23.0
		while x < 23.0:
			var radius: float = rng.randf_range(1.5, 2.4)
			var point: Vector3 = Vector3(x, 0, edge * rng.randf_range(11.8, 13.6))
			x += radius * 1.35
			if diorama._distance_from_route(point) < radius + 1.4 or absf(point.x - diorama.river_x) < diorama.river_width * 0.5 + radius: continue
			var height: float = rng.randf_range(2.4, 4.6) * (0.65 if edge > 0 else 1.0)
			var mesa: Node3D = Node3D.new()
			mesa.position = _on_ground(diorama, point)
			mesa.rotation.y = rng.randf_range(0, TAU)
			diorama.add_child(mesa)
			for layer in range(4):
				var band: float = height / 4.0
				SceneCraft3D.cylinder(mesa, radius * (1.0 - layer * 0.09) * rng.randf_range(0.95, 1.05), band, Vector3(0, band * (layer + 0.5), 0), palette[layer], 7)


static func _canyon_props(diorama: Diorama3D, rng: RandomNumberGenerator) -> void:
	_scatter(diorama, rng, ["Tree_Bare_1_A_Color1", "Tree_Bare_2_A_Color1"], 10, Rect2(-21, -11, 42, 22), 2.6, Vector2(0.5, 0.85))
	_scatter(diorama, rng, ["Rock_1_A_Color1", "Rock_1_D_Color1", "Rock_2_A_Color1", "Rock_3_A_Color1", "Rock_3_C_Color1", "Rock_3_F_Color1"], 34, Rect2(-21, -11, 42, 22), 2.0, Vector2(0.6, 1.3), false)
	_scatter(diorama, rng, ["Bush_4_A_Color1", "Bush_3_A_Color1"], 16, Rect2(-21, -11, 42, 22), 2.0, Vector2(0.5, 0.8))


static func _canyon_palette() -> Array:
	return [SceneCraft3D.material(Color("b06a46")), SceneCraft3D.material(Color("7d4836")), SceneCraft3D.material(Color("b06a46")), SceneCraft3D.material(Color("c2804f"))]


static func _ore_cart(parent: Node3D, point: Vector3, angle: float, rng: RandomNumberGenerator) -> void:
	var iron: StandardMaterial3D = SceneCraft3D.material(Color("3d3b39"), 0.5, 0.7)
	var timber: StandardMaterial3D = SceneCraft3D.material(Color("6b4a2e"), 0.92)
	var cart: Node3D = Node3D.new()
	cart.position = point
	cart.rotation.y = angle
	cart.add_to_group(SCENERY_GROUP)
	parent.add_child(cart)
	SceneCraft3D.box(cart, Vector3(0.9, 0.55, 1.2), Vector3(0, 0.45, 0), iron)
	for z: float in [-0.4, 0.4]:
		for sign: float in [-1.0, 1.0]:
			var wheel: MeshInstance3D = SceneCraft3D.cylinder(cart, 0.16, 0.08, Vector3(sign * 0.45, 0.16, z), timber, 10)
			wheel.rotation.z = PI / 2
	for ore in range(4): SceneCraft3D.sphere(cart, 0.16, Vector3(rng.randf_range(-0.2, 0.2), 0.8, rng.randf_range(-0.35, 0.35)), SceneCraft3D.material(Color("b9ad98"), 0.9))


# --- Pedreira dos Gigantes: a working quarry with a crane, cut blocks and ore carts ----------

static func _canyon_quarry(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6606
	_entrances(diorama, rng)
	_canyon_walls(diorama, rng, _canyon_palette())
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("cdbf9f"), 0.9)
	var cut: StandardMaterial3D = SceneCraft3D.material(Color("b8aa91"), 0.9)
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("694632"))
	var steel: StandardMaterial3D = SceneCraft3D.material(Color("778080"), 0.6, 0.6)
	# Stepped quarry face: terraces of pale stone cut into the hillside.
	var face: Vector3 = _first_free(diorama, [Vector3(5, 0, 0.5), Vector3(4, 0, 1.5), Vector3(16, 0, 5)], 3.6, 3.0)
	if face != Vector3.INF:
		var pit: Node3D = Node3D.new()
		pit.name = "QuarryFace"
		pit.position = _on_ground(diorama, face)
		diorama.add_child(pit)
		for step in range(4):
			var size: float = 3.4 - step * 0.7
			var slab: MeshInstance3D = SceneCraft3D.box(pit, Vector3(size, 0.45, size * 0.8), Vector3(0, 0.22 + step * 0.45, -step * 0.25), stone if step % 2 == 0 else cut)
			slab.rotation.y = 0.2
		# Crane over the face hoisting a block.
		var crane: Node3D = Node3D.new()
		crane.position = Vector3(-1.6, 0, 0.8)
		pit.add_child(crane)
		for x: float in [-0.5, 0.5]: SceneCraft3D.box(crane, Vector3(0.22, 3.6, 0.22), Vector3(x, 1.8, 0), wood)
		SceneCraft3D.box(crane, Vector3(4.4, 0.26, 0.26), Vector3(1.6, 3.5, 0), wood)
		SceneCraft3D.beam(crane, Vector3(3.5, 3.5, 0), Vector3(3.5, 2.2, 0), 0.04, steel)
		var block: MeshInstance3D = SceneCraft3D.box(crane, Vector3(0.8, 0.6, 0.6), Vector3(3.5, 1.9, 0), cut)
		var hoist: Tween = block.create_tween().set_loops()
		hoist.tween_property(block, "position:y", 2.6, 2.5).set_trans(Tween.TRANS_SINE)
		hoist.tween_property(block, "position:y", 1.9, 2.5).set_trans(Tween.TRANS_SINE)
	# Stacks of cut blocks and carts along the quarry track.
	for index in range(10):
		var point: Vector3 = Vector3(rng.randf_range(-18, 17), 0, rng.randf_range(-10, 10))
		if not _free(diorama, point, 2.2, 2.0): continue
		var pile: Node3D = Node3D.new()
		pile.position = _on_ground(diorama, point)
		pile.rotation.y = rng.randf_range(0, TAU)
		pile.add_to_group(SCENERY_GROUP)
		diorama.add_child(pile)
		for level in range(rng.randi_range(1, 3)): SceneCraft3D.box(pile, Vector3(0.9, 0.5, 0.6), Vector3(rng.randf_range(-0.1, 0.1), 0.25 + level * 0.5, 0), stone if level % 2 == 0 else cut)
	var track: Vector3 = _first_free(diorama, [Vector3(14, 0, 4), Vector3(15, 0, 7), Vector3(-17, 0, -8)], 2.4, 2.4)
	if track != Vector3.INF:
		for sign: float in [-1.0, 1.0]: SceneCraft3D.box(diorama, Vector3(0.06, 0.05, 6.0), _on_ground(diorama, track) + Vector3(sign * 0.45, 0.04, 0), steel)
		for index in range(3): _ore_cart(diorama, _on_ground(diorama, track + Vector3(0, 0, -2.0 + index * 1.6)), 0.0, rng)
	_canyon_props(diorama, rng)
	var exit: Vector3 = diorama.route.sample_baked(diorama.route.get_baked_length())
	_flag(diorama, _on_ground(diorama, exit + Vector3(-1.4, 0.1, -1.4)), Color("b8442e"))


# --- Fortaleza Quebrada: a ruined border fort whose broken walls the roads pass through -------

static func _canyon_fortress(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7707
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("8d8b7d"), 0.95)
	var dark: StandardMaterial3D = SceneCraft3D.material(Color("5f665f"), 0.95)
	var cloth: StandardMaterial3D = SceneCraft3D.material(Color("7e2f2a"))
	# Every entrance is a breach in the curtain wall: wall stubs either side and fallen stones.
	for index in range(diorama.all_ground_routes.size()):
		var breach: Node3D = _entrance_frame(diorama, diorama.all_ground_routes[index], "WallBreach%d" % index)
		for sign: float in [-1.0, 1.0]:
			var x: float = 2.0
			while x < 8.0:
				var height: float = rng.randf_range(1.4, 3.4) * (1.0 - (x - 2.0) * 0.06)
				SceneCraft3D.box(breach, Vector3(1.5, height, 1.0), Vector3(sign * x, height * 0.5, 0.4), stone)
				if rng.randf() < 0.6: SceneCraft3D.box(breach, Vector3(0.6, 0.55, 1.1), Vector3(sign * x, height + 0.27, 0.4), dark)
				x += 1.5
			SceneCraft3D.cylinder(breach, 1.2, 4.2, Vector3(sign * 2.4, 2.1, 0.6), stone, 10)
			SceneCraft3D.cylinder(breach, 1.35, 0.3, Vector3(sign * 2.4, 4.2, 0.6), dark, 10)
			var banner: MeshInstance3D = SceneCraft3D.box(breach, Vector3(0.7, 1.4, 0.05), Vector3(sign * 2.4, 2.8, -0.65), cloth)
			banner.rotation.z = sign * 0.08
		for chunk in range(6):
			var piece: MeshInstance3D = SceneCraft3D.box(breach, Vector3(0.7, 0.45, 0.6), Vector3(rng.randf_range(-3.5, 3.5), 0.22, rng.randf_range(-2.4, -1.4)), dark)
			piece.rotation.y = rng.randf_range(0, PI)
	_canyon_walls(diorama, rng, _canyon_palette())
	# The old keep stands broken in the middle of the board.
	var keep_spot: Vector3 = _first_free(diorama, [Vector3(13, 0, -2), Vector3(14, 0, 0), Vector3(-12, 0, -8)], 3.2, 2.8)
	if keep_spot != Vector3.INF:
		var keep: Node3D = Node3D.new()
		keep.name = "BrokenKeep"
		keep.position = _on_ground(diorama, keep_spot)
		diorama.add_child(keep)
		SceneCraft3D.box(keep, Vector3(3.0, 3.6, 3.0), Vector3(0, 1.8, 0), stone)
		SceneCraft3D.box(keep, Vector3(1.6, 1.4, 3.0), Vector3(-0.7, 4.3, 0), stone)
		for x: float in [-1.2, 0.0]: SceneCraft3D.box(keep, Vector3(0.6, 0.6, 3.1), Vector3(x, 5.2, 0), dark)
		SceneCraft3D.box(keep, Vector3(0.9, 1.4, 0.1), Vector3(0.4, 0.7, 1.52), SceneCraft3D.material(Color("1d1714")))
		_smoke(keep, Vector3(0.8, 3.8, 0.6), Color(0.5, 0.48, 0.45, 0.45))
	_canyon_props(diorama, rng)
	var exit: Vector3 = diorama.route.sample_baked(diorama.route.get_baked_length())
	_flag(diorama, _on_ground(diorama, exit + Vector3(1.4, 0.1, -1.4)), Color("3a5f8c"))


# --- Forja do Colosso: a giant's forge with glowing furnaces and lava channels ---------------

static func _canyon_forge(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 8808
	_entrances(diorama, rng)
	_canyon_walls(diorama, rng, [SceneCraft3D.material(Color("8e5440")), SceneCraft3D.material(Color("5b3a32")), SceneCraft3D.material(Color("8e5440")), SceneCraft3D.material(Color("a86a48"))])
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("626b66"), 0.95)
	var steel: StandardMaterial3D = SceneCraft3D.material(Color("3f4b4b"), 0.55, 0.6)
	var ember: StandardMaterial3D = SceneCraft3D.material(Color("ff9a3c"))
	ember.emission_enabled = true
	ember.emission = Color("ff6a1f")
	ember.emission_energy_multiplier = 2.2
	# Two furnaces with smoking chimneys and glowing mouths.
	var placed: int = 0
	for candidate: Vector3 in [Vector3(-12, 0, -1), Vector3(-10, 0, 1.5), Vector3(-15, 0, 0), Vector3(3.5, 0, -0.5), Vector3(-6, 0, -1)]:
		if placed >= 2 or not _free(diorama, candidate, 3.0, 2.8): continue
		placed += 1
		var furnace: Node3D = Node3D.new()
		furnace.name = "Furnace%d" % placed
		furnace.position = _on_ground(diorama, candidate)
		diorama.add_child(furnace)
		SceneCraft3D.cylinder(furnace, 1.6, 0.35, Vector3(0, 0.18, 0), stone, 10)
		SceneCraft3D.box(furnace, Vector3(2.3, 2.5, 1.9), Vector3(0, 1.55, 0), stone)
		SceneCraft3D.box(furnace, Vector3(1.1, 0.8, 0.12), Vector3(0, 0.9, 1.0), ember)
		for x: float in [-0.5, 0.0, 0.5]: SceneCraft3D.box(furnace, Vector3(0.07, 0.9, 0.1), Vector3(x, 0.9, 1.07), steel)
		SceneCraft3D.cylinder(furnace, 0.5, 2.2, Vector3(0.5, 3.8, -0.3), stone, 8)
		_smoke(furnace, Vector3(0.5, 5.0, -0.3), Color(0.32, 0.3, 0.3, 0.6))
		var glow: OmniLight3D = OmniLight3D.new()
		glow.light_color = Color("ff8a3d")
		glow.light_energy = 1.4
		glow.omni_range = 4.0
		glow.position = Vector3(0, 1.0, 1.6)
		furnace.add_child(glow)
	# Lava channels: glowing cracks in the ground, away from roads and build spots.
	for index in range(14):
		var point: Vector3 = Vector3(rng.randf_range(-19, 17), 0, rng.randf_range(-10, 10))
		if not _free(diorama, point, 2.4, 2.2): continue
		var crack: MeshInstance3D = SceneCraft3D.box(diorama, Vector3(rng.randf_range(1.2, 2.6), 0.04, 0.16), _on_ground(diorama, point) + Vector3(0, 0.08, 0), ember)
		crack.rotation.y = rng.randf_range(0, PI)
	# Anvils and stacked ingots.
	for index in range(5):
		var point: Vector3 = Vector3(rng.randf_range(-18, 17), 0, rng.randf_range(-10, 10))
		if not _free(diorama, point, 2.2, 2.0): continue
		var anvil: Node3D = Node3D.new()
		anvil.position = _on_ground(diorama, point)
		anvil.rotation.y = rng.randf_range(0, TAU)
		anvil.add_to_group(SCENERY_GROUP)
		diorama.add_child(anvil)
		SceneCraft3D.box(anvil, Vector3(0.9, 0.5, 0.8), Vector3(0, 0.25, 0), stone)
		SceneCraft3D.box(anvil, Vector3(0.55, 0.5, 0.5), Vector3(0, 0.75, 0), steel)
		SceneCraft3D.box(anvil, Vector3(1.3, 0.28, 0.6), Vector3(0.15, 1.12, 0), steel)
	_canyon_props(diorama, rng)
	var exit: Vector3 = diorama.route.sample_baked(diorama.route.get_baked_length())
	_flag(diorama, _on_ground(diorama, exit + Vector3(-1.4, 0.1, -1.4)), Color("b8442e"))


# --- shared swamp pieces -------------------------------------------------------------------

static func _swamp_woods(diorama: Diorama3D, rng: RandomNumberGenerator) -> void:
	_scatter(diorama, rng, ["Tree_3_A_Color1", "Tree_1_B_Color1", "Tree_4_B_Color1"], 30, Rect2(-30, -18, 60, 6.4), 3.0, Vector2(0.6, 1.0))
	_scatter(diorama, rng, ["Tree_3_A_Color1", "Tree_4_B_Color1", "Tree_Bare_1_A_Color1"], 14, Rect2(-21, -11.5, 42, 23), 3.0, Vector2(0.55, 0.9))
	_scatter(diorama, rng, ["Bush_1_C_Color1", "Grass_2_A_Color1"], 30, Rect2(-21, -11, 42, 22), 1.9, Vector2(0.6, 1.1))
	_scatter(diorama, rng, ["Rock_1_D_Color1", "Rock_3_C_Color1"], 12, Rect2(-21, -11, 42, 22), 2.0, Vector2(0.5, 0.9), false)


## Dark pools with reeds and lily pads in the open ground.
static func _swamp_pools(diorama: Diorama3D, rng: RandomNumberGenerator, count: int) -> void:
	var pad: StandardMaterial3D = SceneCraft3D.material(Color("4f7a43"))
	var placed: int = 0
	var attempts: int = 0
	while placed < count and attempts < count * 20:
		attempts += 1
		var center: Vector3 = Vector3(rng.randf_range(-19, 17), 0, rng.randf_range(-10, 10))
		var size: Vector2 = Vector2(rng.randf_range(1.2, 2.2), rng.randf_range(0.8, 1.5))
		if not _free(diorama, center, size.x + 2.0, size.x + 1.6): continue
		var ground: Vector3 = _on_ground(diorama, center)
		_pond(diorama, ground, size)
		_reeds(diorama, rng, ground, size.x + 0.3, 6)
		for leaf in range(3):
			var angle: float = rng.randf_range(0, TAU)
			SceneCraft3D.cylinder(diorama, rng.randf_range(0.15, 0.25), 0.02, ground + Vector3(cos(angle) * size.x * 0.5, 0.14, sin(angle) * size.y * 0.5), pad, 10)
		placed += 1


static func _rune_material(energy: float) -> StandardMaterial3D:
	var rune: StandardMaterial3D = SceneCraft3D.material(Color("c1aef0"))
	rune.emission_enabled = true
	rune.emission = Color("9a7be0")
	rune.emission_energy_multiplier = energy
	return rune


# --- Trilhas Submersas: raised plank trails over a drowned forest with stilt huts --------------

static func _swamp_causeway(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 10010
	_entrances(diorama, rng)
	_swamp_pools(diorama, rng, 9)
	_swamp_woods(diorama, rng)
	# Plank edging and posts along the trails: the roads read as boardwalks over the mud.
	var plank: StandardMaterial3D = SceneCraft3D.material(Color("6f5a40"))
	for road: Curve3D in diorama.all_ground_routes:
		var distance: float = 3.0
		while distance < road.get_baked_length() - 2.0:
			var here: Vector3 = road.sample_baked(distance)
			var ahead: Vector3 = road.sample_baked(distance + 0.8)
			var side: Vector3 = Vector3(-(ahead - here).z, 0, (ahead - here).x).normalized() * 1.2
			for sign: float in [-1.0, 1.0]:
				var edge: Vector3 = here + side * sign
				if diorama._distance_from_route(edge) < 1.1: continue
				var next: Vector3 = ahead + side * sign
				SceneCraft3D.beam(diorama, _on_ground(diorama, edge) + Vector3(0, 0.16, 0), _on_ground(diorama, next) + Vector3(0, 0.16, 0), 0.09, plank)
				if int(distance / 0.8) % 3 == 0: SceneCraft3D.cylinder(diorama, 0.07, 0.6, _on_ground(diorama, edge) + Vector3(0, 0.2, 0), plank, 6)
			distance += 0.8
	# Stilt huts with smoking chimneys standing in the water.
	var built: int = 0
	for index in range(12):
		if built >= 3: break
		var point: Vector3 = Vector3(rng.randf_range(-18, 16), 0, rng.randf_range(-9, 9))
		if not _free(diorama, point, 3.0, 2.8): continue
		built += 1
		var hut: Node3D = Node3D.new()
		hut.name = "StiltHut%d" % built
		hut.position = _on_ground(diorama, point)
		hut.rotation.y = rng.randf_range(-PI, PI)
		hut.add_to_group(SCENERY_GROUP)
		diorama.add_child(hut)
		_pond(diorama, hut.position, Vector2(1.8, 1.5))
		for x: float in [-0.8, 0.8]:
			for z: float in [-0.7, 0.7]: SceneCraft3D.cylinder(hut, 0.08, 1.2, Vector3(x, 0.6, z), plank, 6)
		SceneCraft3D.box(hut, Vector3(2.0, 0.12, 1.8), Vector3(0, 1.2, 0), plank)
		SceneCraft3D.box(hut, Vector3(1.6, 1.1, 1.4), Vector3(0, 1.8, 0), SceneCraft3D.material(Color("5b4a36")))
		var roof: PrismMesh = PrismMesh.new()
		roof.size = Vector3(2.0, 0.9, 1.8)
		SceneCraft3D.mesh(hut, roof, Vector3(0, 2.8, 0), SceneCraft3D.material(Color("6f6a45")))
		_smoke(hut, Vector3(0.5, 3.2, 0), Color(0.7, 0.8, 0.72, 0.4))
	var exit: Vector3 = diorama.route.sample_baked(diorama.route.get_baked_length())
	_flag(diorama, _on_ground(diorama, exit + Vector3(-1.3, 0.1, 1.3)), Color("6a4f9c"))


# --- Ninho das Sombras: twisted roots around a nest of glowing eggs ---------------------------

static func _swamp_nest(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11011
	_entrances(diorama, rng)
	_swamp_pools(diorama, rng, 6)
	_swamp_woods(diorama, rng)
	var bark: StandardMaterial3D = SceneCraft3D.material(Color("3e3328"), 0.95)
	var egg: StandardMaterial3D = SceneCraft3D.material(Color("cdb8f2"))
	egg.emission_enabled = true
	egg.emission = Color("8f62d6")
	egg.emission_energy_multiplier = 1.4
	# The nest: a bowl of interwoven branches beside the end of the road, holding glowing eggs.
	var road: Curve3D = diorama.route
	var exit: Vector3 = road.sample_baked(road.get_baked_length())
	var arrival: Vector3 = exit - road.sample_baked(road.get_baked_length() - 2.0)
	arrival.y = 0
	arrival = arrival.normalized()
	var nest: Node3D = Node3D.new()
	nest.name = "ShadowNest"
	nest.position = _on_ground(diorama, exit + arrival * 2.2)
	diorama.add_child(nest)
	for ring in range(3):
		var radius: float = 1.9 - ring * 0.25
		for index in range(14):
			var a: float = index * TAU / 14 + ring * 0.4
			var b: float = a + TAU / 14 * 1.6
			SceneCraft3D.beam(nest, Vector3(cos(a) * radius, 0.25 + ring * 0.32, sin(a) * radius), Vector3(cos(b) * radius, 0.45 + ring * 0.32, sin(b) * radius), 0.16, bark)
	for index in range(5):
		var angle: float = index * TAU / 5
		var shell: MeshInstance3D = SceneCraft3D.sphere(nest, 0.36, Vector3(cos(angle) * 0.7, 0.55, sin(angle) * 0.7), egg)
		shell.scale = Vector3(0.8, 1.15, 0.8)
		var pulse: Tween = shell.create_tween().set_loops()
		pulse.tween_property(shell, "scale", Vector3(0.86, 1.22, 0.86), 1.2 + index * 0.17).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(shell, "scale", Vector3(0.8, 1.15, 0.8), 1.2 + index * 0.17).set_trans(Tween.TRANS_SINE)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.light_color = Color("a07ae8")
	glow.light_energy = 1.2
	glow.omni_range = 5.0
	glow.position = Vector3(0, 1.2, 0)
	nest.add_child(glow)
	# Giant roots arching out of the mud across open ground.
	for index in range(9):
		var point: Vector3 = Vector3(rng.randf_range(-19, 17), 0, rng.randf_range(-10, 10))
		if not _free(diorama, point, 2.6, 2.4): continue
		var base: Vector3 = _on_ground(diorama, point)
		var reach: Vector3 = Vector3(rng.randf_range(-1.6, 1.6), 0, rng.randf_range(-1.6, 1.6))
		SceneCraft3D.beam(diorama, base, base + reach * 0.5 + Vector3(0, 1.1, 0), 0.24, bark)
		SceneCraft3D.beam(diorama, base + reach * 0.5 + Vector3(0, 1.1, 0), base + reach, 0.2, bark)
	_flag(diorama, _on_ground(diorama, exit + Vector3(-1.3, 0.1, 1.3)), Color("6a4f9c"))


# --- Coração da Ruína: the sanctuary at the heart of the swamp, with a floating crystal -------

static func _swamp_heart(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12012
	_entrances(diorama, rng)
	_swamp_pools(diorama, rng, 6)
	_swamp_woods(diorama, rng)
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("687c70"), 0.95)
	var moss: StandardMaterial3D = SceneCraft3D.material(Color("546a4a"))
	var rune: StandardMaterial3D = _rune_material(1.6)
	var road: Curve3D = diorama.route
	var exit: Vector3 = road.sample_baked(road.get_baked_length())
	var arrival: Vector3 = exit - road.sample_baked(road.get_baked_length() - 2.0)
	arrival.y = 0
	arrival = arrival.normalized()
	# Stepped altar where the roads end, crowned by a slowly turning crystal inside a rune halo.
	var shrine: Node3D = Node3D.new()
	shrine.name = "RuinHeart"
	shrine.position = _on_ground(diorama, exit + arrival * 2.0)
	diorama.add_child(shrine)
	for step in range(3): SceneCraft3D.box(shrine, Vector3(3.0 - step * 0.6, 0.35, 3.0 - step * 0.6), Vector3(0, 0.175 + step * 0.35, 0), stone if step % 2 == 0 else moss)
	var crystal: Node3D = Node3D.new()
	crystal.position = Vector3(0, 2.4, 0)
	shrine.add_child(crystal)
	for sign: float in [-1.0, 1.0]:
		var point: CylinderMesh = CylinderMesh.new()
		point.top_radius = 0.0
		point.bottom_radius = 0.55
		point.height = 1.0
		point.radial_segments = 6
		var half: MeshInstance3D = SceneCraft3D.mesh(crystal, point, Vector3(0, sign * 0.5, 0), rune)
		if sign < 0: half.rotation.z = PI
	var spin: Tween = crystal.create_tween().set_loops()
	spin.tween_property(crystal, "rotation:y", TAU, 8.0).as_relative()
	var hover: Tween = crystal.create_tween().set_loops()
	hover.tween_property(crystal, "position:y", 2.7, 2.0).set_trans(Tween.TRANS_SINE)
	hover.tween_property(crystal, "position:y", 2.4, 2.0).set_trans(Tween.TRANS_SINE)
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 1.15
	ring.outer_radius = 1.25
	ring.rings = 24
	ring.ring_segments = 6
	var halo: MeshInstance3D = SceneCraft3D.mesh(shrine, ring, Vector3(0, 2.4, 0), rune)
	halo.rotation.x = PI / 2.4
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color("a184e8")
	light.light_energy = 1.6
	light.omni_range = 6.0
	light.position = Vector3(0, 2.4, 0)
	shrine.add_child(light)
	# A ring of tall rune pillars around the sanctuary, kept off the roads.
	for index in range(10):
		var angle: float = index * TAU / 10
		var point: Vector3 = shrine.position + Vector3(cos(angle), 0, sin(angle)) * 6.2
		if not _free(diorama, point, 1.9, 1.7): continue
		var pillar: Node3D = Node3D.new()
		pillar.position = _on_ground(diorama, point)
		pillar.rotation.z = rng.randf_range(-0.06, 0.06)
		pillar.add_to_group(SCENERY_GROUP)
		diorama.add_child(pillar)
		var height: float = rng.randf_range(1.6, 2.8)
		SceneCraft3D.box(pillar, Vector3(0.9, 0.25, 0.9), Vector3(0, 0.12, 0), stone)
		SceneCraft3D.cylinder(pillar, 0.32, height, Vector3(0, height / 2, 0), stone, 8)
		SceneCraft3D.box(pillar, Vector3(0.7, 0.16, 0.7), Vector3(0, height, 0), moss)
		var glyph: MeshInstance3D = SceneCraft3D.box(pillar, Vector3(0.18, 0.18, 0.04), Vector3(0, height * 0.6, 0.33), rune)
		glyph.rotation.z = PI / 4
