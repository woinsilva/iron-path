extends SceneTree
func _initialize() -> void:
	for variant in range(2):
		var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_05.json")
		var plan: Array[String] = ["archer", "cannon", "anti_air", "archer", "archer", "cannon", "frost", "arcane", "archer", "anti_air", "cannon", "frost"]
		if variant == 1:
			for pad in range(plan.size()):
				if plan[pad] == "archer": plan[pad] = "bleed"
		stage.allowed_towers = ["bleed" if variant == 1 else "archer", "cannon", "arcane", "anti_air", "frost"]
		var sim: BattleSimV2 = StageSessionV2.create(stage)
		for pad in [1, 7, 6, 2]: sim.build(pad, plan[pad])
		for tick in range(420): sim.step()
		sim.start_first_wave()
		for tick in range(120000):
			if sim._terminal(): break
			if tick % 30 == 0:
				var core_ready: bool = true
				for target_level in [2, 3]:
					for priority_pad in [7, 1, 2, 6]:
						var tower: SimTowerV2 = sim.tower_on_pad(priority_pad)
						if tower.level < target_level:
							core_ready = false
							sim.upgrade(priority_pad)
							break
					if not core_ready: break
				if core_ready and sim.tower_on_pad(7).level < 4:
					if sim.state == BattleSimV2.State.INTERMISSION: sim.upgrade(7, "A" if variant == 0 else "B")
					core_ready = false
				if core_ready:
					for pad in range(plan.size()):
						if sim.tower_on_pad(pad) == null and not sim.build(pad, plan[pad]): break
					for pad in range(plan.size()):
						var tower: SimTowerV2 = sim.tower_on_pad(pad)
						if tower != null: sim.upgrade(pad, ("A" if variant == 0 else "B") if tower.level >= 3 else "")
			sim.step()
			sim.consume_events()
		for tower: SimTowerV2 in sim.towers.values(): print("TOWER ", tower.pad, " ", tower.type_id, " ", tower.level, " DAMAGE ", tower.damage_done)
		print("CANYON_VARIANT ", variant, " ", sim.summary())
	quit()
