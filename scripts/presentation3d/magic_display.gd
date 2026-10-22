class_name MagicDisplayV2 extends Node3D
var family: String = "frost"
var core: Node3D
var _time: float = 0.0
var _charge: float = 0.0
var _tint: Color
func _ready() -> void:
	_tint = SceneCraft3D.family_color(family)
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("8d9792"))
	var bronze: StandardMaterial3D = SceneCraft3D.material(Color("817454"), 0.5, 0.5)
	var glow: StandardMaterial3D = SceneCraft3D.material(_tint, 0.35, 0.2)
	glow.emission_enabled = true
	glow.emission = _tint
	glow.emission_energy_multiplier = 0.4
	SceneCraft3D.cylinder(self, 0.78, 0.24, Vector3(0, 0.12, 0), stone, 8)
	core = Node3D.new()
	add_child(core)
	if family == "frost":
		SceneCraft3D.cylinder(self, 0.45, 0.9, Vector3(0, 0.65, 0), stone, 8)
		for side: float in [-1, 1]:
			SceneCraft3D.beam(self, Vector3(side * 0.35, 0.8, 0), Vector3(side * 0.7, 1.55, 0), 0.16, bronze)
		var crystal: PrismMesh = PrismMesh.new()
		crystal.size = Vector3(0.85, 1.6, 0.85)
		var gem: MeshInstance3D = SceneCraft3D.mesh(core, crystal, Vector3.ZERO, glow)
		gem.rotation.x = PI
		core.position.y = 1.8
	elif family == "arcane":
		SceneCraft3D.cylinder(self, 0.48, 1.4, Vector3(0, 1, 0), stone, 6)
		SceneCraft3D.cylinder(self, 0.68, 0.18, Vector3(0, 1.8, 0), bronze, 6)
		SceneCraft3D.sphere(core, 0.42, Vector3.ZERO, glow)
		var halo: TorusMesh = TorusMesh.new()
		halo.inner_radius = 0.62
		halo.outer_radius = 0.69
		halo.rings = 24
		halo.ring_segments = 6
		var ring: MeshInstance3D = SceneCraft3D.mesh(core, halo, Vector3.ZERO, bronze)
		ring.rotation.x = PI / 3
		core.position.y = 2.3
	elif family == "venom":
		SceneCraft3D.cylinder(self, 0.63, 0.9, Vector3(0, 0.65, 0), bronze, 12)
		SceneCraft3D.cylinder(self, 0.56, 0.08, Vector3(0, 1.13, 0), glow, 12)
		for index in range(3):
			var angle: float = index * TAU / 3
			SceneCraft3D.beam(self, Vector3(sin(angle) * 0.65, 0.1, cos(angle) * 0.65), Vector3(sin(angle) * 0.5, 1, cos(angle) * 0.5), 0.13, stone)
		SceneCraft3D.sphere(core, 0.18, Vector3.ZERO, glow)
		core.position.y = 1.4
	else:
		SceneCraft3D.cylinder(self, 0.38, 2.3, Vector3(0, 1.4, 0), stone, 8)
		SceneCraft3D.cylinder(self, 0.65, 0.17, Vector3(0, 2.6, 0), bronze, 12)
		for side: float in [-1, 1]:
			SceneCraft3D.box(self, Vector3(0.15, 0.9, 0.15), Vector3(side * 0.5, 2.9, 0), bronze)
		SceneCraft3D.sphere(core, 0.4, Vector3.ZERO, glow)
		core.position.y = 2.95
func _process(delta: float) -> void:
	_time += delta
	_charge = maxf(0, _charge - delta * 3)
	core.rotation.y += delta * 0.8
	core.scale = Vector3.ONE * (1.0 + _charge * 0.25)
	if family == "frost": core.position.y = 1.8 + sin(_time * 2) * 0.08
func aim_at(_target: Vector3, _delta: float) -> void:
	# The emitter is radially symmetric; its core pulses during the actual windup.
	core.rotation.z = sin(_time * 2) * 0.04
func prepare_attack(_duration: float) -> void:
	_charge = 1.0
func release_attack() -> void:
	_charge = 0.6
func cancel_attack() -> void:
	_charge = 0.0

func muzzle_position() -> Vector3:
	return core.global_position
