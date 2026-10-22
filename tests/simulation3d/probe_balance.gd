extends SceneTree
func _initialize() -> void:
	var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_01.json")
	for health in [70, 60, 55, 50]:
		var sim: BattleSimV2 = StageSessionV2.create(stage)
		sim.catalog.enemies.grunt.hp = health
		sim.build(0, "archer")
		sim.build(1, "cannon")
		sim.start_first_wave()
		for index in range(72000):
			if sim._terminal(): break
			if index % 30 == 0:
				for pad in range(2, 9):
					if sim.tower_on_pad(pad) == null:
						sim.build(pad, "archer" if pad % 3 != 2 else "cannon")
				for pad in range(9): sim.upgrade(pad)
			sim.step()
			sim.consume_events()
		print("GRUNT_HP ", health, " ", sim.summary())
	quit()
