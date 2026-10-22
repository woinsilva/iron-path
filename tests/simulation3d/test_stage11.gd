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
	for variant in range(2):
		var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_11.json")
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
					for pad in [13, 2, 12, 6]:
						var tower: SimTowerV2 = sim.tower_on_pad(pad)
						if tower.level < level:
							pending = true
							sim.upgrade(pad, ("A" if pad == 13 else "B") if tower.level >= 3 else "")
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
		check(sim.state == BattleSimV2.State.VICTORY and sim.wave_index == 22, "Nest formation %d completes all twenty two automatic waves" % variant)
		check(sim.kills + sim.leaks == sim.spawned and sim.spawned >= 379 and sim.spawned <= 439 and sim.coins >= 0, "Nest formation %d resolves all authored enemies with legal economy" % variant)
		check(sim.tower_on_pad(2).level == 5 and sim.tower_on_pad(13).level == 5, "Nest formation %d earns its real level five upgrades" % variant)
		var families: Dictionary = {}
		for tower: SimTowerV2 in sim.towers.values(): families[tower.type_id] = true
		check(families.size() == 5, "Nest formation %d uses all five selected families" % variant)
		print("SWAMP ",variant," ",sim.summary())
	print("P8 stage11: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
