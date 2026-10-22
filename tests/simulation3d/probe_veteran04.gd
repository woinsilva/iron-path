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
	var total: int = 0
	for index in range(1, 5): total += StageSessionV2.read_stage("res://data/campaign/stage_%02d.json" % index).waves.size()
	check(total == 52, "The first biome contains fifty-two authored waves")
	for variant in range(2):
		var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_04.json")
		stage.allowed_towers = ["archer", "cannon", "anti_air", "bleed", "frost" if variant == 0 else "venom"]
		var plan: Array[String] = ["archer", "cannon", "anti_air", "bleed", "frost" if variant == 0 else "venom", "cannon", "archer", "frost" if variant == 0 else "venom", "bleed"]
		if variant == 1:
			plan[0] = "cannon"
			plan[1] = "archer"
		var sim: BattleSimV2 = StageSessionV2.create(stage, "veteran")
		for pad in [0, 1, 3, 7]: sim.build(pad, plan[pad])
		for prep in range(420): sim.step()
		sim.start_first_wave()
		var captain: SimEnemyV2 = null
		for index in range(100000):
			if sim._terminal(): break
			if index % 30 == 0:
				if sim.wave_index >= 4 and sim.tower_on_pad(2) == null: sim.build(2, plan[2])
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
		check(sim.state == BattleSimV2.State.VICTORY and sim.wave_index == 16, "Formation %d completes all automatic waves in the gate stage" % variant)
		check(captain != null and captain.health <= 0, "Formation %d defeats the captain instead of relying on a boss leak" % variant)
		check(sim.coins >= 0 and sim.kills + sim.leaks == sim.spawned, "Formation %d resolves economy and entities once" % variant)
		print("BIOME4_VARIANT ", variant, " ", sim.summary(), " CAPTAIN_REMAINING ", captain.health if captain != null else -1)
	print("P6 biome: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
