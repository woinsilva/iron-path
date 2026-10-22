extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var actor: RiggedActor3D = RiggedActor3D.new()
	actor.model_path = "res://art/models/guardian.glb"
	actor.set_meta("type_id", "resistant")
	root.add_child(actor)
	await process_frame
	var crown: Node3D = actor.model.find_child("RunicCrown", true, false) as Node3D
	print("CROWN ", crown.global_position, " ANCHOR ", actor.health_anchor.global_position)
	for node: Node in actor.model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if "Head" in str(mesh.name) or mesh.get_parent().get_parent() == crown:
			print("HEAD MESH ", mesh.name, " bounds ", mesh.global_transform * mesh.get_aabb())
	actor.queue_free()
	await process_frame
	quit()
