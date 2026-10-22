extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error(description)

func fixture(count: int = 2, starting_lives: int = 20) -> BattleSimV2:
	var route: Curve3D = Curve3D.new()
	route.add_point(Vector3.ZERO)
	route.add_point(Vector3(20, 0, 0))
	var definitions: Dictionary = BattleSimV2.load_catalog().duplicate(true)
	var wave_list: Array = []
	for index in range(count):
		wave_list.append({"interval": 0.5, "groups": [{"enemy": "grunt", "count": 1, "interval": 0.1}]})
	return BattleSimV2.new(definitions, [route], PackedVector3Array([Vector3(2, 0, 1), Vector3(6, 0, 1)]), wave_list, 200, starting_lives)

func tick(sim: BattleSimV2, count: int) -> void:
	for index in range(count):
		sim.step()

func run() -> void:
	var sim: BattleSimV2 = fixture()
	tick(sim, 200)
	check(sim.spawned == 0 and sim.state == BattleSimV2.State.PREPARATION, "First wave waits for explicit start")
	check(sim.start_first_wave() and not sim.start_first_wave(), "First wave start is atomic")
	sim.step()
	check(sim.enemies.size() == 1 and sim.wave_index == 1, "First enemy spawns from wave data")
	var enemy: SimEnemyV2 = sim.enemies.values()[0]
	sim.damage(enemy.id, 1000)
	var earned: int = sim.coins
	sim.damage(enemy.id, 1000)
	check(sim.coins == earned and sim.kills == 1, "Death grants reward exactly once")
	sim.step()
	check(sim.state == BattleSimV2.State.INTERMISSION, "Intermission waits until all enemies resolved")
	var interval: int = sim.interval_until
	sim.paused = true
	tick(sim, 100)
	check(sim.interval_until == interval and not sim.call_wave_early(), "Pause freezes automatic countdown and rejects anticipation")
	sim.paused = false
	tick(sim, 30)
	check(sim.wave_index == 2 and sim.state == BattleSimV2.State.WAVE_ACTIVE, "Second wave begins automatically without button")
	enemy = sim.enemies.values()[0]
	sim.damage(enemy.id, 1000)
	sim.step()
	check(sim.state == BattleSimV2.State.VICTORY, "Last resolved wave wins")
	var terminal: Dictionary = sim.summary()
	tick(sim, 1000)
	check(sim.summary() == terminal and not sim.call_wave_early(), "No timers or new waves after victory")
	check(not sim.build(0, "archer"), "Terminal state rejects purchases")

	sim = fixture(2, 1)
	sim.start_first_wave()
	tick(sim, 1000)
	check(sim.state == BattleSimV2.State.DEFEAT and sim.lives == 0, "Leak causes defeat before next wave")
	check(sim.coins == 200 and sim.earned == 0 and sim.kills == 0, "Leaked enemy grants no coins")
	check(sim.spawned == 1, "Defeat cancels pending sequence")

	sim = fixture()
	check(not sim.build(-1, "archer") and not sim.build(100, "archer") and not sim.build(0, "missing"), "Invalid purchases leave state intact")
	check(sim.build(0, "archer") and not sim.build(0, "archer"), "Purchase locks pad against double action")
	check(sim.coins == 130 and sim.towers.size() == 1, "Cost deducted exactly once")
	var tower: SimTowerV2 = sim.tower_on_pad(0)
	tick(sim, 100)
	check(tower.state == SimTowerV2.State.BUILDING, "Tower respects construction duration")
	var construction_ticks: int = tower.work_elapsed
	sim.paused = true
	tick(sim, 100)
	check(tower.work_elapsed == construction_ticks and not sim.cancel_work(0), "Pause freezes construction and economic actions")
	sim.paused = false
	tick(sim, 80)
	check(tower.state == SimTowerV2.State.READY, "Construction completes at fixed tick")
	check(sim.upgrade(0) and sim.coins == 35 and tower.state == SimTowerV2.State.UPGRADING, "Upgrade debits incremental cost and disables attack")
	sim.step()
	check(sim.cancel_work(0) and tower.level == 1 and tower.investment == 70 and sim.coins == 130, "Early upgrade cancellation restores prior level and investment")
	check(not sim.sell(0), "Same-tick sell after cancel cannot double transact")
	sim.step()
	check(sim.sell(0) and sim.coins == 172 and sim.tower_on_pad(0) == null, "Sale refunds floor of completed investment times 60 percent")
	sim.step()
	sim.build(0, "cannon")
	tick(sim, 60)
	check(sim.cancel_work(0) and sim.coins == 139, "Late build cancellation refunds exactly 70 percent")

	sim = fixture(1)
	sim.catalog.towers.archer.levels[0].build = 0.01
	sim.catalog.towers.archer.levels[0].damage = 100
	sim.build(0, "archer")
	sim.start_first_wave()
	tick(sim, 300)
	check(sim.state == BattleSimV2.State.VICTORY and sim.kills == 1 and sim.leaks == 0, "Real weapon windup and projectile can win battle")
	check(sim.projectiles.is_empty(), "Terminal cleanup removes projectiles")

	sim = fixture(1)
	sim.catalog.enemies.grunt.speed = 0.0
	sim.catalog.towers.archer.levels[0].build = 0.01
	sim.build(0, "archer")
	sim.step()
	var a: SimEnemyV2 = sim.spawn_enemy("grunt")
	var b: SimEnemyV2 = sim.spawn_enemy("grunt")
	tower = sim.tower_on_pad(0)
	check(sim.choose_target(tower).id == a.id, "Target ties prefer lower spawn sequence")
	b.position = Vector3(2, 50, 1)
	b.distance = 1.0
	check(sim.choose_target(tower).id == b.id, "Target reach uses XZ plane rather than decorative altitude")
	a.armor = 10
	check(is_equal_approx(sim.damage(a.id, 20, "physical"), 10), "Physical damage uses full armor")
	check(is_equal_approx(sim.damage(a.id, 20, "magical"), 15), "Magic damage uses half armor")
	check(is_equal_approx(sim.damage(a.id, 20, "pure"), 20), "Pure damage ignores armor")

	var slow_sim: BattleSimV2 = fixture(1)
	var fast_sim: BattleSimV2 = fixture(1)
	slow_sim.build(0, "archer")
	fast_sim.build(0, "archer")
	slow_sim.start_first_wave()
	fast_sim.start_first_wave()
	for index in range(900):
		slow_sim.advance(1.0 / 60.0)
	for index in range(450):
		fast_sim.advance(2.0 / 60.0)
	check(slow_sim.summary() == fast_sim.summary(), "1x and 2x produce identical results for identical simulation time")
	print("P2 simulation: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
