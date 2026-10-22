extends SceneTree
func _initialize() -> void:
	var sim: BattleSimV2 = StageSessionV2.create(StageSessionV2.read_stage("res://data/campaign/stage_04.json"))
	for x in range(-14, -9):
		for z in range(1, 5):
			var p: Vector3 = Vector3(x, 0, z)
			var clearance: float = p.distance_to(sim.routes[0].get_closest_point(p))
			if clearance >= 2.2 and p.distance_to(sim.pads[7]) >= 2.5:
				print(p, " ", clearance)
	quit()
