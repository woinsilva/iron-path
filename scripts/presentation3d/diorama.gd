class_name Diorama3D extends Node3D
## Reusable real-geometry scene. No gameplay rules or sprite backdrops.

var route_points: Array = []
var additional_route_points: Array = []
var all_ground_routes: Array[Curve3D] = []
var biome: String = "vale"
## Name of a hand-dressed map (MapSceneryV2); empty keeps the generic biome dressing.
var scenery: String = ""
## Height of the rolling terrain in metres (0 keeps the board flat). Roads roll gently, open ground
## rises into hills and the board edges climb into a ridge that frames the map.
var relief: float = 0.0
## Photo materials and realistic sprites (kept as an option; the vale went back to the stylised look).
var photo: bool = false
## Optional [[x, z] high, [x, z] low]: the land falls from the first point towards the second. Empty keeps
## the first map's western plateau.
var descent: Array = []
## Simulation route ids whose enemies travel underground; they get no entrance building.
var burrow_routes: Array = []
## [x, z, radius] areas kept at ground level (lakes, plazas) on relief maps.
var flats: Array = []
## [x, z, radius, height] rounded hills that lift everything on them, roads included (a hill fort).
var mounds: Array = []
## Height of the plateau the land falls from (metres before relief scaling).
var descent_drop: float = 2.6
var _heights: PackedFloat32Array = PackedFloat32Array()
const HEIGHT_STEP: float = 0.5
const HEIGHT_ORIGIN: Vector2 = Vector2(-48, -32)
const HEIGHT_SIZE: Vector2i = Vector2i(193, 129)
var stage_index: int = 1
var reserved_positions: PackedVector3Array = PackedVector3Array()
var river_x: float = 19.3
var river_width: float = 3.0
var bridges_enabled: bool = false
var bridge_centers: Array[Vector3] = []
var route: Curve3D
var camera: Camera3D
var sunlight: DirectionalLight3D
var _water_surface: ShaderMaterial
var water: MeshInstance3D
var _wind_time: float = 0.0
var _foliage: Array[Node3D] = []
var _gust_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _next_gust: float = 4.0
var _gust_age: float = -1.0
const GUST_SECONDS: float = 4.5

func _ready() -> void:
	_build_camera_and_light()
	if relief > 0.0: _build_heights()
	_build_ground()
	_build_route()
	all_ground_routes.append(route)
	var primary: Curve3D = route
	for points: Array in additional_route_points:
		var controls: PackedVector3Array = PackedVector3Array()
		for point: Array in points: controls.append(Vector3(float(point[0]), float(point[1]), float(point[2])))
		route = StageSessionV2.curve_from_points(controls)
		all_ground_routes.append(route)
		_build_road_surface(2.45, 0.075, Color("8f805b"))
		_build_road_surface(2.10, 0.10, Color("c6aa77"))
	if bridges_enabled:
		for ground_route: Curve3D in all_ground_routes:
			route = ground_route
			_build_bridges()
	route = primary
	_build_banks()
	_build_verge_details()
	if not scenery.is_empty(): MapSceneryV2.build(self, scenery)
	elif biome == "swamp": _build_swamp()
	elif biome == "canyon": _build_canyon()
	else: _build_forest()
	BiomeDressingV2.dress(self)

func _build_camera_and_light() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 32.0
	camera.v_offset = -1.2
	camera.position = Vector3(0, 33, 29)
	add_child(camera)
	camera.look_at(Vector3(0, 0, 0))
	camera.current = true
	camera.near = 0.1
	camera.far = 120.0
	sunlight = DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-58, -32, 0)
	sunlight.light_color = Color("fff0cf")
	sunlight.light_energy = 1.05 if biome == "swamp" else 1.35
	if biome == "swamp": sunlight.light_color = Color("d2ddd4")
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_max_distance = 80.0
	sunlight.shadow_bias = 0.03
	add_child(sunlight)
	var environment_node: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("334d52")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a9c4d2")
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)

func _curve_from(points: Array) -> Curve3D:
	var controls: PackedVector3Array = PackedVector3Array()
	for point: Array in points: controls.append(Vector3(float(point[0]), 0, float(point[2])))
	return StageSessionV2.curve_from_points(controls)

