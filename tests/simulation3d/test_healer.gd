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
	var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_05.json")
	var sim: BattleSimV2 = StageSessionV2.create(stage)
	check(sim.routes.size() == 3 and sim.catalog.towers.has("arcane") and sim.catalog.towers.arcane.branches.A.levels.size() == 1, "Twin bridges expose two ground routes, air and Arcane level four")
	var healer: SimEnemyV2 = sim.spawn_enemy("healer")
	var allies: Array[SimEnemyV2] = []
	for index in range(4):
		var ally: SimEnemyV2 = sim.spawn_enemy("grunt")
		ally.health = 20
		allies.append(ally)
	healer.health = 30
	var corpse: SimEnemyV2 = sim.spawn_enemy("grunt")
	sim.damage(corpse.id, 10000, "pure")
	var earned: int = sim.earned
	sim.ticks = 240
	sim._update_enemy_support()
	check(healer.health == 30 and not sim.enemies.has(corpse.id), "Healer cannot heal itself or resurrect a defeated unit")
	check(allies[0].health == 30 and allies[2].health == 30 and allies[3].health == 20, "Healing caps three targets with stable tie order")
	check(healer.support_casts == 1 and sim.earned == earned, "Healing consumes one charge without granting currency")
	sim._update_enemy_support()
	check(healer.support_casts == 1 and allies[0].health == 30, "Repeated tick cannot duplicate a healing pulse")
	for pulse in range(10):
		sim.ticks += 240
		sim._update_enemy_support()
	check(healer.support_casts == 6 and allies[0].health <= allies[0].maximum_health, "Finite cast budget and maximum health prevent indefinite healing")
	var distant: SimEnemyV2 = sim.spawn_enemy("healer", 2)
	var ally: SimEnemyV2 = sim.spawn_enemy("grunt")
	ally.health = 1
	distant.position = Vector3(100, 0, 100)
	sim.ticks += 240
	sim._update_enemy_support()
	check(ally.health == 1 and distant.support_casts == 0, "Healing requires range and idle healers preserve their budget")
	sim.paused = true
	var before: int = sim.ticks
	for frame in range(60): sim.advance(1.0 / 60)
	check(sim.ticks == before and distant.support_casts == 0, "Pause freezes support timing")
	print("P7 healing: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
