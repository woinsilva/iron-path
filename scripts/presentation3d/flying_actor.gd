class_name FlyingActorV2 extends RiggedActor3D
## Volumetric wasp with jointed wings. Motion follows the authoritative route.
var wings: Array[Node3D] = []
var _flight_time: float = 0.0
func _ready() -> void:
	health_anchor = Node3D.new()
	health_anchor.position.y = 1.2
	add_child(health_anchor)
	model = Node3D.new()
	add_child(model)
	model.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var gold: StandardMaterial3D = SceneCraft3D.material(Color("d2a94c"))
	var dark: StandardMaterial3D = SceneCraft3D.material(Color("26352f"))
	var glass: StandardMaterial3D = SceneCraft3D.material(Color("b1d6df"), 0.35)
	var body: MeshInstance3D = SceneCraft3D.sphere(model, 0.46, Vector3.ZERO, gold)
	body.scale = Vector3(0.8, 0.8, 1.4)
	for z: float in [-0.35, 0, 0.35]:
		var stripe: MeshInstance3D = SceneCraft3D.cylinder(model, 0.4, 0.13, Vector3(0, 0, z), dark, 12)
		stripe.rotation.x = PI * 0.5
	if str(get_meta("type_id", "")) == "flyer_heavy":
		var plate: StandardMaterial3D = SceneCraft3D.material(Color("7b9292"), 0.45, 0.65)
		for z: float in [-0.3, 0, 0.3]:
			var armor: MeshInstance3D = SceneCraft3D.sphere(model, 0.36, Vector3(0, 0.22, z), plate)
			armor.scale = Vector3(1.25, 0.65, 0.75)
	SceneCraft3D.sphere(model, 0.29, Vector3(0, 0.02, 0.65), dark)
	for side: float in [-1, 1]:
		SceneCraft3D.sphere(model, 0.11, Vector3(side * 0.2, 0.15, 0.85), gold)
		var joint: Node3D = Node3D.new()
		joint.position = Vector3(side * 0.28, 0.18, 0)
		model.add_child(joint)
		var wing: MeshInstance3D = SceneCraft3D.sphere(joint, 0.65, Vector3(side * 0.55, 0, -0.15), glass)
		wing.scale = Vector3(1.4, 0.045, 0.55)
		wings.append(joint)
		for index in range(3):
			SceneCraft3D.beam(model, Vector3(side * 0.25, -0.15, -0.3 + index * 0.28), Vector3(side * 0.6, -0.52, -0.38 + index * 0.28), 0.045, dark)
func _process(delta: float) -> void:
	super._process(delta)
	_flight_time += delta
	if dead:
		model.position.y -= delta * 2.5
		model.rotation.z += delta * 2.0
		return
	model.position.y = sin(_flight_time * 5.0 + initial_phase) * 0.07
	for index in range(wings.size()):
		wings[index].rotation.z = sin(_flight_time * 42 + initial_phase) * 0.5 * (-1 if index == 0 else 1)
func animate_motion(velocity: Vector3, delta: float) -> void:
	if not dead and velocity.length() > 0.05:
		var desired: float = atan2(velocity.x, velocity.z)
		_heading = lerp_angle(_heading, desired, 1.0 - exp(-delta * 7))
		rotation.y = _heading
func die() -> void:
	dead = true
	health_ratio = 0
func revive() -> void:
	_hit_recovery = 0
	dead = false
	health_ratio = 1
	model.position = Vector3.ZERO
	model.rotation = Vector3.ZERO
func react_to_hit() -> void:
	if _accept_hit_reaction(): model.position.y -= 0.05

func impact_position() -> Vector3:
	return model.to_global(Vector3.ZERO)
