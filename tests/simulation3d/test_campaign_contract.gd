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
	var catalog: Dictionary = BattleSimV2.load_catalog()
	var total: int = 0
	var routes_valid: bool = true
	var counters: bool = true
	var utf8: bool = true
	var level_limits: bool = true
	var emergence: bool = true
	var last_boss: bool = false
	for index in range(1, 13):
		var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_%02d.json" % index)
		var sim: BattleSimV2 = StageSessionV2.create(stage)
		total += stage.waves.size()
		level_limits = level_limits and int(stage.max_level) == (3 if index <= 2 else (4 if index <= 4 else (5 if index <= 8 else 6)))
		utf8 = utf8 and not str(stage.name).contains("�") and not str(stage.name).contains("Ã")
		for wave: Dictionary in stage.waves:
			for group: Dictionary in wave.groups:
				var enemy: Dictionary = catalog.enemies[str(group.enemy)]
				routes_valid = routes_valid and int(group.route) >= 0 and int(group.route) < sim.routes.size() and int(group.count) > 0
				var covered: bool = false
				for tower: String in stage.allowed_towers:
					if str(catalog.towers[tower].layer) in ["both", str(enemy.layer)]: covered = true
				counters = counters and covered
				if str(group.enemy) == "burrower": emergence = emergence and int(group.route) in PackedInt32Array(stage.get("burrow_routes", [])) and sim.routes[int(group.route)].get_baked_length() > float(enemy.burrow_distance) + 10
				if str(group.enemy) == "boss_ruin": last_boss = index == 12 and wave == stage.waves[-1] and int(group.count) == 1
	check(total == 212, "Twelve stages contain exactly 212 explicit campaign waves")
	check(routes_valid, "Every authored group uses an existing route and a positive count")
	check(counters, "Every stage offers an unlocked tower able to hit each enemy layer")
	check(level_limits, "Campaign introduces level five only after reaching the swamp")
	check(emergence, "Every burrower group has an announced emergence route and a real exposed defense window")
	check(last_boss, "Final guardian appears once in the final campaign wave")
	check(utf8 and str(catalog.enemies.resistant.name) == "Sentinela Rúnica" and str(catalog.enemies.boss_ruin.name) == "Guardião da Ruína", "Portuguese stage and final enemy names preserve UTF-8 characters")
	var common: int = 0
	var bosses: int = 0
	for enemy: Dictionary in catalog.enemies.values():
		if bool(enemy.get("lab_only", false)): continue
		if bool(enemy.get("boss", false)): bosses += 1
		else: common += 1
	check(common == 16 and bosses == 3, "Campaign has sixteen common or elite entries and three bosses without counting laboratory targets")
	print("P8 campaign contract: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
