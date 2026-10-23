## Hand-dressed set pieces for the redesigned maps (one per biome): border hills or cliffs, a lived-in
## landmark with moving parts (smoke, flags, water, swaying plants) and dense props. Presentation only;
## every placement keeps clear of the roads, the build area rule and the authored reference spots.
class_name MapSceneryV2
extends RefCounted

const FLAG_SHADER: String = "res://scripts/presentation3d/flag.gdshader"


static func build(diorama: Diorama3D, scenery: String) -> void:
	match scenery:
		"vale_meadow": _vale_meadow(diorama)
		"canyon_bridges": _canyon_bridges(diorama)
		"swamp_lake": _swamp_lake(diorama)
	if scenery != "vale_meadow": _frame(diorama)


## Beyond the playable board the camera still sees ground on wide screens; fill it so the map never
## ends in an empty plain (forest for the vale, rock shelves for the canyon, dead woods for the swamp).
static func _frame(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4242
	var files: Array = ["Tree_1_A_Color1", "Tree_1_B_Color1", "Tree_2_A_Color1", "Tree_4_A_Color1", "Tree_4_B_Color1", "Bush_1_A_Color1", "Bush_4_A_Color1"]
	if diorama.biome == "canyon": files = ["Rock_3_A_Color1", "Rock_3_C_Color1", "Rock_3_F_Color1", "Rock_1_D_Color1", "Tree_Bare_1_A_Color1"]
	elif diorama.biome == "swamp": files = ["Tree_3_A_Color1", "Tree_1_B_Color1", "Tree_4_B_Color1", "Bush_2_C_Color1"]
	for band: Rect2 in [Rect2(-31, -19, 9.5, 38), Rect2(21.5, -19, 9.5, 38), Rect2(-22, 11.6, 44, 7), Rect2(-22, -19, 44, 6.5)]:
		var count: int = int(band.get_area() / 7.0)
		for index in range(count):
			var point: Vector3 = Vector3(rng.randf_range(band.position.x, band.end.x), 0.06, rng.randf_range(band.position.y, band.end.y))
			if absf(point.x - diorama.river_x) < diorama.river_width * 0.5 + 0.8: continue
			if diorama._distance_from_route(point) < 2.4: continue
			if point.distance_to(diorama.route.sample_baked(diorama.route.get_baked_length())) < 7.0: continue
			var size: float = rng.randf_range(0.8, 1.4) * (1.6 if diorama.biome == "canyon" else 1.0)
			_prop(diorama, str(files[rng.randi() % files.size()]), point, size, rng.randf_range(-PI, PI), diorama.biome != "canyon")


# --- shared pieces -------------------------------------------------------------------------

static func _free(diorama: Diorama3D, point: Vector3, road: float, reserved: float) -> bool:
	if diorama._distance_from_route(point) < road: return false
	if diorama._is_reserved(point, reserved): return false
	return absf(point.x - diorama.river_x) > diorama.river_width * 0.5 + 0.6


static func _prop(diorama: Diorama3D, file: String, point: Vector3, size: float, angle: float, sway: bool = true) -> Node3D:
	var node: Node3D = (load("res://art/models/%s.glb" % file) as PackedScene).instantiate() as Node3D
	node.position = point
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
		_prop(diorama, str(files[rng.randi() % files.size()]), point, rng.randf_range(size.x, size.y), rng.randf_range(-PI, PI), sway)
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
static func _entrance_gate(diorama: Diorama3D, rng: RandomNumberGenerator) -> void:
	var road: Curve3D = diorama.route
	var start: Vector3 = road.sample_baked(2.2)
	var forward: Vector3 = (road.sample_baked(3.2) - road.sample_baked(1.2)).normalized()
	var side: Vector3 = Vector3(-forward.z, 0, forward.x)
	var gate: Node3D = Node3D.new()
	gate.name = "EntranceGate"
	gate.position = start
	gate.basis = Basis(side, Vector3.UP, -forward)
	diorama.add_child(gate)
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


# --- Vale Verde: farm valley with a village, windmill, pond and forest edges ---------------

static func _vale_meadow(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1101
	_entrance_gate(diorama, rng)
	# Realistic vegetation and rocks: camera-matched sprites of CC0 Poly Haven models (art/sprites3d).
	var tall: Array = ["island_tree_01_r0", "island_tree_01_r120", "island_tree_01_r240"]
	var broad: Array = ["island_tree_02_r0", "island_tree_02_r120", "island_tree_02_r240"]
	var shrubs: Array = ["shrub_01", "shrub_04", "shrub_02_0", "shrub_02_1", "shrub_02_2", "shrub_02_3", "fern_02_0", "fern_02_1", "fern_02_2", "fern_02_3"]
	var ground: Array = ["grass_medium_02_0", "grass_medium_02_1", "grass_medium_02_2", "grass_medium_02_3", "grass_medium_02_4", "celandine_01_0", "celandine_01_1", "celandine_01_2", "dandelion_01_0", "dandelion_01_1", "dandelion_01_2"]
	var rocks: Array = ["rock_moss_set_01_0", "rock_moss_set_01_1", "rock_moss_set_01_2", "rock_moss_set_01_3", "rock_moss_set_01_4", "rock_moss_set_01_5", "boulder_01"]
	# Woods hugging the board edges and spilling past them, with clearings left around the exit.
	var exit: Vector3 = diorama.route.sample_baked(diorama.route.get_baked_length())
	var gate: Vector3 = diorama.route.sample_baked(2.2)
	var clear: Array[Vector3] = [exit, gate]
	for band: Array in [[Rect2(-31, -19, 62, 8.6), 150], [Rect2(-31, 10.6, 62, 8.4), 130], [Rect2(-31, -11, 10, 22), 60], [Rect2(21.6, -11, 10, 22), 50]]:
		_sprite_scatter(diorama, rng, tall + broad, int(band[1]), band[0], 2.6, Vector2(4.2, 6.8), clear, 6.5)
	# Copses inside the board, on open ground away from roads and the reference build spots.
	_sprite_scatter(diorama, rng, broad + tall, 16, Rect2(-20, -10, 37, 20), 3.6, Vector2(3.4, 5.2), clear, 6.0)
	_sprite_scatter(diorama, rng, shrubs, 70, Rect2(-21, -11, 40, 22), 2.0, Vector2(0.7, 1.4), clear, 3.0)
	_sprite_scatter(diorama, rng, ground, 220, Rect2(-21, -11, 40, 22), 1.5, Vector2(0.3, 0.6), clear, 2.0)
	_sprite_scatter(diorama, rng, rocks, 22, Rect2(-21, -11, 40, 22), 2.0, Vector2(0.5, 1.3), clear, 3.0)
	_sprite_scatter(diorama, rng, ["dead_tree_trunk_02"], 5, Rect2(-20, -10, 37, 20), 2.4, Vector2(0.45, 0.6), clear, 4.0)
	# Village around the exit: cottages with chimney smoke and the guard flag.
	for entry: Array in [[Vector3(-3.6, 0, 1.5), 0.3, Color("8f4a35")], [Vector3(-3.2, 0, -2.6), -0.2, Color("4f5f72")], [Vector3(2.6, 0, 2.4), 2.6, Color("8f4a35")]]:
		var spot: Vector3 = exit + (entry[0] as Vector3)
		spot.y = diorama.terrain_height(spot)
		if _free(diorama, spot, 2.4, 2.4): _house(diorama, spot, float(entry[1]), entry[2], true)
	var pole: Vector3 = exit + Vector3(-1.2, 0.1, -1.2)
	pole.y += diorama.terrain_height(pole)
	_flag(diorama, pole, Color("2f6f76"))
	# Split-rail fences on stretches of the road, following the ground.
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("6b543c"), 0.95)
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
			SceneCraft3D.box(diorama, Vector3(0.1, 0.6, 0.1), post + Vector3(0, 0.3, 0), wood)
			SceneCraft3D.beam(diorama, post + Vector3(0, 0.45, 0), next + Vector3(0, 0.45, 0), 0.045, wood)
			SceneCraft3D.beam(diorama, post + Vector3(0, 0.22, 0), next + Vector3(0, 0.22, 0), 0.04, wood)
		distance += 1.1 if int(distance / 9.0) % 2 == 0 else 4.0
	weather(diorama)


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


## Sprite props spread over an area on the terrain, clear of roads, build spots and a radius around a point.
static func _sprite_scatter(diorama: Diorama3D, rng: RandomNumberGenerator, names: Array, count: int, area: Rect2, road: float, height: Vector2, keep_clear: Array[Vector3], clear_radius: float) -> void:
	var placed: int = 0
	var attempts: int = 0
	while placed < count and attempts < count * 10:
		attempts += 1
		var point: Vector3 = Vector3(rng.randf_range(area.position.x, area.end.x), 0, rng.randf_range(area.position.y, area.end.y))
		if not _free(diorama, point, road, 2.0): continue
		var crowded: bool = false
		for spot: Vector3 in keep_clear: crowded = crowded or point.distance_to(Vector3(spot.x, 0, spot.z)) < clear_radius
		if crowded: continue
		point.y = diorama.terrain_height(point)
		SpritePropsV2.place(diorama, str(names[rng.randi() % names.size()]), point, rng.randf_range(height.x, height.y), rng.randf() < 0.5)
		placed += 1


# --- Garganta Rubra: red canyon split by a river, with cliffs and a waterfall ---------------

static func _canyon_bridges(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5505
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
			mesa.position = point
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
	_flag(diorama, exit + Vector3(-1.4, 0.1, -1.4), Color("b8442e"))
	_flag(diorama, exit + Vector3(1.4, 0.1, -1.4), Color("b8442e"))
	for camp: Vector3 in [Vector3(15, 0.1, -9.5), Vector3(-17, 0.1, 10.0)]:
		if _free(diorama, camp, 2.2, 2.0):
			SceneCraft3D.cylinder(diorama, 0.45, 0.12, camp, stratum, 10)
			_smoke(diorama, camp + Vector3(0, 0.3, 0), Color(0.6, 0.55, 0.5, 0.5))


# --- Pântano Sombrio: drowned ruins around a misty lake -----------------------------------

static func _swamp_lake(diorama: Diorama3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9909
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
		column.position = point
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
	_flag(diorama, exit + Vector3(-1.3, 0.1, 1.3), Color("6a4f9c"))
	_smoke(diorama, exit + Vector3(1.6, 0.4, 1.4), Color(0.7, 0.9, 0.75, 0.35))