## Bakes the terrain into a 0.5 m grid once, so every later height query is a cheap bilinear lookup.
func _build_heights() -> void:
	var roads: Array[Curve3D] = [_curve_from(route_points)]
	for points: Array in additional_route_points: roads.append(_curve_from(points))
	var roll: FastNoiseLite = FastNoiseLite.new()
	roll.seed = 7101
	roll.frequency = 0.045
	var hills: FastNoiseLite = FastNoiseLite.new()
	hills.seed = 9203
	hills.frequency = 0.045
	hills.fractal_octaves = 2
	_heights.resize(HEIGHT_SIZE.x * HEIGHT_SIZE.y)
	for row in range(HEIGHT_SIZE.y):
		for column in range(HEIGHT_SIZE.x):
			var point: Vector3 = Vector3(HEIGHT_ORIGIN.x + column * HEIGHT_STEP, 0, HEIGHT_ORIGIN.y + row * HEIGHT_STEP)
			var road: float = 1e9
			for curve: Curve3D in roads: road = minf(road, curve.get_closest_point(point).distance_to(point))
			var open: float = smoothstep(2.4, 6.5, road)
			# The camera looks from the south (+z), so only the far side and the flanks rise; a ridge in
			# front would hide the board.
			var ridge: float = smoothstep(19.0, 27.0, absf(point.x)) + smoothstep(10.5, 15.5, -point.z)
			var water: float = smoothstep(river_width * 0.5 + 0.4, river_width * 0.5 + 3.0, absf(point.x - river_x))
			# The land descends from a high western plateau (where the road enters) to the valley floor in the
			# east, so the road visibly climbs down; open ground carries flat-topped knolls with steep sides.
			var fall: float = descent_drop * (1.0 - smoothstep(-20.0, 6.0, point.x))
			if descent.size() == 2:
				var high: Vector2 = Vector2(float(descent[0][0]), float(descent[0][1]))
				var low: Vector2 = Vector2(float(descent[1][0]), float(descent[1][1]))
				var along: float = (Vector2(point.x, point.z) - high).dot(low - high) / (low - high).length_squared()
				fall = descent_drop * (1.0 - smoothstep(0.0, 1.0, along))
			for mound: Array in mounds:
				var span: float = Vector2(point.x - float(mound[0]), point.z - float(mound[1])).length() / float(mound[2])
				fall += float(mound[3]) * (1.0 - smoothstep(0.35, 1.0, span))
			# Canyon knolls are steep-sided mesas; elsewhere they are softer rises.
			var knoll: float = smoothstep(0.12, 0.34, hills.get_noise_2d(point.x, point.z)) * 2.0 * open
			if biome == "canyon": knoll = smoothstep(0.16, 0.22, hills.get_noise_2d(point.x, point.z)) * 2.4 * open
			var height: float = (fall +roll.get_noise_2d(point.x, point.z) * 0.35 + knoll + ridge * 2.6) * relief
			for flat: Array in flats:
				var reach: float = Vector2(point.x - float(flat[0]), point.z - float(flat[1])).length()
				height *= smoothstep(float(flat[2]), float(flat[2]) + 3.0, reach)
			_heights[row * HEIGHT_SIZE.x + column] = height * water

## Height a building's floor needs on uneven ground: the highest point under its footprint, so a
## stone plinth can fill the gap down to the lowest point instead of the base sinking into a slope.
func footprint_heights(point: Vector3, radius: float) -> Vector2:
	var low: float = terrain_height(point)
	var high: float = low
	for index in range(8):
		var angle: float = index * TAU / 8.0
		var sample: float = terrain_height(point + Vector3(cos(angle), 0, sin(angle)) * radius)
		low = minf(low, sample)
		high = maxf(high, sample)
	return Vector2(low, high)

func terrain_height(point: Vector3) -> float:
	if _heights.is_empty(): return 0.0
	var gx: float = clampf((point.x - HEIGHT_ORIGIN.x) / HEIGHT_STEP, 0, HEIGHT_SIZE.x - 1.001)
	var gz: float = clampf((point.z - HEIGHT_ORIGIN.y) / HEIGHT_STEP, 0, HEIGHT_SIZE.y - 1.001)
	var x: int = int(gx)
	var z: int = int(gz)
	var fx: float = gx - x
	var fz: float = gz - z
	var top: float = lerpf(_heights[z * HEIGHT_SIZE.x + x], _heights[z * HEIGHT_SIZE.x + x + 1], fx)
	var bottom: float = lerpf(_heights[(z + 1) * HEIGHT_SIZE.x + x], _heights[(z + 1) * HEIGHT_SIZE.x + x + 1], fx)
	return lerpf(top, bottom, fz)

