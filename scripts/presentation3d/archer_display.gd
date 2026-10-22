class_name ArcherDisplay3D extends Node3D

var simulation_controlled: bool = false
var operator_model: Node3D
var operator_player: AnimationPlayer
var turret: Node3D
var bow: Node3D
var _shot_time: float = 0.0
var _ready_to_shoot: bool = false
var _idle_timer: float = 0.0
signal arrow_released(origin: Vector3, direction: Vector3)

func _ready() -> void:
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("aaa48c"))
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("805333"))
	var plank: StandardMaterial3D = SceneCraft3D.material(Color("b58a53"))
	var iron: StandardMaterial3D = SceneCraft3D.material(Color("454e54"), 0.5, 0.5)
	var canvas: StandardMaterial3D = SceneCraft3D.material(Color("426b45"))
	SceneCraft3D.cylinder(self, 1.12, 0.24, Vector3(0, 0.12, 0), stone, 12)
	SceneCraft3D.cylinder(self, 0.92, 0.22, Vector3(0, 0.34, 0), stone, 12)
	for x: float in [-0.72, 0.72]:
		for z: float in [-0.72, 0.72]:
			SceneCraft3D.box(self, Vector3(0.22, 2.05, 0.22), Vector3(x, 1.45, z), wood)
			SceneCraft3D.box(self, Vector3(0.27, 0.16, 0.27), Vector3(x, 0.85, z), iron)
	for index in range(8):
		SceneCraft3D.box(self, Vector3(0.21, 0.16, 1.85), Vector3(-0.77 + index * 0.22, 2.36, 0), plank)
	for z: float in [-0.75, 0.75]:
		SceneCraft3D.beam(self, Vector3(-0.72, 0.55, z), Vector3(0.72, 2.26, z), 0.12, wood)
	for x: float in [-0.82, 0.82]:
		SceneCraft3D.box(self, Vector3(0.12, 0.5, 1.8), Vector3(x, 2.65, 0), wood)
		SceneCraft3D.box(self, Vector3(0.16, 0.12, 1.9), Vector3(x, 2.91, 0), plank)
	# Canopy stays behind the front firing ledge, leaving the operator readable.
	var roof: PrismMesh = PrismMesh.new()
	roof.size = Vector3(2.15, 0.72, 1.5)
	SceneCraft3D.mesh(self, roof, Vector3(0, 4.02, -0.37), canvas)
	for x: float in [-0.82, 0.82]:
		SceneCraft3D.box(self, Vector3(0.10, 1.6, 0.10), Vector3(x, 3.2, -0.72), wood)
	for index in range(6):
		SceneCraft3D.box(self, Vector3(0.5, 0.07, 0.12), Vector3(0, 0.65 + index * 0.27, 0.88), plank)
	for x: float in [-0.3, 0.3]:
		SceneCraft3D.beam(self, Vector3(x, 0.40, 1.02), Vector3(x, 2.38, 0.86), 0.07, wood)
	turret = Node3D.new()
	turret.position = Vector3(0, 2.45, 0.18)
	add_child(turret)
	operator_model = load("res://art/models/ranger.glb").instantiate() as Node3D
	operator_model.scale = Vector3.ONE * 0.55
	turret.add_child(operator_model)
	operator_player = SceneCraft3D.find_node_type(operator_model, "AnimationPlayer") as AnimationPlayer
	operator_player.get_animation("aim").loop_mode = Animation.LOOP_LINEAR
	operator_player.play("aim")
	var rig: Skeleton3D = SceneCraft3D.find_node_type(operator_model, "Skeleton3D") as Skeleton3D
	var attachment: BoneAttachment3D = BoneAttachment3D.new()
	attachment.bone_name = "handslot.l"
	rig.add_child(attachment)
	bow = load("res://art/models/bow_withString.glb").instantiate() as Node3D
	attachment.add_child(bow)

func aim_at(target: Vector3, delta: float) -> void:
	var direction: Vector3 = target - global_position
	var heading: float = atan2(direction.x, direction.z)
	turret.rotation.y = lerp_angle(turret.rotation.y, heading, 1.0 - exp(-delta * 9.0))

func shoot() -> void:
	if _ready_to_shoot:
		return
	_ready_to_shoot = true
	_shot_time = 0.0
	operator_player.play("draw", 0.08)

func _process(delta: float) -> void:
	if _ready_to_shoot and not simulation_controlled:
		_shot_time += delta
		if _shot_time >= 0.45:
			_ready_to_shoot = false
			operator_player.play("release", 0.04)
			_idle_timer = 0.35
			arrow_released.emit(global_position + Vector3(0, 3.0, 0), turret.global_basis.z)
	elif _idle_timer > 0.0:
		_idle_timer -= delta
		if _idle_timer <= 0.0:
			operator_player.play("aim", 0.12)

func prepare_attack(duration: float) -> void:
	_ready_to_shoot = false
	operator_player.speed_scale = operator_player.get_animation("draw").length / maxf(0.01, duration)
	operator_player.play("draw", 0.08)

func release_attack() -> void:
	operator_player.speed_scale = 1.0
	operator_player.play("release", 0.04)
	_idle_timer = 0.3

func cancel_attack() -> void:
	_ready_to_shoot = false
	operator_player.speed_scale = 1.0
	operator_player.play("aim", 0.1)

func muzzle_position() -> Vector3:
	return bow.global_position
