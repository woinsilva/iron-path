extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func fixture() -> BattleSimV2:
	var route: Curve3D = Curve3D.new()
	route.add_point(Vector3.ZERO)
	route.add_point(Vector3(100, 0, 0))
	return BattleSimV2.new(BattleSimV2.load_catalog(), [route], PackedVector3Array(), [], 200, 20)
func tick(sim: BattleSimV2, count: int) -> void:
	for index in range(count): sim.step()
func _initialize() -> void:
	var sim: BattleSimV2 = fixture()
	var target: SimEnemyV2 = sim.spawn_enemy("grunt")
	check(sim.apply_status(target.id, "slow", 0.2, 1.5, 1), "Slow can be applied to a living target")
	sim.apply_status(target.id, "slow", 0.3, 1.0, 2)
	check(is_equal_approx(sim.movement_factor(target), 0.7), "Slow uses strongest source instead of additive stacking")
	sim.apply_status(target.id, "slow", 0.95, 0.5, 3)
	check(is_equal_approx(sim.movement_factor(target), 0.35), "Slow respects the movement floor")
	tick(sim, 30)
	check(is_equal_approx(sim.movement_factor(target), 0.7), "Expired strong slow yields to remaining weaker source")
	target.boss = true
	sim.apply_status(target.id, "slow", 0.9, 1.0, 4)
	check(is_equal_approx(sim.movement_factor(target), 0.6), "Boss slow is capped at forty percent")
	sim = fixture()
	target = sim.spawn_enemy("grunt")
	sim.apply_status(target.id, "venom", 4.0, 3.0, 1)
	tick(sim, 29)
	check(target.health == 70, "Poison waits for the first half-second tick")
	sim.apply_status(target.id, "venom", 4.0, 3.0, 1)
	tick(sim, 1)
	check(target.health == 68 and target.statuses.size() == 1, "Same source refresh preserves tick cadence without stacking")
	sim.paused = true
	tick(sim, 60)
	check(target.health == 68 and sim.ticks == 30, "Pause freezes DoT and expiration")
	sim.paused = false
	tick(sim, 179)
	check(target.health == 58 and target.statuses.is_empty(), "Poison applies six deterministic ticks and expires")
	sim.apply_status(target.id, "venom", 4, 3, 1)
	sim.apply_status(target.id, "venom", 4, 3, 2)
	sim.apply_status(target.id, "venom", 4, 3, 3)
	check(not sim.apply_status(target.id, "venom", 4, 3, 4), "Poison caps at three independent sources")
	sim = fixture()
	target = sim.spawn_enemy("grunt")
	target.boss = true
	sim.apply_status(target.id, "venom", 4, 3, 1)
	tick(sim, 90)
	check(target.health == 64 and target.statuses.is_empty(), "Boss poison duration is halved with no hidden immunity")
	sim = fixture()
	target = sim.spawn_enemy("grunt")
	sim.apply_status(target.id, "venom", 1000, 3, 1)
	tick(sim, 180)
	check(sim.kills == 1 and sim.earned == 6, "Lethal poison rewards exactly once")
	check(not sim.apply_status(target.id, "slow", 0.2, 1, 1), "Resolved targets reject status application")
	var a: BattleSimV2 = fixture()
	var b: BattleSimV2 = fixture()
	var ea: SimEnemyV2 = a.spawn_enemy("grunt")
	var eb: SimEnemyV2 = b.spawn_enemy("grunt")
	a.apply_status(ea.id, "venom", 4, 3, 1)
	b.apply_status(eb.id, "venom", 4, 3, 1)
	a.apply_status(ea.id, "slow", 0.2, 2, 1)
	b.apply_status(eb.id, "slow", 0.2, 2, 1)
	for index in range(180): a.advance(1.0 / 60)
	for index in range(90): b.advance(2.0 / 60)
	check(is_equal_approx(ea.distance, eb.distance) and ea.health == eb.health, "DoT and control are equivalent at one and two times speed")
	print("P4 status: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