func _terrain_mesh() -> ArrayMesh:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(HEIGHT_SIZE.y):
		for column in range(HEIGHT_SIZE.x):
			surface.add_vertex(Vector3(HEIGHT_ORIGIN.x + column * HEIGHT_STEP, _heights[row * HEIGHT_SIZE.x + column], HEIGHT_ORIGIN.y + row * HEIGHT_STEP))
	for row in range(HEIGHT_SIZE.y - 1):
		for column in range(HEIGHT_SIZE.x - 1):
			var a: int = row * HEIGHT_SIZE.x + column
			for index: int in [a, a + 1, a + HEIGHT_SIZE.x, a + 1, a + HEIGHT_SIZE.x + 1, a + HEIGHT_SIZE.x]: surface.add_index(index)
	surface.generate_normals()
	return surface.commit()

## Drifting cloud shadows painted by the terrain shader itself, so they follow the hills instead of a flat
## sheet cutting through them.
func _cloud_texture() -> NoiseTexture2D:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	var texture: NoiseTexture2D = NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.noise = noise
	return texture

func _photo_ground() -> ShaderMaterial:
	var ground: ShaderMaterial = ShaderMaterial.new()
	ground.shader = load("res://scripts/presentation3d/ground_pbr.gdshader") as Shader
	ground.set_shader_parameter("grass_albedo", load("res://art/textures/aerial_grass_rock_Diffuse.jpg"))
	ground.set_shader_parameter("grass_normal", load("res://art/textures/aerial_grass_rock_nor_gl.jpg"))
	ground.set_shader_parameter("soil_albedo", load("res://art/textures/forrest_ground_01_Diffuse.jpg"))
	ground.set_shader_parameter("soil_normal", load("res://art/textures/forrest_ground_01_nor_gl.jpg"))
	ground.set_shader_parameter("rock_albedo", load("res://art/textures/rocky_trail_Diffuse.jpg"))
	ground.set_shader_parameter("rock_normal", load("res://art/textures/rocky_trail_nor_gl.jpg"))
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 4040
	noise.frequency = 0.04
	var mask: NoiseTexture2D = NoiseTexture2D.new()
	mask.seamless = true
	mask.noise = noise
	ground.set_shader_parameter("mask_noise", mask)
	return ground

func _build_ground() -> void:
	var grass: ShaderMaterial = ShaderMaterial.new()
	grass.shader = load("res://scripts/presentation3d/terrain.gdshader") as Shader
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 9012
	noise.frequency = 0.10
	var texture: NoiseTexture2D = NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.noise = noise
	texture.seamless = true
	grass.set_shader_parameter("grain", texture)
	grass.set_shader_parameter("grain_scale", 0.06)
	grass.set_shader_parameter("deep_color", Color("416848"))
	grass.set_shader_parameter("light_color", Color("789558"))
	if biome == "canyon":
		grass.set_shader_parameter("deep_color", Color("714538"))
		grass.set_shader_parameter("light_color", Color("b67b50"))
		grass.set_shader_parameter("slope_color", Color("8a4a35"))
	if biome == "swamp":
		grass.set_shader_parameter("grain_scale", 0.06)
		grass.set_shader_parameter("deep_color", Color("35473e"))
		grass.set_shader_parameter("light_color", Color("4f6050"))
		grass.set_shader_parameter("slope_color", Color("4a4436"))
	if relief > 0.0: grass.set_shader_parameter("clouds", _cloud_texture())
	var earth: StandardMaterial3D = SceneCraft3D.material(Color("665341"))
	SceneCraft3D.box(self, Vector3(96, 1.2, 64), Vector3(0, -0.75, 0), earth)
	if photo or relief > 0.0:
		var terrain: MeshInstance3D = MeshInstance3D.new()
		terrain.name = "Terrain"
		if relief > 0.0: terrain.mesh = _terrain_mesh()
		else:
			var flat: PlaneMesh = PlaneMesh.new()
			flat.size = Vector2(96, 64)
			terrain.mesh = flat
		terrain.position.y = 0.05
		terrain.material_override = _photo_ground() if photo else grass
		add_child(terrain)
	else:
		SceneCraft3D.box(self, Vector3(96, 0.22, 64), Vector3(0, -0.06, 0), grass)
	_water_surface = ShaderMaterial.new()
	_water_surface.shader = load("res://scripts/presentation3d/water.gdshader") as Shader
	_water_surface.set_shader_parameter("phase",0.0)
	_water_surface.set_shader_parameter("deep_color",Color("2c5d5a") if biome == "swamp" else (Color("2f5e63") if photo else Color("3c8492")))
	if photo_style(): _water_surface.set_shader_parameter("ripple_color", Color("4b7a7c"))
	water = SceneCraft3D.box(self, Vector3(river_width, 0.12, 64), Vector3(river_x, 0.08, 0), _water_surface)

