class_name ColossusActorV2 extends RiggedActor3D
## Original stone/bronze body bound to the licensed shared skeletal animation rig.
var stone_color: Color = Color("505956")
var face_color: Color = Color("77817a")
var metal_color: Color = Color("aa7544")
var core_color: Color = Color("dc7f35")
var core_material: StandardMaterial3D
func _ready() -> void:
	super._ready()
	_hide_source_meshes(model)
	health_anchor.position.y = 2.05
	var basalt: StandardMaterial3D = SceneCraft3D.material(stone_color, 0.9, 0.1)
	var face: StandardMaterial3D = SceneCraft3D.material(face_color, 0.95)
	var bronze: StandardMaterial3D = SceneCraft3D.material(metal_color, 0.55, 0.6)
	core_material = SceneCraft3D.material(core_color, 0.5)
	core_material.emission_enabled = true
	core_material.emission = core_color
	core_material.emission_energy_multiplier = 0.5
	_block("hips", Vector3(0.6, 0.4, 0.5), Vector3.ZERO, basalt)
	_block("chest", Vector3(0.9, 0.65, 0.65), Vector3(0, -0.05, 0), basalt)
	_block("chest", Vector3(0.66, 0.12, 0.72), Vector3(0, 0.15, 0), bronze)
	_block("chest", Vector3(0.23, 0.28, 0.08), Vector3(0, -0.03, 0.37), core_material)
	for sign: float in [-1, 1]: _block("chest", Vector3(0.1, 0.3, 0.07), Vector3(sign * 0.18, -0.03, -0.37), core_material)
	_block("head", Vector3(0.67, 0.48, 0.6), Vector3(0, 0.15, 0), face)
	for sign: float in [-1, 1]:
		var suffix: String = ".l" if sign > 0 else ".r"
		_block("upperarm" + suffix, Vector3(0.38, 0.35, 0.42), Vector3(sign * 0.11, 0, 0), basalt)
		_block("lowerarm" + suffix, Vector3(0.32, 0.34, 0.38), Vector3(sign * 0.12, 0, 0), bronze)
		_block("hand" + suffix, Vector3(0.43, 0.4, 0.43), Vector3(sign * 0.03, 0, 0), basalt)
		_block("upperleg" + suffix, Vector3(0.3, 0.28, 0.32), Vector3(0, -0.1, 0), basalt)
		_block("lowerleg" + suffix, Vector3(0.3, 0.24, 0.32), Vector3(0, -0.06, 0), bronze)
		_block("foot" + suffix, Vector3(0.36, 0.18, 0.5), Vector3(0, -0.04, 0.08), basalt)
		_block("head", Vector3(0.12, 0.065, 0.06), Vector3(sign * 0.15, 0.18, 0.32), core_material)
func _hide_source_meshes(node: Node) -> void:
	if node is MeshInstance3D: (node as MeshInstance3D).visible = false
	for child in node.get_children(): _hide_source_meshes(child)
func _block(bone: String, size: Vector3, offset: Vector3, material: StandardMaterial3D) -> void:
	var mount: BoneAttachment3D = BoneAttachment3D.new()
	mount.bone_name = bone
	skeleton.add_child(mount)
	var rest: Transform3D = skeleton.get_bone_global_rest(skeleton.find_bone(bone))
	var pivot: Node3D = Node3D.new()
	pivot.transform = Transform3D(rest.basis.inverse(), rest.basis.inverse() * offset)
	mount.add_child(pivot)
	SceneCraft3D.mesh(pivot, _carved_block(size), Vector3.ZERO, material)
func set_ability_state(windup: bool) -> void:
	core_material.emission_energy_multiplier = 1.5 if windup else 0.5

func _carved_block(size: Vector3) -> ArrayMesh:
	var h: Vector3 = size * 0.5
	var bevel: float = minf(0.055, minf(h.x, minf(h.y, h.z)) * 0.35)
	var inner: Vector3 = h - Vector3.ONE * bevel
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in range(3):
		var u: int = (axis + 1) % 3
		var v: int = (axis + 2) % 3
		for sign: float in [-1, 1]:
			var face: Array[Vector3] = []
			for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var point: Vector3 = Vector3.ZERO
				point[axis] = h[axis] * sign
				point[u] = inner[u] * corner.x
				point[v] = inner[v] * corner.y
				face.append(point)
			_polygon(tool, face)
		for a: float in [-1, 1]:
			for b: float in [-1, 1]:
				var edge: Array[Vector3] = []
				for coordinates: Vector3 in [Vector3(-1, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 0), Vector3(-1, 1, 0)]:
					var point: Vector3 = Vector3.ZERO
					point[axis] = inner[axis] * coordinates.x
					point[u] = (inner[u] if coordinates.y == 0 else h[u]) * a
					point[v] = (inner[v] if coordinates.z == 0 else h[v]) * b
					edge.append(point)
				_polygon(tool, edge)
	for x: float in [-1, 1]:
		for y: float in [-1, 1]:
			for z: float in [-1, 1]:
				_polygon(tool, [Vector3(h.x * x, inner.y * y, inner.z * z), Vector3(inner.x * x, h.y * y, inner.z * z), Vector3(inner.x * x, inner.y * y, h.z * z)])
	return tool.commit()
func _polygon(tool: SurfaceTool, points: Array[Vector3]) -> void:
	for index in range(1, points.size() - 1):
		var a: Vector3 = points[0]
		var b: Vector3 = points[index]
		var c: Vector3 = points[index + 1]
		var normal: Vector3 = (b - a).cross(c - a).normalized()
		if normal.dot((a + b + c) / 3) < 0: normal = -normal
		if (b - a).cross(c - a).dot(normal) > 0:
			var swap: Vector3 = b
			b = c
			c = swap
		for point: Vector3 in [a, b, c]:
			tool.set_normal(normal)
			tool.add_vertex(point)

func impact_position() -> Vector3:
	return model.to_global(Vector3(0, 0.95, 0))
