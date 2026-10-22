extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
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
			check(sim.state == BattleSimV2.State.VICTORY, "Stage %d strategy %d wins with legal resources" % [stage_index, variant])
			check(sim.coins >= 0 and sim.kills + sim.leaks == sim.spawned, "Stage %d strategy %d resolves economy and entities" % [stage_index, variant])
			check(sim.wave_index == stage.waves.size(), "Stage %d strategy %d completes automatic sequence" % [stage_index, variant])
			print("STAGE ", stage_index, " VARIANT ", variant, " ", sim.summary())
	print("P4 alpha campaign: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
