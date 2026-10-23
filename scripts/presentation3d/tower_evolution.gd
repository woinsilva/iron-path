## Building site shown while a tower is being built or evolves: a scaffold that rises around it, stone
## blocks hauled up on a pulley, hammer sparks, golden motes and a ring of lights on the ground that
## fills as the work progresses. Presentation only: the simulation decides when the work ends.
class_name TowerEvolutionV2
extends Node3D

const SEGMENTS: int = 24
const RING_RADIUS: float = 1.3

var _frame: Node3D
var _segments: Array[MeshInstance3D] = []
var _dim: StandardMaterial3D
var _lit: StandardMaterial3D
var _motes: CPUParticles3D
var _sparks: CPUParticles3D
var _loops: Array[Tween] = []
var _blocks: Array[Node3D] = []
var _shown: int = -1


func _ready() -> void:
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("bb8c53"))
	var rope: StandardMaterial3D = SceneCraft3D.material(Color("d9c79b"))
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("b9b29b"), 0.9)
	_frame = Node3D.new()
	_frame.name = "Scaffold"
	add_child(_frame)
	for x: float in [-0.95, 0.95]:
		for z: float in [-0.95, 0.95]:
			SceneCraft3D.box(_frame, Vector3(0.1, 2.6, 0.1), Vector3(x, 1.3, z), wood)
	for y: float in [1.0, 2.0]:
		for x: float in [-0.95, 0.95]: SceneCraft3D.box(_frame, Vector3(0.08, 0.08, 1.95), Vector3(x, y, 0), wood)
		for z: float in [-0.95, 0.95]: SceneCraft3D.box(_frame, Vector3(1.95, 0.08, 0.08), Vector3(0, y, z), wood)
	SceneCraft3D.beam(_frame, Vector3(-0.95, 0.15, 0.95), Vector3(0.95, 2.0, 0.95), 0.07, wood)
	SceneCraft3D.beam(_frame, Vector3(0.95, 0.15, -0.95), Vector3(-0.95, 2.0, -0.95), 0.07, wood)
	# Pulley arm over one corner with a rope down to the hauled blocks.
	SceneCraft3D.box(_frame, Vector3(0.08, 0.08, 1.0), Vector3(0.95, 2.62, 1.35), wood)
	SceneCraft3D.box(_frame, Vector3(0.03, 2.4, 0.03), Vector3(0.95, 1.4, 1.8), rope)
	for index in range(2):
		var block: MeshInstance3D = SceneCraft3D.box(_frame, Vector3(0.3, 0.24, 0.3), Vector3(0.95, 0.3, 1.8), stone)
		_blocks.append(block)
	# Progress ring: segments light up gold one by one.
	_dim = SceneCraft3D.material(Color(0.12, 0.1, 0.06, 0.55))
	_dim.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dim.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_lit = SceneCraft3D.material(Color("ffd36a"))
	_lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for index in range(SEGMENTS):
		var angle: float = -PI / 2 + index * TAU / SEGMENTS
		var segment: MeshInstance3D = SceneCraft3D.box(self, Vector3(0.24, 0.04, 0.12), Vector3(cos(angle) * RING_RADIUS, 0.21, sin(angle) * RING_RADIUS), _dim)
		segment.rotation.y = -angle + PI / 2
		segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_segments.append(segment)
	_motes = _particles(Color("ffe08a"), 16, 1.8, 0.05)
	_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_motes.emission_ring_axis = Vector3.UP
	_motes.emission_ring_radius = 1.15
	_motes.emission_ring_inner_radius = 0.8
	_motes.emission_ring_height = 0.1
	_motes.direction = Vector3.UP
	_motes.spread = 10
	_motes.gravity = Vector3(0, 0.5, 0)
	_motes.initial_velocity_min = 0.5
	_motes.initial_velocity_max = 1.0
	_motes.position.y = 0.3
	_sparks = _particles(Color("fff2c4"), 10, 0.45, 0.035)
	_sparks.one_shot = true
	_sparks.explosiveness = 0.95
	_sparks.direction = Vector3.UP
	_sparks.spread = 70
	_sparks.gravity = Vector3(0, -7, 0)
	_sparks.initial_velocity_min = 1.4
	_sparks.initial_velocity_max = 2.6
	begin()


func _particles(color: Color, amount: int, lifetime: float, size: float) -> CPUParticles3D:
	var glow: StandardMaterial3D = SceneCraft3D.material(color)
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var dot: SphereMesh = SphereMesh.new()
	dot.radius = size
	dot.height = size * 2.0
	dot.radial_segments = 6
	dot.rings = 3
	dot.material = glow
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.mesh = dot
	particles.amount = amount
	particles.lifetime = lifetime
	add_child(particles)
	return particles


## Starts a new round of work: the scaffold rises out of the ground and the ring resets.
func begin() -> void:
	visible = true
	set_progress(0.0)
	for loop: Tween in _loops: loop.kill()
	_loops.clear()
	_frame.scale = Vector3(1, 0.05, 1)
	var rise: Tween = create_tween()
	rise.tween_property(_frame, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_loops.append(rise)
	for index in range(_blocks.size()):
		var block: Node3D = _blocks[index]
		var haul: Tween = create_tween().set_loops()
		haul.tween_interval(index * 0.9)
		haul.tween_property(block, "position:y", 2.3, 1.6).from(0.3).set_trans(Tween.TRANS_SINE)
		haul.tween_property(block, "position:y", 0.3, 0.2)
		_loops.append(haul)
	var hammer: Tween = create_tween().set_loops()
	hammer.tween_interval(0.42)
	hammer.tween_callback(_strike)
	_loops.append(hammer)
	_motes.emitting = true


func _strike() -> void:
	var corner: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * 0.95
	_sparks.position = Vector3(corner.x, randf_range(0.6, 2.2), corner.y)
	_sparks.restart()


## Work finished or cancelled: hide and stop every loop so idle sites cost nothing.
func finish() -> void:
	for loop: Tween in _loops: loop.kill()
	_loops.clear()
	_motes.emitting = false
	visible = false


func set_progress(value: float) -> void:
	var count: int = clampi(int(floor(clampf(value, 0.0, 1.0) * SEGMENTS)), 0, SEGMENTS)
	if count == _shown: return
	_shown = count
	for index in range(SEGMENTS): _segments[index].material_override = _lit if index < count else _dim
	_motes.speed_scale = 0.7 + value * 0.9
