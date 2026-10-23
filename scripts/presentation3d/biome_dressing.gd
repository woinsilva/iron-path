## Extra life on top of each biome's diorama: dense ground cover, flowers, drifting cloud shadows,
## ambient particles and low fog. Everything joins the "biome_detail" group so the Economy graphics
## profile can hide it, and nothing is placed on the roads or the build pads.
class_name BiomeDressingV2
extends Node3D

const DETAIL_GROUP: StringName = &"biome_detail"

var diorama: Diorama3D
var _shadows: StandardMaterial3D
var _fog: StandardMaterial3D
var _time: float = 0.0


static func dress(target: Diorama3D) -> BiomeDressingV2:
	var dressing: BiomeDressingV2 = BiomeDressingV2.new()
	dressing.name = "BiomeDressing"
	dressing.diorama = target
	target.add_child(dressing)
	return dressing


func _ready() -> void:
	var palette: Dictionary = {
		"vale": {"blades": [Color("4d7a32"), Color("5b8a38"), Color("426c2c")], "count": 0, "flowers": []},
		"canyon": {"blades": [Color("6a5230"), Color("5e4a2c"), Color("554228")], "count": 380, "flowers": []},
		"swamp": {"blades": [Color("2c4128"), Color("34492d"), Color("263a24")], "count": 1300, "flowers": []},
	}
	var look: Dictionary = palette.get(diorama.biome, palette.vale)
	if int(look.count) > 0: _scatter(look.blades, int(look.count), _blade_mesh(), 0.9, 1.6)
	if not (look.flowers as Array).is_empty(): _scatter(look.flowers, 260, _flower_mesh(), 0.8, 1.3)
	# On relief maps the terrain shader draws the cloud shadows so they follow the hills.
	if diorama.relief <= 0.0: _cloud_shadows()
	if diorama.biome == "swamp":
		_low_fog()
		_motes(Color("d9ff9a"), 40, 2.5, 0.6)
	elif diorama.biome == "canyon":
		_motes(Color("f0d2a0"), 36, 1.6, 0.25)
	else:
		_motes(Color("fff6c8"), 18, 2.0, 0.35)


func _process(delta: float) -> void:
	_time += delta
	if _shadows != null: _shadows.uv1_offset = Vector3(_time * 0.004, _time * 0.0025, 0)
	if _fog != null: _fog.uv1_offset = Vector3(-_time * 0.006, _time * 0.003, 0)


## Free ground: off the roads, off the pads, off the river and inside the visible board.
func _open_ground(point: Vector3) -> bool:
	if diorama._distance_from_route(point) < 1.55: return false
	if diorama._is_reserved(point, 1.25): return false
	if absf(point.x - diorama.river_x) < diorama.river_width * 0.5 + 0.35: return false
	return true


func _scatter(colors: Array, count: int, mesh: Mesh, min_scale: float, max_scale: float) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(diorama.biome) + count
	var transforms: Array[Transform3D] = []
	var tints: Array[Color] = []
	var attempts: int = 0
	while transforms.size() < count and attempts < count * 4:
		attempts += 1
		var point: Vector3 = Vector3(rng.randf_range(-21, 21), 0.1, rng.randf_range(-12.5, 12.5))
		if not _open_ground(point): continue
		point.y += diorama.terrain_height(point)
		var basis: Basis = Basis(Vector3.UP, rng.randf_range(-PI, PI)).scaled(Vector3.ONE * rng.randf_range(min_scale, max_scale))
		transforms.append(Transform3D(basis, point))
		tints.append((colors[rng.randi() % colors.size()] as Color).lightened(rng.randf_range(-0.08, 0.08)))
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
		multimesh.set_instance_color(index, tints[index])
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	instance.add_to_group(DETAIL_GROUP)


