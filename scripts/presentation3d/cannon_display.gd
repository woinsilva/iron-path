class_name CannonDisplay3D extends Node3D

var turret: Node3D
var barrel: Node3D
var _recoil: Tween

func _ready() -> void:
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("979587"))
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("805334"))
	var iron: StandardMaterial3D = SceneCraft3D.material(Color("465464"), 0.4, 0.7)
	var rim: StandardMaterial3D = SceneCraft3D.material(Color("a58a50"), 0.4, 0.5)
	SceneCraft3D.cylinder(self, 1.05, 0.30, Vector3(0, 0.15, 0), stone, 12)
	turret = Node3D.new()
	turret.position.y = 0.75
	add_child(turret)
	for side: float in [-0.7, 0.7]:
		var wheel: MeshInstance3D = SceneCraft3D.cylinder(turret, 0.52, 0.18, Vector3(side, 0, 0), wood, 12)
		wheel.rotation.z = PI / 2.0
		var hub: MeshInstance3D = SceneCraft3D.cylinder(turret, 0.15, 0.22, Vector3(side, 0, 0), rim, 12)
		hub.rotation.z = PI / 2.0
	SceneCraft3D.box(turret, Vector3(1.4, 0.25, 1.1), Vector3(0, -0.15, 0), wood)
	barrel = Node3D.new()
	barrel.position.y = 0.25
	turret.add_child(barrel)
	var tube: MeshInstance3D = SceneCraft3D.cylinder(barrel, 0.34, 1.75, Vector3(0, 0, 0.25), iron, 20)
	tube.rotation.x = PI / 2.0
	for z: float in [-0.4, 0.7]:
		var band: MeshInstance3D = SceneCraft3D.cylinder(barrel, 0.38, 0.11, Vector3(0, 0, z), rim, 20)
		band.rotation.x = PI / 2.0
	var mouth: MeshInstance3D = SceneCraft3D.cylinder(barrel, 0.28, 0.03, Vector3(0, 0, 1.15), SceneCraft3D.material(Color("151d28")), 20)
	mouth.rotation.x = PI / 2.0

func aim_at(target: Vector3, delta: float) -> void:
	var direction: Vector3 = target - global_position
	turret.rotation.y = lerp_angle(turret.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-delta * 7.0))

func prepare_attack(_duration: float) -> void:
	if _recoil and _recoil.is_valid():
		_recoil.kill()
	barrel.position.z = 0.0

func release_attack() -> void:
	barrel.position.z = -0.24
	_recoil = create_tween()
	_recoil.tween_property(barrel, "position:z", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func cancel_attack() -> void:
	if _recoil and _recoil.is_valid():
		_recoil.kill()
	barrel.position.z = 0.0

func muzzle_position() -> Vector3:
	return barrel.to_global(Vector3(0, 0, 1.15))
