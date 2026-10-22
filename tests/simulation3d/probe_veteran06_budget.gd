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
	for variant in range(1):
		var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_06.json")
		var plan: Array[String] = ["cannon", "cannon", "arcane", "arcane", "frost", "cannon", "frost", "arcane", "cannon", "arcane", "cannon", "frost", "banner", "anti_air"]
		if variant == 1:
			for pad in range(plan.size()):
				if plan[pad] == "frost": plan[pad] = "venom"
		stage.allowed_towers = ["cannon", "arcane", "frost" if variant == 0 else "venom", "banner", "anti_air"]
		stage.starting_coins = int(round(float(stage.starting_coins) * 1.25))
		var sim: BattleSimV2 = StageSessionV2.create(stage, "veteran")
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
				var pending: bool = false
				for request: Array in [[1,2],[13,2],[7,4],[1,3],[13,4],[6,3]]:
					var tower: SimTowerV2 = sim.tower_on_pad(int(request[0]))
					if tower.level < int(request[1]):
						pending = true
						sim.upgrade(tower.pad, "A" if tower.level >= 3 else "")
						break
				if not pending:
					for pad in range(plan.size()):
						if sim.tower_on_pad(pad) == null and not sim.build(pad, plan[pad]): break
					for pad in range(plan.size()):
						var tower: SimTowerV2 = sim.tower_on_pad(pad)
						if tower != null: sim.upgrade(pad, "A" if tower.level >= 3 else "")
			sim.step()
			sim.consume_events()
		check(sim.state == BattleSimV2.State.VICTORY and sim.wave_index == 18, "Fortress formation %d completes its eighteen automatic waves" % variant)
		check(sim.coins >= 0 and sim.kills + sim.leaks == sim.spawned and sim.spawned == 292, "Fortress formation %d resolves all shield units and economy" % variant)
		check(sim.tower_on_pad(7).level == 4 and sim.tower_on_pad(13).level == 4, "Fortress formation %d completes its real specialization choices" % variant)
		print("FORTRESS_VARIANT ", variant, " ", sim.summary())
	print("P7 stage07: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