func _build_route() -> void:
	var controls: PackedVector3Array = PackedVector3Array([
		Vector3(-19, 0, -7), Vector3(-10, 0, -7), Vector3(2, 0, -7),
		Vector3(14, 0, -4), Vector3(13, 0, 5), Vector3(3, 0, 7),
		Vector3(-10, 0, 6), Vector3(-14, 0, 1), Vector3(-7, 0, -1), Vector3(1, 0, 1)
	])
	if not route_points.is_empty():
		controls.clear()
		for entry: Array in route_points:
			controls.append(Vector3(float(entry[0]), float(entry[1]), float(entry[2])))
	route = StageSessionV2.curve_from_points(controls)
	_build_road_surface(2.45, 0.075, Color("8f805b"))
	_build_road_surface(2.10, 0.10, Color("c6aa77"))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3304
	var pebble: StandardMaterial3D = SceneCraft3D.material(Color("8a8274") if photo_style() else Color("ac9d7f"))
	for index in range(70):
		var distance: float = rng.randf() * route.get_baked_length()
		var point: Vector3 = route.sample_baked(distance)
		var direction: Vector3 = (route.sample_baked(minf(distance + 0.2, route.get_baked_length())) - point).normalized()
		var normal: Vector3 = Vector3(-direction.z, 0, direction.x)
		point += normal * rng.randf_range(-0.8, 0.8)
		var stone: MeshInstance3D = SceneCraft3D.sphere(self, rng.randf_range(0.025, 0.065), point + Vector3(0, 0.085 + terrain_height(point), 0), pebble)
		stone.scale.y = 0.35

