extends SceneTree

func _initialize() -> void:
	var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_01.json")
	for strategy in range(4):
		var sim: BattleSimV2 = StageSessionV2.create(stage)
		if strategy in [0, 3]:
			sim.build(0, "archer")
			sim.build(1, "archer")
		elif strategy == 1:
			sim.build(0, "archer")
			sim.build(1, "cannon")
		sim.start_first_wave()
		for index in range(60 * 1200):
			if sim._terminal():
				break
			if strategy != 2 and index % 30 == 0:
				if strategy == 3:
					for pad in range(9):
						sim.upgrade(pad)
				# Fixed legal strategy: expand the firing line, then improve existing towers.
				for pad in [2, 3, 4, 5, 6, 7, 8]:
					if sim.tower_on_pad(pad) == null:
						sim.build(pad, "archer" if pad % 3 != 2 else "cannon")
				for pad in [0, 1, 2, 3, 4, 5, 6, 7, 8]:
					sim.upgrade(pad)
			sim.step()
			sim.consume_events()
		print("STRATEGY ", strategy, " ", sim.summary())
	quit()
