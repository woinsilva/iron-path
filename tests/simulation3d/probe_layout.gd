extends SceneTree
func _initialize() -> void:
	for index in range(1, 5):
		var sim: BattleSimV2 = StageSessionV2.create(StageSessionV2.read_stage("res://data/campaign/stage_%02d.json" % index))
		for pad in range(sim.pads.size()):
			print("PAD ", index, ":", pad, " distance ", sim.pads[pad].distance_to(sim.routes[0].get_closest_point(sim.pads[pad])))
	quit()