func _build_road_surface(width: float, height: float, color: Color) -> void:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length: float = route.get_baked_length()
	var segments: int = ceili(length / 0.3)
	var left: PackedVector3Array = PackedVector3Array()
	var right: PackedVector3Array = PackedVector3Array()
	for index in range(segments + 1):
		var distance: float = length * float(index) / segments
		var point: Vector3 = route.sample_baked(distance)
		var tangent: Vector3 = (route.sample_baked(minf(length, distance + 0.15)) - route.sample_baked(maxf(0.0, distance - 0.15))).normalized()
		var side: Vector3 = Vector3(-tangent.z, 0, tangent.x) * width * 0.5
		var low: Vector3 = point - side
		var high: Vector3 = point + side
		low.y = height + terrain_height(low)
		high.y = height + terrain_height(high)
		left.append(low)
		right.append(high)
	for index in range(segments):
		for corner: Array in [[left[index], 0.0], [left[index + 1], 0.0], [right[index], 1.0], [right[index], 1.0], [left[index + 1], 0.0], [right[index + 1], 1.0]]:
			surface.set_normal(Vector3.UP)
			surface.set_uv(Vector2(float(corner[1]), 0))
			surface.add_vertex(corner[0])
	var material: Material = SceneCraft3D.material(color)
	(material as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	if photo:
		var trail: ShaderMaterial = ShaderMaterial.new()
		trail.shader = load("res://scripts/presentation3d/road_pbr.gdshader") as Shader
		trail.set_shader_parameter("trail_albedo", load("res://art/textures/rocky_trail_Diffuse.jpg"))
		trail.set_shader_parameter("trail_normal", load("res://art/textures/rocky_trail_nor_gl.jpg"))
		trail.set_shader_parameter("tint", color.lightened(0.35))
		material = trail
	SceneCraft3D.mesh(self, surface.commit(), Vector3.ZERO, material)

func _build_forest() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 8721
	var tree_files: Array[String] = ["Tree_1_A_Color1", "Tree_2_B_Color1", "Tree_3_A_Color1"]
	for index in range(52):
		var point: Vector3
		if index < 28:
			point = Vector3(rng.randf_range(-21, 16.7), 0.1, rng.randf_range(10.5, 13.0) if index % 2 == 0 else rng.randf_range(-13.0, -10.6))
		else:
			point = Vector3(rng.randf_range(-21.0, -19.7), 0.1, rng.randf_range(-11, 11))
		if _is_reserved(point, 3.2) or _distance_from_route(point) < 3.2:
			continue
		var tree: Node3D = load("res://art/models/%s.glb" % tree_files[index % tree_files.size()]).instantiate() as Node3D
		tree.position = point
		tree.rotation.y = rng.randf_range(-PI, PI)
		tree.scale = Vector3.ONE * rng.randf_range(0.55, 0.95) * (0.72 if point.z > 10 else 1.0)
		add_child(tree)
		_style_foliage(tree)
		_foliage.append(tree)
	var files: Array[String] = ["Bush_1_A_Color1", "Bush_2_C_Color1", "Rock_1_A_Color1", "Grass_1_A_Color1"]
	for index in range(110):
		var point: Vector3 = Vector3(rng.randf_range(-20.5, 16.8), 0.08, rng.randf_range(-12.4, 12.4))
		if _is_reserved(point, 2.0): continue
		if absf(point.x - river_x) < river_width * 0.5 + 0.6 or _distance_from_route(point) < 1.65:
			continue
		if point.x > -11.0 and point.x < 12.0 and point.z > -5.0 and point.z < 5.0:
			continue
		var prop: Node3D = load("res://art/models/%s.glb" % files[index % files.size()]).instantiate() as Node3D
		prop.position = point
		prop.scale = Vector3.ONE * rng.randf_range(0.65, 1.25)
		prop.rotation.y = rng.randf_range(-PI, PI)
		add_child(prop)
		if "Bush" in files[index % files.size()] or "Grass" in files[index % files.size()]: _style_foliage(prop)

func _distance_from_route(point: Vector3) -> float:
	var distance: float = route.get_closest_point(point).distance_to(point)
	for branch: Curve3D in all_ground_routes: distance = minf(distance, branch.get_closest_point(point).distance_to(point))
	return distance

func _process(delta: float) -> void:
	_wind_time += delta
	if _water_surface != null: _water_surface.set_shader_parameter("phase",_wind_time)
	_update_wind(delta)

## Calm air with an occasional gust: every 6–16 s (random) a front crosses the board from the west,
## bending the plants it passes and fading out on the far side.
func _update_wind(delta: float) -> void:
	if _gust_age < 0.0:
		_next_gust -= delta
		if _next_gust <= 0.0: _gust_age = 0.0
		return
	_gust_age += delta
	var progress: float = _gust_age / GUST_SECONDS
	RenderingServer.global_shader_parameter_set("wind_front", lerpf(-34.0, 34.0, progress))
	RenderingServer.global_shader_parameter_set("wind_power", sin(clampf(progress, 0.0, 1.0) * PI) * _gust_rng.randf_range(0.9, 1.1) * 1.6)
	if progress >= 1.0:
		_gust_age = -1.0
		_next_gust = _gust_rng.randf_range(6.0, 16.0)
		RenderingServer.global_shader_parameter_set("wind_power", 0.0)

func _style_foliage(node: Node) -> void:
	if node is MeshInstance3D:
		var instance: MeshInstance3D = node as MeshInstance3D
		for index in range(instance.mesh.get_surface_count()):
			var source: StandardMaterial3D = instance.mesh.surface_get_material(index) as StandardMaterial3D
			if source:
				var material: ShaderMaterial = ShaderMaterial.new()
				material.shader = load("res://scripts/presentation3d/foliage.gdshader") as Shader
				material.set_shader_parameter("source_texture", source.albedo_texture)
				if biome == "swamp":
					material.set_shader_parameter("leaf_dark", Color("233d38"))
					material.set_shader_parameter("leaf_light", Color("55786b"))
				instance.set_surface_override_material(index, material)
	for child in node.get_children():
		_style_foliage(child)

func _build_bridges() -> void:
	var length: float = route.get_baked_length()
	var previous: Vector3 = route.sample_baked(0)
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("96704b"))
	var frame: StandardMaterial3D = SceneCraft3D.material(Color("63523c"))
	for index in range(1, ceili(length / 0.2) + 1):
		var distance: float = minf(length, index * 0.2)
		var point: Vector3 = route.sample_baked(distance)
		if (previous.x - river_x) * (point.x - river_x) < 0:
			var crossing: Vector3 = previous.lerp(point, (river_x - previous.x) / (point.x - previous.x))
			var exists: bool = false
			for center: Vector3 in bridge_centers:
				if center.distance_to(crossing) < 1.0: exists = true; break
			if exists:
				previous = point
				continue
			bridge_centers.append(crossing)
			var bridge: Node3D = Node3D.new()
			bridge.position = crossing + Vector3(0, 0.14, 0)
			bridge.rotation.y = atan2(point.x - previous.x, point.z - previous.z)
			add_child(bridge)
			var plank: BoxMesh = BoxMesh.new()
			plank.size = Vector3(2.5, 0.12, 0.23)
			var batch: MultiMesh = MultiMesh.new()
			batch.transform_format = MultiMesh.TRANSFORM_3D
			batch.mesh = plank
			batch.instance_count = 18
			for board in range(18):
				batch.set_instance_transform(board, Transform3D(Basis.IDENTITY, Vector3(0, 0, -2.125 + board * 0.25)))
			var boards: MultiMeshInstance3D = MultiMeshInstance3D.new()
			boards.multimesh = batch
			boards.material_override = wood
			bridge.add_child(boards)
			for x: float in [-1.2, 1.2]:
				SceneCraft3D.box(bridge, Vector3(0.12, 0.13, 4.6), Vector3(x, 0.65, 0), frame)
				for z: float in [-2, 0, 2]:
					SceneCraft3D.box(bridge, Vector3(0.13, 0.8, 0.13), Vector3(x, 0.3, z), frame)
		previous = point
