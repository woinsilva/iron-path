extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var lab: Node3D = load("res://scenes/lab3d/quality_lab.tscn").instantiate() as Node3D
	root.add_child(lab)
	current_scene = lab
	# Recorded camera review: forward travel, curve, slow, run, hit and death.
	for frame in range(750):
		if frame == 180:
			lab.set("_speed", 0.5)
		if frame == 270:
			lab.set("_speed", 1.0)
			lab.set("_running", true)
		if frame == 420:
			lab.set("_running", false)
			lab.actors[1].react_to_hit()
		if frame == 540:
			lab.call("_test_death")
		if frame == 630:
			for index in range(lab.tracks.size()):
				lab.tracks[index].direction = -1.0
		await process_frame
	quit()
