extends SceneTree

func _initialize() -> void:
	call_deferred("inspect")

func inspect() -> void:
	var model: Node = load("res://art/models/goblin.glb").instantiate()
	root.add_child(model)
	show(model, 0)
	var player: AnimationPlayer = find_player(model)
	if player:
		print("CLIPS ", player.get_animation_list())
		for clip in player.get_animation_list():
			print(clip, " length=", player.get_animation(clip).length, " tracks=", player.get_animation(clip).get_track_count())
	model.free()
	quit()

func find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = find_player(child)
		if found:
			return found
	return null

func show(node: Node, depth: int) -> void:
	print(" ".repeat(depth), node.name, " ", node.get_class())
	if node is Skeleton3D:
		print("BONES ", node.get_bone_count(), " ", node.get_bone_name(8))
	for child in node.get_children():
		show(child, depth + 1)
