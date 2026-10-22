extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var actor: RiggedActor3D = RiggedActor3D.new()
	actor.model_path = "res://art/models/guardian.glb"
	root.add_child(actor)
	for index in range(actor.skeleton.get_bone_count()):
		print(actor.skeleton.get_bone_name(index), " ", actor.skeleton.get_bone_global_rest(index).origin)
	actor.queue_free()
	await process_frame
	quit()
