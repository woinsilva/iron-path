class_name SceneCraft3D extends RefCounted

static func material(color: Color, roughness: float = 0.85, metallic: float = 0.0) -> StandardMaterial3D:
	var value: StandardMaterial3D = StandardMaterial3D.new()
	value.albedo_color = color
	value.roughness = roughness
	value.metallic = metallic
	return value

static func mesh(parent: Node3D, geometry: Mesh, position: Vector3, surface: Material) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = geometry
	instance.position = position
	instance.material_override = surface
	parent.add_child(instance)
	return instance

static func box(parent: Node3D, size: Vector3, position: Vector3, surface: Material) -> MeshInstance3D:
	var geometry: BoxMesh = BoxMesh.new()
	geometry.size = size
	return mesh(parent, geometry, position, surface)

static func cylinder(parent: Node3D, radius: float, height: float, position: Vector3, surface: Material, sides: int = 16) -> MeshInstance3D:
	var geometry: CylinderMesh = CylinderMesh.new()
	geometry.top_radius = radius
	geometry.bottom_radius = radius
	geometry.height = height
	geometry.radial_segments = sides
	return mesh(parent, geometry, position, surface)

static func sphere(parent: Node3D, radius: float, position: Vector3, surface: Material) -> MeshInstance3D:
	var geometry: SphereMesh = SphereMesh.new()
	geometry.radius = radius
	geometry.height = radius * 2.0
	geometry.radial_segments = 12
	geometry.rings = 6
	return mesh(parent, geometry, position, surface)

static func beam(parent: Node3D, start: Vector3, finish: Vector3, thickness: float, surface: Material) -> MeshInstance3D:
	var value: MeshInstance3D = box(parent, Vector3(thickness, start.distance_to(finish), thickness), (start + finish) * 0.5, surface)
	value.quaternion = Quaternion(Vector3.UP, (finish - start).normalized())
	return value

static func find_node_type(node: Node, type_name: String) -> Node:
	if node.is_class(type_name):
		return node
	for child in node.get_children():
		var result: Node = find_node_type(child, type_name)
		if result:
			return result
	return null

static func family_color(family: String) -> Color:
	var palette: Dictionary = {"archer": "d3bc84", "cannon": "d9a574", "frost": "76cfed", "venom": "92c968", "bleed": "cb7566", "anti_air": "e6ce8a", "arcane": "b69be0", "banner": "65afa5"}
	return Color(str(palette.get(family, "d3bc84")))
