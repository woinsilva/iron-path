extends SceneTree
func _initialize() -> void:
	for stage_index in [2, 3]:
		for variant in range(2):
			var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_%02d.json" % stage_index)
			var sim: BattleSimV2 = StageSessionV2.create(stage)
			var plan: Array[String] = ["archer", "cannon", "frost", "archer", "cannon", "frost", "archer", "cannon", "archer"]
			if stage_index == 3: plan = ["archer", "cannon", "anti_air", "frost", "venom", "cannon", "archer", "frost", "anti_air"]
			if variant == 1:
				if stage_index == 2:
					plan[0] = "cannon"
					plan[1] = "archer"
				else:
					plan[1] = "archer"
					plan[3] = "cannon"
			for pad in range(2): sim.build(pad, plan[pad])
			sim.build(2, plan[2])
			for prep_tick in range(360): sim.step()
			sim.start_first_wave()
			for index in range(90000):
				if sim._terminal(): break
				if index % 30 == 0:
					for pad in range(2, 9):
						if sim.tower_on_pad(pad) == null:
							if not sim.build(pad, plan[pad]): break
					for pad in range(9): sim.upgrade(pad)
				sim.step()
				sim.consume_events()
			print("STAGE ", stage_index, " VARIANT ", variant, " ", sim.summary())
	quit()
