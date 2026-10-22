class_name RiggedActor3D extends Node3D
## Real skeletal animation. World position belongs to the simulation/route driver.

@export var model_path: String = "res://art/models/goblin.glb"
var _flag_material: ShaderMaterial
var _flag_time: float = 0
@export var initial_phase: float = 0.0
var _phase_applied: bool = false
var _hit_recovery: float = 0

var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var animation_tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var current_state: StringName = &"Idle"
var gait_speed: float = 1.0
var dead: bool = false
var health_ratio: float = 1.0
var health_anchor: Node3D
var _heading: float = 0.0
var gait_profile: Dictionary

func _ready() -> void:
	gait_profile = JSON.parse_string(FileAccess.get_file_as_string("res://data/presentation/rig_gaits.json").trim_prefix("\ufeff")) as Dictionary
	health_anchor = Node3D.new()
	health_anchor.name = "HealthAnchor"
	health_anchor.position = Vector3(0, 2.55, 0)
	add_child(health_anchor)
	model = load(model_path).instantiate() as Node3D
	add_child(model)
	model.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_style_model(model)
	_attach_variant()
	_attach_equipment()
	skeleton = SceneCraft3D.find_node_type(model, "Skeleton3D") as Skeleton3D
	player = SceneCraft3D.find_node_type(model, "AnimationPlayer") as AnimationPlayer
	for clip: String in ["walk", "run", "idle"]:
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var machine: AnimationNodeStateMachine = AnimationNodeStateMachine.new()
	for entry: Array in [["Idle", "idle"], ["Walk", "walk"], ["Run", "run"], ["Death", "death"]]:
		var animation: AnimationNodeAnimation = AnimationNodeAnimation.new()
		animation.animation = entry[1]
		machine.add_node(entry[0], animation)
	for origin: String in ["Idle", "Walk", "Run", "Death"]:
		for destination: String in ["Idle", "Walk", "Run", "Death"]:
			if origin == destination:
				continue
			var transition: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.16
			machine.add_transition(origin, destination, transition)
	animation_tree = AnimationTree.new()
	model.add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(player)
	var graph: AnimationNodeBlendTree = AnimationNodeBlendTree.new()
	graph.add_node("States", machine)
	graph.add_node("Rate", AnimationNodeTimeScale.new())
	graph.connect_node("Rate", 0, "States")
	var hit_clip: AnimationNodeAnimation = AnimationNodeAnimation.new()
	hit_clip.animation = "hit"
	graph.add_node("HitClip", hit_clip)
	var hit: AnimationNodeOneShot = AnimationNodeOneShot.new()
	hit.fadein_time = 0.06
	hit.fadeout_time = 0.12
	hit.filter_enabled = true
	var hit_animation: Animation = player.get_animation("hit")
	for index in range(hit_animation.get_track_count()):
		var path: NodePath = hit_animation.track_get_path(index)
		if path.get_subname_count() > 0 and str(path.get_subname(0)) in ["head", "chest", "spine", "upperarm.l", "upperarm.r"]:
			hit.set_filter_path(path, true)
	graph.add_node("Hit", hit)
	graph.connect_node("Hit", 0, "Rate")
	graph.connect_node("Hit", 1, "HitClip")
	if player.has_animation("rally"):
		var rally_clip: AnimationNodeAnimation = AnimationNodeAnimation.new()
		rally_clip.animation = "rally"
		graph.add_node("RallyClip", rally_clip)
		graph.add_node("RallyRate", AnimationNodeTimeScale.new())
		graph.connect_node("RallyRate", 0, "RallyClip")
		var rally: AnimationNodeOneShot = AnimationNodeOneShot.new()
		rally.fadein_time = 0.12
		rally.fadeout_time = 0.18
		rally.filter_enabled = true
		var clip: Animation = player.get_animation("rally")
		for index in range(clip.get_track_count()):
			var path: NodePath = clip.track_get_path(index)
			if path.get_subname_count() > 0 and str(path.get_subname(0)) in ["head", "chest", "spine", "upperarm.l", "upperarm.r", "lowerarm.l", "lowerarm.r", "wrist.l", "wrist.r", "hand.l", "hand.r", "handslot.l", "handslot.r"]: rally.set_filter_path(path, true)
		graph.add_node("Rally", rally)
		graph.connect_node("Rally", 0, "Hit")
		graph.connect_node("Rally", 1, "RallyRate")
		graph.connect_node("output", 0, "Rally")
	else:
		graph.connect_node("output", 0, "Hit")
	animation_tree.tree_root = graph
	animation_tree.active = true
	playback = animation_tree.get("parameters/States/playback") as AnimationNodeStateMachinePlayback
	playback.start("Idle")

