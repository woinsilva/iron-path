extends SceneTree
func _initialize() -> void:
	for variant in range(2):
		var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_07.json")
		var plan: Array[String] = ["cannon", "cannon", "arcane", "arcane", "frost", "cannon", "frost", "arcane", "cannon", "arcane", "cannon", "frost", "banner", "anti_air"]
		if variant == 1:
			for pad in range(plan.size()):
				if plan[pad] == "frost": plan[pad] = "venom"
		stage.allowed_towers = ["cannon", "arcane", "frost" if variant == 0 else "venom", "banner", "anti_air"]
		var sim: BattleSimV2 = StageSessionV2.create(stage)
		for pad in [1, 7, 6, 12, 13]: sim.build(pad, plan[pad])
		for tick in range(420): sim.step()
		for prep_level in range(2):
			sim.upgrade(7)
			for tick in range(720): sim.step()
		sim.upgrade(1)
		for tick in range(720): sim.step()
		sim.start_first_wave()
		for tick in range(120000):
			if sim._terminal(): break
			if tick % 30 == 0:
				var core_ready: bool = true
				for target_level in [2, 3]:
					for priority_pad in [7, 1, 13, 6]:
						var tower: SimTowerV2 = sim.tower_on_pad(priority_pad)
						if tower.level < target_level:
							core_ready = false
							sim.upgrade(priority_pad)
							break
					if not core_ready: break
				if core_ready and sim.tower_on_pad(13).level < 4:
					if sim.state == BattleSimV2.State.INTERMISSION: sim.upgrade(13, "A" if variant == 0 else "B")
					core_ready = false
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
		for tower: SimTowerV2 in sim.towers.values(): print("TOWER ", tower.pad, " ", tower.type_id, " ", tower.level, " DAMAGE ", tower.damage_done, " SUPPORTED ", tower.supported_attacks)
		print("FORTRESS_VARIANT ", variant, " ", sim.summary())
	quit()
