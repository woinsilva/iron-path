extends SceneTree
func _initialize() -> void:
	for index in [10, 11, 12]:
		var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_%02d.json" % index)
		var sim: BattleSimV2 = StageSessionV2.create(stage)
		print("TUNNEL ",index," length ", sim.routes[2].get_baked_length(), " marker ", stage.burrow_routes, " int membership ", 2 in stage.burrow_routes)
	quit()
