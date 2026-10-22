extends SceneTree
func _initialize() -> void:
	var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_05.json")
	var sim: BattleSimV2 = StageSessionV2.create(stage)
	for pad in range(sim.pads.size()):
		var coverage: float = 0
		for route_id in [0, 2]:
			var curve: Curve3D = sim.routes[route_id]
			var nearest: float = curve.get_closest_point(sim.pads[pad]).distance_to(sim.pads[pad])
			for sample in range(int(curve.get_baked_length() * 5)):
				if BattleSimV2.distance_xz(curve.sample_baked(sample * .2), sim.pads[pad]) < 3.8: coverage += .2
			print("PAD ", pad, " ROUTE ", route_id, " CLEAR ", nearest)
		print("COVERAGE ", pad, " ", coverage)
	quit()