func _vertex_color_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## Three crossed blades: a tuft that reads as grass from the high camera.
func _blade_mesh() -> ArrayMesh:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(_vertex_color_material())
	for blade in range(3):
		var angle: float = blade * TAU / 3
		var side: Vector3 = Vector3(cos(angle), 0, sin(angle)) * 0.09
		var lean: Vector3 = Vector3(sin(angle), 0, -cos(angle)) * 0.06
		var tip: Vector3 = Vector3(0, 0.34, 0) + lean
		# Sideways normals keep the tufts in half shade instead of glowing under the high sun.
		surface.set_normal(Vector3(sin(angle), 0.35, -cos(angle)).normalized())
		for vertex: Vector3 in [-side, side, tip]: surface.add_vertex(vertex)
	return surface.commit()


## A small five-petal disc on a short stem.
func _flower_mesh() -> ArrayMesh:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(_vertex_color_material())
	var center: Vector3 = Vector3(0, 0.2, 0)
	surface.set_normal(Vector3.UP)
	for petal in range(5):
		var a: float = petal * TAU / 5
		var b: float = a + TAU / 10
		for vertex: Vector3 in [center, center + Vector3(cos(a), 0, sin(a)) * 0.11, center + Vector3(cos(b), 0.01, sin(b)) * 0.07]:
			surface.add_vertex(vertex)
	return surface.commit()


## Soft noise darkening that drifts across the whole board like passing clouds.
func _cloud_shadows() -> void:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	var texture: NoiseTexture2D = NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.noise = noise
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(0, 0, 0, 0))
	ramp.set_color(1, Color(0, 0, 0, 0))
	ramp.add_point(0.62, Color(0, 0, 0, 0))
	ramp.add_point(0.8, Color(0.02, 0.04, 0.06, 0.2))
	texture.color_ramp = ramp
	_shadows = StandardMaterial3D.new()
	_shadows.albedo_texture = texture
	_shadows.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadows.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadows.uv1_scale = Vector3(1.6, 1.6, 1)
	_shadows.texture_repeat = true
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(52, 34)
	var sheet: MeshInstance3D = MeshInstance3D.new()
	sheet.mesh = plane
	sheet.material_override = _shadows
	sheet.position.y = 0.32
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sheet)
	sheet.add_to_group(DETAIL_GROUP)


## Pale mist hugging the swamp floor.
func _low_fog() -> void:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.frequency = 0.02
	var texture: NoiseTexture2D = NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.noise = noise
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(0.85, 0.92, 0.88, 0))
	ramp.set_color(1, Color(0.85, 0.92, 0.88, 0.08))
	texture.color_ramp = ramp
	_fog = StandardMaterial3D.new()
	_fog.albedo_texture = texture
	_fog.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fog.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fog.uv1_scale = Vector3(2.2, 2.2, 1)
	_fog.texture_repeat = true
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(96, 64)
	var sheet: MeshInstance3D = MeshInstance3D.new()
	sheet.mesh = plane
	sheet.material_override = _fog
	# Over relief the mist floats just above the highest ground on the board instead of cutting the hills.
	var top: float = 0.0
	for x in range(-21, 22, 2):
		for z in range(-13, 14, 2): top = maxf(top, diorama.terrain_height(Vector3(x, 0, z)))
	sheet.position.y = 0.45 + top
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sheet)
	sheet.add_to_group(DETAIL_GROUP)


## Floating specks: fireflies in the swamp, dust in the canyon, pollen in the vale.
func _motes(color: Color, amount: int, lifetime: float, glow: float) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = glow > 0.3
	material.emission = color
	material.emission_energy_multiplier = glow
	var speck: SphereMesh = SphereMesh.new()
	speck.radius = 0.05
	speck.height = 0.1
	speck.radial_segments = 6
	speck.rings = 3
	speck.material = material
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.mesh = speck
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(20, 0.6, 12)
	particles.position.y = 1.2
	particles.direction = Vector3(1, 0.3, 0.2)
	particles.spread = 60
	particles.gravity = Vector3(0, 0.05, 0)
	particles.initial_velocity_min = 0.15
	particles.initial_velocity_max = 0.45
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.3
	add_child(particles)
	particles.add_to_group(DETAIL_GROUP)
