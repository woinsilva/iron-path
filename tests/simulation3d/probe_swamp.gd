extends SceneTree
func _initialize() -> void:
	for variant in range(2):
		var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_09.json")
		var plan: Array[String] = ["cannon", "cannon", "cannon", "arcane", "frost", "cannon", "frost", "banner", "cannon", "anti_air", "cannon", "bleed", "bleed", "anti_air"]
		if variant == 1:
			for i in range(plan.size()):
				if plan[i] == "frost": plan[i] = "venom"
		# Five-family reference: physical / pure damage, control, support and aerial coverage.
		for i in range(plan.size()):
			if plan[i] == "arcane": plan[i] = "bleed"
		stage.allowed_towers = ["cannon", "bleed", "frost" if variant == 0 else "venom", "banner", "anti_air"]
		var sim: BattleSimV2 = StageSessionV2.create(stage)
		for pad in [2, 6, 7, 12, 13]: sim.build(pad, plan[pad])
		for tick in range(420): sim.step()
		for target_level in [2, 3]:
			sim.upgrade(2)
			for tick in range(720): sim.step()
		sim.upgrade(12)
		for tick in range(720): sim.step()
		sim.start_first_wave()
		for tick in range(130000):
			if sim._terminal(): break
			if tick % 30 == 0:
				var pending: bool = false
				for level in [2, 3, 4]:
					for pad in ([13, 2, 12, 6] if variant == 1 else [2, 13, 12, 6, 7]):
						var tower: SimTowerV2 = sim.tower_on_pad(pad)
						if tower.level < level:
							pending = true
							sim.upgrade(pad, ("A" if variant == 1 and pad == 13 else "B") if tower.level >= 3 else "")
							break
					if pending: break
				if not pending:
					for pad in [2, 13, 12]:
						var focus: SimTowerV2 = sim.tower_on_pad(pad)
						if focus.level < 5:
							pending = true
							sim.upgrade(pad)
							break
				if not pending:
					for pad in range(plan.size()):
						if sim.tower_on_pad(pad) == null and not sim.build(pad, plan[pad]): break
					for pad in range(plan.size()):
						var tower: SimTowerV2 = sim.tower_on_pad(pad)
						if tower != null: sim.upgrade(pad, "A" if tower.level >= 3 else "")
			sim.step()
			sim.consume_events()
		print("SWAMP ",variant," ",sim.summary())
	quit()
