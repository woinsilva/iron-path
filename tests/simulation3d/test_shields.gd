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
	var sim: BattleSimV2 = StageSessionV2.create(StageSessionV2.read_stage("res://data/campaign/stage_06.json"))
	var guard: SimEnemyV2 = sim.spawn_enemy("shieldbearer")
	var useful: float = sim.damage(guard.id, 50, "pure")
	check(guard.health == 190 and guard.shield == 30 and useful == 50, "Shield absorbs damage before health and reports useful absorbed damage")
	sim.damage(guard.id, 50, "pure")
	check(guard.shield == 0 and guard.health == 170, "Damage exceeding remaining shield reaches health exactly once")
	sim.ticks = 299
	sim._update_enemy_support()
	check(guard.shield == 0, "Broken shield cannot recharge before its full delay")
	sim.damage(guard.id, 1, "pure")
	sim.ticks = 300
	sim._update_enemy_support()
	check(guard.shield == 0, "New damage postpones the recharge window")
	sim.ticks = 599
	sim._update_enemy_support()
	check(guard.shield == 80 and guard.shield_recharges_left == 0, "One recharge restores the declared shield after five seconds without damage")
	sim.damage(guard.id, 80, "pure")
	sim.ticks = 2000
	sim._update_enemy_support()
	check(guard.shield == 0, "Exhausted recharge budget prevents indefinite shields")
	sim.damage(guard.id, 10000, "pure")
	var earned: int = sim.earned
	sim.damage(guard.id, 10000, "pure")
	check(earned == 17 and sim.earned == earned and sim.kills == 1, "Shielded enemy pays one reward and never duplicates a kill")
	var controlled: SimEnemyV2 = sim.spawn_enemy("shieldbearer")
	sim.damage(controlled.id, 80, "pure")
	sim.apply_status(controlled.id, "venom", 1, 8, 77)
	for frame in range(420): sim.step()
	check(controlled.shield == 0 and controlled.shield_recharges_left == 1, "Continuous DoT keeps a broken shield from recharging")
	var before: int = sim.ticks
	sim.paused = true
	for frame in range(360): sim.advance(1.0 / 60)
	check(sim.ticks == before and controlled.shield == 0, "Pause freezes shield timers and DoT")
	print("P7 shields: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
