## Places the camera-matched sprites rendered by tools/assets/render_sprites.py. Each prop is a quad turned
## to face the fixed game camera, anchored so the model's base sits on the terrain, plus a flat ground
## shadow. Materials and metadata are cached, so a forest of sprites costs a few draw calls per kind.
class_name SpritePropsV2
extends RefCounted

const FOLDER: String = "res://art/sprites3d/"
const SHADER: String = "res://scripts/presentation3d/sprite_prop.gdshader"
# Faces the camera at Diorama3D's fixed position (0, 33, 29): normal (0, 0.751, 0.660).
const FACING: float = -0.8504

static var _info: Dictionary = {}
static var _materials: Dictionary = {}
static var _shadows: Dictionary = {}


static func info(name: String) -> Dictionary:
	if not _info.has(name):
		_info[name] = JSON.parse_string(FileAccess.get_file_as_string(FOLDER + name + ".json")) as Dictionary
	return _info[name]


static func _material(name: String, sway: float) -> ShaderMaterial:
	var key: String = "%s:%.2f" % [name, sway]
	if not _materials.has(key):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load(SHADER) as Shader
		material.set_shader_parameter("sprite", load(FOLDER + name + ".png") as Texture2D)
		material.set_shader_parameter("sway", sway)
		material.set_shader_parameter("base_v", float(info(name).pivot_uv[1]))
		_materials[key] = material
	return _materials[key]


static func _shadow_material(name: String) -> StandardMaterial3D:
	if not _shadows.has(name):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_texture = load(FOLDER + name + "_shadow.png") as Texture2D
		material.albedo_color = Color(0, 0, 0, 0.55)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.no_depth_test = false
		material.render_priority = -1
		_shadows[name] = material
	return _shadows[name]


## height: wanted model height in metres; ground: point on the terrain under the model's base.
static func place(parent: Node3D, name: String, ground: Vector3, height: float, flip: bool = false, sway: float = 1.0) -> Node3D:
	var data: Dictionary = info(name)
	var factor: float = height / maxf(0.01, float(data.height))
	var size: float = float(data.ortho_scale) * factor
	var holder: Node3D = Node3D.new()
	holder.position = ground
	parent.add_child(holder)
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(size, size)
	var card: MeshInstance3D = MeshInstance3D.new()
	card.mesh = quad
	card.material_override = _material(name, sway)
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	card.rotation.x = FACING
	var pivot: Vector2 = Vector2(float(data.pivot_uv[0]), float(data.pivot_uv[1]))
	var local: Vector3 = Vector3((pivot.x - 0.5) * size * (-1.0 if flip else 1.0), (0.5 - pivot.y) * size, 0)
	if flip: card.scale.x = -1
	card.position = -(card.basis * local)
	holder.add_child(card)
	var plane: PlaneMesh = PlaneMesh.new()
	var shadow_size: float = float(data.shadow_scale) * factor
	plane.size = Vector2(shadow_size, shadow_size)
	var shadow: MeshInstance3D = MeshInstance3D.new()
	shadow.mesh = plane
	shadow.material_override = _shadow_material(name)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.position = Vector3(0, 0.03, 0)
	if flip: shadow.scale.x = -1
	holder.add_child(shadow)
	return holder
