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
	var sim: BattleSimV2 = StageSessionV2.create(StageSessionV2.read_stage("res://data/campaign/stage_09.json"))
	var sentinel: SimEnemyV2 = sim.spawn_enemy("resistant")
	check(is_equal_approx(sim.damage(sentinel.id, 100, "magical"), 43), "Runic resistance reduces magic by 55 percent before half armor")
	check(is_equal_approx(sim.damage(sentinel.id, 100, "physical"), 96), "Physical damage provides a distinct counter to runic resistance")
	check(is_equal_approx(sim.damage(sentinel.id, 20, "pure"), 20), "Pure damage bypasses both runic resistance and armor")
	var poisoned: SimEnemyV2 = sim.spawn_enemy("resistant")
	sim.apply_status(poisoned.id, "venom", 20, 2, 1)
	sim.apply_status(poisoned.id, "bleed", 20, 2, 2)
	sim.ticks = 30
	sim._update_statuses()
	check(is_equal_approx(poisoned.maximum_health - poisoned.health, 15), "Venom respects resistance while moving bleed preserves its pure damage")
	sim.damage(sentinel.id, 1000, "pure")
	var earned: int = sim.earned
	sim.damage(sentinel.id, 1000, "pure")
	check(sim.earned == earned and earned == 18, "Runic sentinel pays its reward exactly once")
	print("P8 resistance: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
