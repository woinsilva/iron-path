class_name BallistaDisplayV2 extends Node3D
var turret: Node3D
var rail: Node3D
var _return: Tween
func _ready() -> void:
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("94968a"))
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("805735"))
	var metal: StandardMaterial3D = SceneCraft3D.material(Color("6b7782"), 0.4, 0.6)
	var rope: StandardMaterial3D = SceneCraft3D.material(Color("d5c697"))
	SceneCraft3D.cylinder(self, 0.95, 0.24, Vector3(0, 0.12, 0), stone, 12)
	SceneCraft3D.cylinder(self, 0.3, 1, Vector3(0, 0.7, 0), wood, 12)
	turret = Node3D.new()
	turret.position.y = 1.35
	add_child(turret)
	rail = Node3D.new()
	turret.add_child(rail)
	SceneCraft3D.box(rail, Vector3(0.35, 0.28, 2.2), Vector3.ZERO, wood)
	SceneCraft3D.box(rail, Vector3(0.12, 0.08, 2.25), Vector3(0, 0.18, 0), metal)
	for side: float in [-1, 1]:
		SceneCraft3D.beam(turret, Vector3(0, 0, 0.55), Vector3(side * 1.05, 0.12, 0.65), 0.16, wood)
		SceneCraft3D.beam(turret, Vector3(side * 1.05, 0.12, 0.65), Vector3(side * 1.3, 0.05, 0.2), 0.12, wood)
		SceneCraft3D.beam(turret, Vector3(side * 1.3, 0.05, 0.2), Vector3(0, 0.12, -0.45), 0.035, rope)
		SceneCraft3D.cylinder(turret, 0.1, 0.4, Vector3(side * 0.38, -0.25, -0.6), metal, 8)
func aim_at(target: Vector3, delta: float) -> void:
	var direction: Vector3 = target - global_position
	turret.rotation.y = lerp_angle(turret.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-delta * 7))
func prepare_attack(_duration: float) -> void:
	if _return and _return.is_valid(): _return.kill()
	rail.position.z = -0.12
func release_attack() -> void:
	rail.position.z = -0.25
	_return = create_tween()
	_return.tween_property(rail, "position:z", 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
func cancel_attack() -> void:
	if _return and _return.is_valid(): _return.kill()
	rail.position.z = 0
func muzzle_position() -> Vector3:
	return rail.to_global(Vector3(0, 0.18, 1.1))
