class_name BannerDisplayV2 extends Node3D
var flag: MeshInstance3D
var _cloth: ShaderMaterial
var _time: float = 0.0
var _pulse: float = 0.0
func _ready() -> void:
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("89978c"))
	var metal: StandardMaterial3D = SceneCraft3D.material(Color("b99d59"), 0.5, 0.5)
	SceneCraft3D.cylinder(self, 0.8, 0.3, Vector3(0, 0.15, 0), stone, 8)
	SceneCraft3D.cylinder(self, 0.46, 0.25, Vector3(0, 0.42, 0), metal, 8)
	SceneCraft3D.cylinder(self, 0.08, 3.6, Vector3(0, 2.1, 0), metal, 12)
	SceneCraft3D.sphere(self, 0.16, Vector3(0, 3.95, 0), metal)
	SceneCraft3D.box(self, Vector3(1.25, 0.08, 0.08), Vector3(0.55, 3.6, 0), metal)
	var cloth: BoxMesh = BoxMesh.new()
	cloth.size = Vector3(1.15, 1.35, 0.035)
	cloth.subdivide_width = 8
	cloth.subdivide_height = 6
	_cloth = ShaderMaterial.new()
	_cloth.shader = load("res://scripts/presentation3d/banner.gdshader") as Shader
	_cloth.set_shader_parameter("phase", 0.0)
	_cloth.set_shader_parameter("pulse", 0.0)
	flag = SceneCraft3D.mesh(self, cloth, Vector3(0.6, 2.9, 0), _cloth)
func _process(delta: float) -> void:
	_time += delta
	_pulse = maxf(0, _pulse - delta)
	_cloth.set_shader_parameter("phase", _time)
	_cloth.set_shader_parameter("pulse", _pulse)
func prepare_attack(_duration: float) -> void:
	_pulse = 1
func release_attack() -> void:
	_pulse = 0.5
func cancel_attack() -> void:
	_pulse = 0
