extends SceneTree
func _initialize() -> void:
	for stage_index in [2]:
		for variant in range(1):
			var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_%02d.json" % stage_index)
			var sim: BattleSimV2 = StageSessionV2.create(stage)
			var plan: Array[String] = ["archer", "cannon", "frost", "archer", "cannon", "frost", "archer", "cannon", "archer"]
			if stage_index == 3: plan = ["archer", "cannon", "anti_air", "frost", "venom", "cannon", "archer", "frost", "anti_air"]
			if variant == 1:
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
						if sim.tower_on_pad(pad) == null: sim.build(pad, plan[pad])
					for pad in range(9): sim.upgrade(pad)
				sim.step()
				for event: Dictionary in sim.consume_events():
					if str(event.kind) == "wave_completed": print("WAVE ", sim.summary())
			print("STAGE ", stage_index, " VARIANT ", variant, " ", sim.summary())
	quit()