## Maps dressed with the realistic photo materials and sprites (currently the redesigned vale).
func photo_style() -> bool:
	return photo

func walk_surface_height(point: Vector3) -> float:
	var height: float = 0.1 + terrain_height(point)
	for center: Vector3 in bridge_centers:
		var distance: float = BattleSimV2.distance_xz(center,point)
		height = maxf(height,0.1 + terrain_height(point) + 0.1 * (1.0 - smoothstep(1.65,2.6,distance)))
	return height

func _build_banks() -> void:
	var bank: StandardMaterial3D = SceneCraft3D.material(Color("6f6a5c") if photo_style() else Color("a4a187"))
	for z_index in range(25):
		var z: float = -12.5 + z_index
		if _distance_from_route(Vector3(river_x, 0, z)) < 2.6 or _is_reserved(Vector3(river_x, 0, z), 2.5): continue
		var rock: MeshInstance3D = SceneCraft3D.sphere(self, 0.38, Vector3(river_x - river_width * 0.5 + sin(z) * 0.1, 0.1, z), bank)
		rock.scale = Vector3(1.4, 0.6, 1.0)


func _is_reserved(point: Vector3, clearance: float) -> bool:
	for reserved: Vector3 in reserved_positions:
		if BattleSimV2.distance_xz(point, reserved) < clearance: return true
	return false

func _build_canyon() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 57505
	var rock: StandardMaterial3D = SceneCraft3D.material(Color("a56748"))
	var stratum: StandardMaterial3D = SceneCraft3D.material(Color("70473b"))
	var accent: StandardMaterial3D = SceneCraft3D.material(Color("cca16d"))
	for index in range(34):
		var point: Vector3 = Vector3(rng.randf_range(-20.5, 20), 0, -12.4 if index % 2 == 0 else 12.4)
		if _distance_from_route(point) < 3 or _is_reserved(point, 3): continue
		var column: Node3D = Node3D.new()
		column.position = point
		add_child(column)
		var height: float = rng.randf_range(1.1, 3.2) * (0.55 if point.z > 0 else 1)
		for layer in range(3):
			var radius: float = (1.4 - layer * 0.22) * rng.randf_range(0.85, 1.15)
			SceneCraft3D.cylinder(column, radius, height / 3, Vector3(0, height * (layer + 0.5) / 3, 0), stratum if layer == 1 else rock, 7)
	for index in range(36):
		var point: Vector3 = Vector3(rng.randf_range(-20, 20), 0.13, rng.randf_range(-11, 11))
		if _distance_from_route(point) < 2 or _is_reserved(point, 2.5) or absf(point.x - river_x) < river_width: continue
		var stone: MeshInstance3D = SceneCraft3D.sphere(self, rng.randf_range(0.12, 0.4), point, accent)
		stone.scale = Vector3(1.4, 0.65, 1)

