extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var actor: RiggedActor3D = RiggedActor3D.new()
	root.add_child(actor)
	actor.animation_tree.active = false
	var clip: String = "run" if "--run" in OS.get_cmdline_user_args() else "walk"
	actor.player.play(clip)
	var samples: Array[Dictionary] = []
	for index in range(65):
		var time: float = actor.player.get_animation(clip).length * index / 64.0
		actor.player.seek(time, true)
		actor.skeleton.force_update_all_bone_transforms()
		var left: Vector3 = actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("foot.l")).origin
		var right: Vector3 = actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("foot.r")).origin
		samples.append({"time": time, "left": [left.x, left.y, left.z], "right": [right.x, right.y, right.z]})
	var file: FileAccess = FileAccess.open("res://test-results/gait-%s.json" % clip, FileAccess.WRITE)
	file.store_string(JSON.stringify(samples))
	file.close()
	actor.free()
	quit()
