class_name CrawlerActorV2 extends RiggedActor3D
var legs: Array[Node3D] = []
var _burrow_dust: Node3D
var _stride: float = 0.0
var _summon_rune: MeshInstance3D
func _ready() -> void:
	health_anchor = Node3D.new()
	health_anchor.position.y = 1.35
	add_child(health_anchor)
	model = Node3D.new()
	add_child(model)
	model.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var shell: StandardMaterial3D = SceneCraft3D.material(Color("8f7752") if str(get_meta("type_id", "")) == "burrower" else Color("745682"))
	var dark: StandardMaterial3D = SceneCraft3D.material(Color("34303e"))
	var eye: StandardMaterial3D = SceneCraft3D.material(Color("e2ac69"))
	var seal: TorusMesh = TorusMesh.new()
	seal.inner_radius = 0.19
	seal.outer_radius = 0.25
	seal.rings = 12
	seal.ring_segments = 4
	_summon_rune = SceneCraft3D.mesh(model, seal, Vector3(0, 0.8, -0.12), SceneCraft3D.material(Color("b7ced7")))
	_summon_rune.visible = false
	_burrow_dust = Node3D.new()
	_burrow_dust.visible = false
	add_child(_burrow_dust)
	var soil: StandardMaterial3D = SceneCraft3D.material(Color("8c7a57"))
	for index in range(5):
		var mound: MeshInstance3D = SceneCraft3D.sphere(_burrow_dust, 0.18 + index * 0.025, Vector3(sin(index * 2.4) * 0.22, 0.13, -index * 0.24), soil)
		mound.scale.y = 0.55
	if str(get_meta("type_id", "")) == "burrower":
		for sign: float in [-1, 1]:
			SceneCraft3D.box(model, Vector3(0.3, 0.12, 0.55), Vector3(sign * 0.4, 0.25, 0.6), soil)
	var body: MeshInstance3D = SceneCraft3D.sphere(model, 0.52, Vector3(0, 0.45, -0.12), shell)
	body.scale = Vector3(0.9, 0.6, 1.3)
	SceneCraft3D.sphere(model, 0.25, Vector3(0, 0.4, 0.55), dark)
	for side: float in [-1, 1]:
		SceneCraft3D.sphere(model, 0.075, Vector3(side * 0.14, 0.48, 0.75), eye)
		for index in range(3):
			var joint: Node3D = Node3D.new()
			joint.position = Vector3(side * 0.28, 0.42, -0.45 + index * 0.4)
			model.add_child(joint)
			SceneCraft3D.beam(joint, Vector3.ZERO, Vector3(side * 0.42, -0.02, -0.12), 0.085, dark)
			SceneCraft3D.beam(joint, Vector3(side * 0.42, -0.02, -0.12), Vector3(side * 0.57, -0.38, 0.1), 0.065, dark)
			legs.append(joint)
func animate_motion(velocity: Vector3, delta: float) -> void:
	if dead: return
	_stride += Vector2(velocity.x,velocity.z).length() * delta * 9
	for index in range(legs.size()):
		var phase: float = _stride + (PI if index % 2 else 0)
		legs[index].rotation.y = sin(phase) * 0.3
		legs[index].rotation.z = maxf(0, cos(phase)) * 0.12 * (-1 if index < 3 else 1)
	if velocity.length() > 0.05:
		_heading = lerp_angle(_heading, atan2(velocity.x, velocity.z), 1.0 - exp(-delta * 12))
		rotation.y = _heading
func die() -> void:
	dead = true
	health_ratio = 0
	model.rotation.z = PI
	model.position.y = 0.6
func revive() -> void:
	_hit_recovery = 0
	dead = false
	health_ratio = 1
	model.rotation = Vector3.ZERO
	model.position = Vector3.ZERO
func react_to_hit() -> void:
	if _accept_hit_reaction(): model.scale = Vector3.ONE * 0.95
func _process(delta: float) -> void:
	super._process(delta)
	model.scale = model.scale.lerp(Vector3.ONE, 1.0 - exp(-delta * 15))

func set_summoned(summoned: bool) -> void:
	_summon_rune.visible = summoned

func set_underground(buried: bool) -> void:
	model.visible = not buried
	_burrow_dust.visible = buried

func impact_position() -> Vector3:
	return model.to_global(Vector3(0, 0.45, -0.12))