func _build_swamp() -> void:
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("67776f"), 0.95)
	var moss: StandardMaterial3D = SceneCraft3D.material(Color("69794c"))
	var pool: StandardMaterial3D = SceneCraft3D.material(Color("365d59"), 0.25, 0.2)
	_build_swamp_border()
	var rune: StandardMaterial3D = SceneCraft3D.material(Color("b29ed4"))
	rune.emission_enabled = true
	rune.emission = Color("755b9c")
	rune.emission_energy_multiplier = 0.5
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9009
	for index in range(30):
		var point: Vector3 = Vector3(rng.randf_range(-19, 19), 0.12, rng.randf_range(-11, 11))
		if _is_reserved(point, 2.8) or _distance_from_route(point) < 3.4: continue
		var pond: MeshInstance3D = SceneCraft3D.cylinder(self, rng.randf_range(0.6, 1.3), 0.035, point, pool, 20)
		pond.name = "SwampPool%d" % index
		pond.scale.z = 0.65
		for stem in range(4):
			SceneCraft3D.cylinder(self, 0.035, 0.5, point + Vector3(0.5 + stem * 0.12, 0.22, 0.3), moss, 5)
	for index in range(8):
		var point: Vector3 = Vector3(-17 + index * 4.8, 0.1, -11.5 if index % 2 == 0 else 10.5)
		if _is_reserved(point, 2.5) or _distance_from_route(point) < 3: continue
		var column: Node3D = Node3D.new()
		column.name = "RunicRuin%d" % index
		column.position = point
		add_child(column)
		SceneCraft3D.box(column, Vector3(1.5, 0.25, 1.5), Vector3(0, 0.1, 0), stone)
		var height: float = 1.5 + (index % 3) * 0.5
		SceneCraft3D.cylinder(column, 0.48, height, Vector3(0, height / 2, 0), stone, 8)
		SceneCraft3D.box(column, Vector3(1.15, 0.22, 1.15), Vector3(0, height, 0), moss)
		var glyph: MeshInstance3D = SceneCraft3D.box(column, Vector3(0.22, 0.22, 0.04), Vector3(0, height * 0.65, 0.49), rune)
		glyph.rotation.z = PI / 4

func _build_verge_details() -> void:
	var placements: Array[Transform3D] = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 91009
	for road: Curve3D in all_ground_routes:
		for index in range(ceili(road.get_baked_length() / 2.8)):
			var distance: float = minf(road.get_baked_length(), index * 2.8 + 0.5)
			var point: Vector3 = road.sample_baked(distance)
			var tangent: Vector3 = (road.sample_baked(minf(road.get_baked_length(), distance + 0.2)) - road.sample_baked(maxf(0,distance - 0.2))).normalized()
			var side: Vector3 = Vector3(-tangent.z,0,tangent.x)
			for sign: float in [-1,1]:
				var position: Vector3 = point + side * sign * rng.randf_range(1.12,1.25)
				if _is_reserved(position,1.3) or (bridges_enabled and absf(position.x - river_x) < river_width * 0.65): continue
				position.y = 0.13 + terrain_height(position)
				var scale: Vector3 = Vector3(rng.randf_range(0.14,0.25),rng.randf_range(0.05,0.09),rng.randf_range(0.12,0.2))
				placements.append(Transform3D(Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(scale),position))
	var geometry: SphereMesh = SphereMesh.new()
	geometry.radius = 1
	geometry.height = 2
	geometry.radial_segments = 8
	geometry.rings = 4
	var material: StandardMaterial3D = SceneCraft3D.material(Color("baaa89") if biome != "swamp" else Color("9b9b80"))
	if photo_style(): material.albedo_color = Color("7d776b")
	material.vertex_color_use_as_albedo = true
	geometry.material = material
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = geometry
	instances.instance_count = placements.size()
	for index in range(placements.size()):
		instances.set_instance_transform(index, placements[index])
		instances.set_instance_color(index,Color(1,1,1).darkened(rng.randf_range(0,0.2)))
	var view: MultiMeshInstance3D = MultiMeshInstance3D.new()
	view.name = "RoadVergeStones"
	view.multimesh = instances
	add_child(view)