func animate_motion(velocity: Vector3, delta: float) -> void:
	if dead:
		return
	var speed: float = Vector2(velocity.x, velocity.z).length()
	var model_scale: float = maxf(0.01, absf(global_basis.get_scale().y))
	var walk_reference: float = float(gait_profile.walk_stance_speed) * model_scale
	var run_reference: float = float(gait_profile.run_stance_speed) * model_scale
	var requested: StringName = &"Idle" if speed < 0.05 else (&"Run" if speed > walk_reference * float(gait_profile.max_walk_rate) else &"Walk")
	if requested != current_state:
		current_state = requested
		playback.travel(requested)
		if requested == &"Walk" and not _phase_applied:
			animation_tree.advance(initial_phase)
			_phase_applied = true
	if speed > 0.05:
		var desired: float = atan2(velocity.x, velocity.z)
		_heading = lerp_angle(_heading, desired, 1.0 - exp(-delta * 12.0))
		rotation.y = _heading
	gait_speed = clampf(speed / (run_reference if requested == &"Run" else walk_reference), 0.20, 2.5) if speed > 0.05 else 1.0
	animation_tree.set("parameters/Rate/scale", gait_speed)

func die() -> void:
	dead = true
	animation_tree.set("parameters/Hit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	if player.has_animation("rally"): animation_tree.set("parameters/Rally/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	health_ratio = 0.0
	current_state = &"Death"
	playback.travel("Death")

func revive() -> void:
	_hit_recovery = 0
	dead = false
	health_ratio = 1.0
	current_state = &"Idle"
	playback.start("Idle", true)
	_phase_applied = false

func set_heading(direction: Vector3) -> void:
	_heading = atan2(direction.x, direction.z)
	rotation.y = _heading

func react_to_hit() -> void:
	if _accept_hit_reaction():
		health_ratio = maxf(0.05, health_ratio - 0.2)
		animation_tree.set("parameters/Hit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _style_model(node: Node) -> void:
	if node is MeshInstance3D and str(node.name) != "Goblin_Ears":
		var instance: MeshInstance3D = node as MeshInstance3D
		for index in range(instance.mesh.get_surface_count()):
			var source: StandardMaterial3D = instance.mesh.surface_get_material(index) as StandardMaterial3D
			if source:
				var material: ShaderMaterial = ShaderMaterial.new()
				material.shader = load("res://scripts/presentation3d/goblin.gdshader") as Shader
				material.set_shader_parameter("source_texture", source.albedo_texture)
				material.set_shader_parameter("green_skin", "Head" in str(node.name) or "Arm" in str(node.name) or (model_path.ends_with("captain.glb") and ("Body" in str(node.name) or "Leg" in str(node.name))))
				instance.set_surface_override_material(index, material)
	for child in node.get_children():
		_style_model(child)

func _attach_variant() -> void:
	var variant: String = str(get_meta("type_id", "grunt"))
	if variant in ["resistant", "summoner"]:
		health_anchor.position.y = 2.95
		var rune_rig: Skeleton3D = SceneCraft3D.find_node_type(model, "Skeleton3D") as Skeleton3D
		var crown: BoneAttachment3D = BoneAttachment3D.new()
		crown.name = "SummoningCrown" if variant == "summoner" else "RunicCrown"
		crown.bone_name = "head"
		rune_rig.add_child(crown)
		var rune_pivot: Node3D = Node3D.new()
		rune_pivot.basis = rune_rig.get_bone_global_rest(rune_rig.find_bone("head")).basis.inverse()
		crown.add_child(rune_pivot)
		var rune_material: StandardMaterial3D = SceneCraft3D.material(Color("b69be0"), 0.4, 0.2)
		rune_material.emission_enabled = true
		rune_material.emission = Color("7751ad")
		rune_material.emission_energy_multiplier = 0.6
		var halo: TorusMesh = TorusMesh.new()
		halo.inner_radius = 0.6 if variant == "summoner" else 0.42
		halo.outer_radius = 0.69 if variant == "summoner" else 0.49
		halo.rings = 20
		halo.ring_segments = 6
		SceneCraft3D.mesh(rune_pivot, halo, Vector3(0, 1.2, 0), rune_material)
		for index in range(3):
			var angle: float = index * TAU / 3
			var gem: MeshInstance3D = SceneCraft3D.box(rune_pivot, Vector3(0.13, 0.24, 0.13), Vector3(sin(angle) * 0.48, 1.21, cos(angle) * 0.48), rune_material)
			gem.rotation.z = PI / 4
		return
	if variant in ["grunt_elite", "runner_veteran", "armored_elite"]:
		var elite_rig: Skeleton3D = SceneCraft3D.find_node_type(model, "Skeleton3D") as Skeleton3D
		var armor_mount: BoneAttachment3D = BoneAttachment3D.new()
		armor_mount.name = "EliteArmor"
		armor_mount.bone_name = "chest"
		elite_rig.add_child(armor_mount)
		var plate: StandardMaterial3D = SceneCraft3D.material(Color("ba9959") if variant == "armored_elite" else Color("756956"), 0.55, 0.55)
		for side: float in [-1, 1]:
			SceneCraft3D.sphere(armor_mount, 0.32, Vector3(side * 0.48, 0.12, 0), plate)
		return
	if not variant.begins_with("dummy_"): return
	var rig: Skeleton3D = SceneCraft3D.find_node_type(model, "Skeleton3D") as Skeleton3D
	var attachment: BoneAttachment3D = BoneAttachment3D.new()
	attachment.bone_name = "chest" if variant == "dummy_brute" else "head"
	rig.add_child(attachment)
	var metal: StandardMaterial3D = SceneCraft3D.material(Color("7d8b91"), 0.5, 0.6)
	if variant == "dummy_armored":
		SceneCraft3D.cylinder(attachment, 0.42, 0.28, Vector3(0, 0.1, 0), metal, 12)
	elif variant == "dummy_resistant":
		var rune: TorusMesh = TorusMesh.new()
		rune.inner_radius = 0.5
		rune.outer_radius = 0.56
		rune.rings = 20
		rune.ring_segments = 6
		SceneCraft3D.mesh(attachment, rune, Vector3(0, 0.2, 0), SceneCraft3D.material(Color("b69be0")))
	else:
		for side: float in [-1, 1]:
			SceneCraft3D.sphere(attachment, 0.32, Vector3(side * 0.48, 0.15, 0), metal)

func _attach_equipment() -> void:
	var rig: Skeleton3D = SceneCraft3D.find_node_type(model, "Skeleton3D") as Skeleton3D
	for item: Dictionary in get_meta("equipment", []):
		var attachment: BoneAttachment3D = BoneAttachment3D.new()
		attachment.bone_name = str(item.slot)
		rig.add_child(attachment)
		attachment.add_child(load("res://art/models/%s.glb" % str(item.model)).instantiate())
	if str(get_meta("type_id", "")) in ["boss_captain", "standardbearer"]:
		var back: BoneAttachment3D = BoneAttachment3D.new()
		back.bone_name = "chest"
		rig.add_child(back)
		var pole: StandardMaterial3D = SceneCraft3D.material(Color("8e6e3c"))
		SceneCraft3D.cylinder(back, 0.045, 2.0, Vector3(0, 0.75, -0.3), pole, 8)
		var cloth: BoxMesh = BoxMesh.new()
		cloth.size = Vector3(0.65, 0.7, 0.035)
		cloth.subdivide_width = 6
		cloth.subdivide_height = 4
		_flag_material = ShaderMaterial.new()
		_flag_material.shader = load("res://scripts/presentation3d/banner.gdshader") as Shader
		_flag_material.set_shader_parameter("tint", Color("417b88") if str(get_meta("type_id", "")) == "standardbearer" else Color("91483b"))
		SceneCraft3D.mesh(back, cloth, Vector3(0.33, 1.4, -0.3), _flag_material)
func perform_rally(duration: float) -> void:
	if dead: return
	assert(player.has_animation("rally"), "Rally presentation requires its skeletal clip")
	animation_tree.set("parameters/RallyRate/scale", player.get_animation("rally").length / maxf(duration, 0.1))
	animation_tree.set("parameters/Rally/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
func _process(delta: float) -> void:
	_hit_recovery = maxf(0,_hit_recovery - delta)
	if _flag_material != null:
		_flag_time += delta
		_flag_material.set_shader_parameter("phase", _flag_time)

func impact_position() -> Vector3:
	return to_global(Vector3(0, 1.1, 0))

func _accept_hit_reaction() -> bool:
	if dead or _hit_recovery > 0: return false
	_hit_recovery = 0.22
	return true
