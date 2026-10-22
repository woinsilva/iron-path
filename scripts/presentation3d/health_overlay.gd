extends Node2D
## Screen-space bars follow world-space head anchors; no gameplay ownership.

var camera: Camera3D
var actors: Array[RiggedActor3D] = []

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(camera):
		return
	var viewport_height: float = get_viewport_rect().size.y
	for actor in actors:
		if not is_instance_valid(actor) or actor.dead:
			continue
		var point: Vector3 = actor.health_anchor.global_position
		if camera.is_position_behind(point):
			continue
		var screen: Vector2 = camera.unproject_position(point)
		if screen.y < 104.0 or screen.y > viewport_height - 130.0:
			continue
		draw_rect(Rect2(screen - Vector2(34, 7), Vector2(68, 12)), Color("162821"))
		draw_rect(Rect2(screen - Vector2(32, 5), Vector2(64.0 * clampf(actor.health_ratio, 0.0, 1.0), 8)), Color("8bbb53"))
