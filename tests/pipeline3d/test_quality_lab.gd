extends SceneTree

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func run() -> void:
	var lab: Node3D = load("res://scenes/lab3d/quality_lab.tscn").instantiate() as Node3D
	root.add_child(lab)
	current_scene = lab
	await process_frame
	check(lab.diorama.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "P0/P1: fixed orthographic Camera3D")
	check(lab.diorama.sunlight.shadow_enabled, "P1: real geometry receives directional shadows")
	check(lab.diorama.route.get_baked_length() > 40.0, "P1: route measured in world meters")
	var actor: RiggedActor3D = lab.actors[1]
	check(actor.health_anchor != null and actor.health_anchor.position.y > 2.0, "P1: health overlay follows a head-height 3D anchor")
	check(actor.skeleton.get_bone_count() == 23, "P0: imported character has 23 actual bones")
	check(actor.player.has_animation("walk") and actor.player.has_animation("run") and actor.player.has_animation("idle") and actor.player.has_animation("death") and actor.player.has_animation("hit"), "P0: all five character clips imported")
	check(actor.player.get_animation("walk").get_track_count() > 20, "P0: walking animation contains skeletal tracks")
	check(actor.animation_tree.active and actor.playback != null, "P1: AnimationTree state blending is active")
	var foot: int = actor.skeleton.find_bone("foot.l")
	check(foot >= 0, "P0: left foot bone preserved by import")
	var original_pose: Quaternion = actor.skeleton.get_bone_pose_rotation(foot)
	var original_position: Vector3 = actor.position
	await create_timer(0.28).timeout
	check(not actor.position.is_equal_approx(original_position), "P1: actor moves along the continuous 3D route")
	check(not actor.skeleton.get_bone_pose_rotation(foot).is_equal_approx(original_pose), "P1: foot pose changes through real skeletal animation")
	check(actor.current_state == &"Walk", "P1: walking state follows movement")
	var paused_pose: Quaternion = actor.skeleton.get_bone_pose_rotation(foot)
	var paused_position: Vector3 = actor.position
	paused = true
	await create_timer(0.15, true).timeout
	check(actor.position.is_equal_approx(paused_position), "P1: pause freezes route progression")
	check(actor.skeleton.get_bone_pose_rotation(foot).is_equal_approx(paused_pose), "P1: pause freezes skeletal pose")
	paused = false
	lab.set("_running", true)
	await create_timer(0.22).timeout
	check(actor.current_state == &"Run", "P1: running uses its own animation state")
	lab.set("_running", false)
	lab.set("_speed", 0.5)
	await create_timer(0.22).timeout
	check(actor.gait_speed < 1.0 and actor.current_state == &"Walk", "P1: slow adjusts walking cadence")
	lab.set("_motion", false)
	await create_timer(0.22).timeout
	check(actor.current_state == &"Idle", "P1: stopping transitions to idle")
	actor.die()
	await create_timer(0.20).timeout
	check(actor.dead and actor.current_state == &"Death", "P1: death has a dedicated skeletal state")
	actor.revive()
	await create_timer(0.20).timeout
	check(not actor.dead and actor.current_state == &"Idle", "P1: revival resets presentation state")
	actor.scale = Vector3.ONE * 0.85
	actor.animate_motion(Vector3(1.4, 0, 0), 1.0 / 60)
	check(actor.current_state == &"Walk" and is_equal_approx(actor.gait_speed, 1.4 / (0.675 * 0.85)), "Common raider uses a ground-calibrated brisk walk instead of a slow running pose")
	actor.animate_motion(Vector3(2.3, 0, 0), 1.0 / 60)
	check(actor.current_state == &"Run", "Fast raider still selects its separate running gait")
	var tower: ArcherDisplay3D = lab.towers[0]
	check(tower.operator_player.has_animation("draw") and tower.operator_player.has_animation("release"), "P1: tower operator has bow draw and release clips")
	check(tower.bow.get_parent() is BoneAttachment3D, "P1: bow attaches to an actual hand bone")
	var release_count: Array[int] = [0]
	tower.arrow_released.connect(func(_origin: Vector3, _direction: Vector3) -> void: release_count[0] += 1)
	tower.shoot()
	tower.shoot()
	await create_timer(0.65).timeout
	check(release_count[0] == 1, "P1: repeated shoot request releases one arrow")
	check(lab.diorama.camera.size > 0.0, "P1: camera framing is valid")
	lab.free()
	await process_frame
	print("P0/P1: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