func _build_swamp_border() -> void:
	for sign: float in [-1,1]:
		for index in range(5):
			var point: Vector3 = Vector3(sign * (24 + index % 2),0.1,-10 + index * 4.7)
			if sign < 0 and absf(point.z + 1) < 4: continue
			var tree: Node3D = load("res://art/models/Tree_3_A_Color1.glb").instantiate() as Node3D
			tree.position = point
			tree.scale = Vector3.ONE * (0.75 + (index % 3) * 0.08)
			tree.rotation.y = index * 1.7
			add_child(tree)
			_style_foliage(tree)
			_foliage.append(tree)
	_build_swamp_hero()

func _build_swamp_hero() -> void:
	var hero: Node3D = Node3D.new()
	hero.name = "SwampLandmark%d" % stage_index
	hero.position = Vector3(-23,0.1,-1)
	hero.position.y += terrain_height(hero.position)
	add_child(hero)
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("687c70"),0.95)
	var moss: StandardMaterial3D = SceneCraft3D.material(Color("546a4a"))
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("79674b"))
	var rune: StandardMaterial3D = SceneCraft3D.material(Color("b399d0"),0.4)
	rune.emission_enabled = true
	rune.emission = Color("9370b9")
	rune.emission_energy_multiplier = 0.6
	if stage_index == 10:
		SceneCraft3D.box(hero,Vector3(3.5,0.05,5.5),Vector3(0,0.02,0),SceneCraft3D.material(Color("365d59"),0.2))
		for index in range(11):
			SceneCraft3D.box(hero,Vector3(2.3,0.14,0.36),Vector3(0,0.65,-2 + index * 0.4),wood)
		for sign: float in [-1,1]:
			for z: float in [-1.8,1.8]: SceneCraft3D.cylinder(hero,0.1,1.5,Vector3(sign * 1.05,0.75,z),wood,8)
			SceneCraft3D.beam(hero,Vector3(sign * 1.05,1.35,-1.8),Vector3(sign * 1.05,1.35,1.8),0.07,wood)
		return
	if stage_index == 11:
		for index in range(7):
			var angle: float = index * TAU / 7
			var shell: MeshInstance3D = SceneCraft3D.sphere(hero,0.62,Vector3(sin(angle) * 1.2,0.4,cos(angle) * 1.2),stone)
			shell.scale = Vector3(0.7,1.2,0.7)
			SceneCraft3D.sphere(hero,0.16,Vector3(sin(angle) * 1.2,0.65,cos(angle) * 1.2 + 0.4),rune)
		SceneCraft3D.cylinder(hero,2,0.15,Vector3(0,0.05,0),moss,12)
		return
	if stage_index == 12:
		for index in range(3): SceneCraft3D.box(hero,Vector3(3 - index * 0.5,0.35,4 - index * 0.5),Vector3(0,0.175 + index * 0.35,0),stone)
		for sign: float in [-1,1]:
			var crystal: CylinderMesh = CylinderMesh.new()
			crystal.top_radius = 0
			crystal.bottom_radius = 0.65
			crystal.height = 1.2
			crystal.radial_segments = 6
			var half: MeshInstance3D = SceneCraft3D.mesh(hero,crystal,Vector3(0,2.2 + sign * 0.6,0),rune)
			if sign < 0: half.rotation.z = PI
		var ring: TorusMesh = TorusMesh.new()
		ring.inner_radius = 1.3
		ring.outer_radius = 1.4
		ring.rings = 24
		ring.ring_segments = 6
		var halo: MeshInstance3D = SceneCraft3D.mesh(hero,ring,Vector3(0,2.2,0),moss)
		halo.rotation.x = PI / 2
		return
	for sign: float in [-1,1]:
		SceneCraft3D.cylinder(hero,0.65,3.2 if sign < 0 else 2.7,Vector3(0,1.6 if sign < 0 else 1.35,sign * 1.5),stone,8)
		SceneCraft3D.box(hero,Vector3(1.5,0.3,1.5),Vector3(0,0.15,sign * 1.5),moss)
	var lintel: MeshInstance3D = SceneCraft3D.box(hero,Vector3(1.4,0.45,3.8),Vector3(0,3.3,0),stone)
	lintel.rotation.x = 0.13
	for z: float in [-0.7,0,0.7]: SceneCraft3D.box(hero,Vector3(0.05,0.22,0.22),Vector3(0.73,3.3,z),rune)
