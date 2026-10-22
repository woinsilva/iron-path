extends SceneTree
func _initialize() -> void:
	for variant in range(2):
		var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_04.json")
		stage.allowed_towers = ["archer", "cannon", "anti_air", "bleed", "frost" if variant == 0 else "venom"]
		var plan: Array[String] = ["archer", "cannon", "anti_air", "bleed", "frost" if variant == 0 else "venom", "cannon", "archer", "frost" if variant == 0 else "venom", "bleed"]
		if variant == 1:
			plan[0] = "cannon"
			plan[1] = "archer"
		var sim: BattleSimV2 = StageSessionV2.create(stage)
		for pad in range(4): sim.build(pad, plan[pad])
		for prep in range(420): sim.step()
		sim.start_first_wave()
		var captain: SimEnemyV2 = null
		for index in range(100000):
			if sim._terminal(): break
			if index % 30 == 0:
				for pad in range(4, 9):
					if sim.tower_on_pad(pad) == null and not sim.build(pad, plan[pad]): break
				for pad in range(9):
					sim.upgrade(pad)
					var tower: SimTowerV2 = sim.tower_on_pad(pad)
					if tower != null and tower.type_id == "bleed": tower.priority = "strongest"
			sim.step()
			for enemy: SimEnemyV2 in sim.enemies.values():
				if enemy.boss: captain = enemy
			sim.consume_events()
		print("BIOME4_VARIANT ", variant, " ", sim.summary(), " CAPTAIN_REMAINING ", captain.health if captain != null else -1)
	quit()
