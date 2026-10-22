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
	return BattleSimV2.new(BattleSimV2.load_catalog(), [route], PackedVector3Array([Vector3.ZERO, Vector3(2, 0, 0), Vector3(-2, 0, 0)]), [], 50000, 100)
func tick(sim: BattleSimV2, count: int) -> void:
	for index in range(count): sim.step()
func tower_at(sim: BattleSimV2, family: String, level: int = 1, branch: String = "", pad: int = 0) -> SimTowerV2:
	sim.build(pad, family)
	var tower: SimTowerV2 = sim.tower_on_pad(pad)
	tick(sim, tower.work_ticks)
	for next_level in range(2, level + 1):
		sim.upgrade(pad, branch if next_level == 4 else "")
		tick(sim, tower.work_ticks)
	return tower
func target_at(sim: BattleSimV2, point: Vector3, layer: String = "ground") -> SimEnemyV2:
	var enemy: SimEnemyV2 = sim.spawn_enemy("flyer" if layer == "air" else "grunt")
	enemy.health = 10000
	enemy.maximum_health = 10000
	enemy.position = point
	enemy.speed = 0
	return enemy
func impact(sim: BattleSimV2, tower: SimTowerV2, target: SimEnemyV2) -> Dictionary:
	sim._release(tower, target)
	var shot: Dictionary = sim.projectiles.values().back()
	shot.position = target.position
	sim._update_projectiles()
	return shot
func _initialize() -> void:
	var catalog: Dictionary = BattleSimV2.load_catalog()
	var configs: int = 0
	for definition: Dictionary in catalog.towers.values():
		configs += definition.levels.size()
		for branch: Dictionary in definition.branches.values(): configs += branch.levels.size()
	check(catalog.towers.size() == 8 and configs == 56, "Eight families contain fifty-six explicit configurations")
	var sim: BattleSimV2 = fixture()
	var archer: SimTowerV2 = tower_at(sim, "archer", 3)
	var before: int = sim.coins
	check(not sim.upgrade(0) and sim.coins == before, "L3 requires an explicit branch choice")
	check(sim.upgrade(0, "A") and archer.branch.is_empty() and archer.pending_branch == "A", "Branch selection stays pending until work completes")
	tick(sim, 1)
	check(sim.cancel_work(0) and archer.level == 3 and archer.branch.is_empty() and sim.coins == before, "Early branch cancellation restores level and full payment")
	tick(sim, 1)
	sim.upgrade(0, "B")
	tick(sim, archer.work_ticks)
	check(archer.level == 4 and archer.branch == "B", "Completed branch commits the exclusive specialization")
	before = sim.coins
	check(not sim.upgrade(0, "A") and sim.coins == before, "Completed specialization cannot switch to the opposite branch")
	check(sim.upgrade(0), "L4 upgrades within its existing branch")
	tick(sim, archer.work_ticks)
	check(archer.level == 5 and archer.branch == "B" and not sim.upgrade(0), "L5 is terminal within the chosen branch")
	var refund: int = int(floor(archer.investment * 0.6))
	before = sim.coins
	sim.sell(0)
	check(sim.coins == before + refund, "Specialization investments retain correct sale refund")
	var restricted: BattleSimV2 = StageSessionV2.create(StageSessionV2.read_stage("res://data/campaign/stage_01.json"))
	check(not restricted.catalog.towers.archer.has("branches"), "Early campaign cannot bypass specialization unlocks")
	sim = fixture()
	archer = tower_at(sim, "archer", 4, "A")
	var enemy: SimEnemyV2 = target_at(sim, Vector3(2, 0, 0))
	var damages: Array[float] = []
	for index in range(4):
		damages.append(float(impact(sim, archer, enemy).damage))
	check(damages == [56.0, 56.0, 56.0, 112.0], "Atiradora critical follows a predictable four-shot sequence")
	sim = fixture()
	archer = tower_at(sim, "archer", 5, "B")
	for index in range(5): target_at(sim, Vector3(1 + index * 0.5, 0, 0))
	enemy = sim.enemies.values()[0]
	sim._release(archer, enemy)
	var targets: Dictionary = {}
	for shot: Dictionary in sim.projectiles.values(): targets[int(shot.target)] = true
	check(sim.projectiles.size() == 3 and targets.size() == 3, "Rajada launches at most three projectiles at distinct enemies")
	sim = fixture()
	var cannon: SimTowerV2 = tower_at(sim, "cannon", 4, "A")
	enemy = target_at(sim, Vector3(2, 0, 0))
	sim._release(cannon, enemy)
	var mortar: Dictionary = sim.projectiles.values()[0]
	enemy.position = Vector3(20, 0, 0)
	mortar.position = mortar.impact_point
	sim._update_projectiles()
	check(enemy.health == 10000 and sim.projectiles.is_empty(), "Mortar explodes at its announced point instead of chasing a fleeing target")
	sim = fixture()
	enemy = target_at(sim, Vector3.ZERO)
	enemy.armor = 18
	sim.apply_status(enemy.id, "corrosion", 100, 3, 1)
	check(sim.remaining_armor(enemy) == 9, "Corrosion cannot remove more than half the original armor")
	sim.apply_status(enemy.id, "corrosion", 4, 3, 2)
	check(sim.remaining_armor(enemy) == 9, "Corrosion sources use the strongest reduction rather than adding")
	check(is_equal_approx(sim.damage(enemy.id, 100, "physical", -1, 0.5), 95.5), "Armor penetration applies after capped corrosion")
	enemy.magic_resistance = 0.6
	check(is_equal_approx(sim.damage(enemy.id, 100, "magical"), 35.5), "Magic resistance and half armor preserve the intended counter")
	check(sim.damage(enemy.id, 0) == 0, "Zero-damage support cannot gain the minimum damage floor")
	sim = fixture()
	var frost: SimTowerV2 = tower_at(sim, "frost", 5, "A")
	enemy = target_at(sim, Vector3.ZERO)
	for index in range(5): impact(sim, frost, enemy)
	check(sim.fields.size() == 3, "Frost fields are capped at three per source")
	tick(sim, 1)
	check(is_equal_approx(sim.movement_factor(enemy), 0.65), "Frost field applies its announced strongest slow")
	sim.paused = true
	var field_ticks: int = sim.ticks
	tick(sim, 60)
	check(sim.ticks == field_ticks and sim.fields.size() == 3, "Pause freezes field duration and refresh")
	sim.paused = false
	sim.sell(0) # Stop creating new fields while existing fields expire.
	tick(sim, 180)
	check(sim.fields.is_empty(), "Frost fields expire on simulation time")
	sim = fixture()
	var venom: SimTowerV2 = tower_at(sim, "venom", 5, "A")
	for index in range(7): target_at(sim, Vector3(1 + index * 0.1, 0, 0))
	enemy = sim.enemies.values()[0]
	impact(sim, venom, enemy)
	var infected: int = 0
	for target: SimEnemyV2 in sim.enemies.values():
		if not target.statuses.is_empty(): infected += 1
	check(infected == 4, "Plague infects at most four total enemies per application")
	tick(sim, 60)
	infected = 0
	for target: SimEnemyV2 in sim.enemies.values():
		if not target.statuses.is_empty(): infected += 1
	check(infected == 4, "Poison ticks do not recursively spread the infection")
	sim = fixture()
	var ballista: SimTowerV2 = tower_at(sim, "bleed", 5, "A")
	for index in range(6): target_at(sim, Vector3(1 + index * 0.6, 0, 0.1))
	var outside: SimEnemyV2 = target_at(sim, Vector3(2, 0, 2))
	enemy = sim.enemies.values()[0]
	impact(sim, ballista, enemy)
	var hit_count: int = 0
	for target: SimEnemyV2 in sim.enemies.values():
		if target.health < 10000: hit_count += 1
	check(hit_count == 4 and outside.health == 10000, "Piercing respects the line width and four-target cap")
	sim = fixture()
	enemy = target_at(sim, Vector3.ZERO)
	enemy.speed = 1
	enemy.armor = 100
	sim.apply_status(enemy.id, "bleed", 8, 1, 1)
	tick(sim, 60)
	check(is_equal_approx(enemy.health, 9990), "Bleeding bypasses armor and gains twenty-five percent while moving")
	sim = fixture()
	var beacon: SimTowerV2 = tower_at(sim, "anti_air", 5, "A")
	for index in range(7): target_at(sim, Vector3(1 + index * 0.5, 2.2, 0), "air")
	var grounded: SimEnemyV2 = target_at(sim, Vector3(1, 0, 0))
	enemy = sim.enemies.values()[0]
	impact(sim, beacon, enemy)
	hit_count = 0
	for target: SimEnemyV2 in sim.enemies.values():
		if target.health < 10000: hit_count += 1
	check(hit_count == 4 and grounded.health == 10000, "Air chain respects target cap and excludes ground enemies")
	check(is_equal_approx((sim.enemies.values()[1] as SimEnemyV2).health, 10000 - 58 * 0.65), "Chain damage decays after each bounce")
	sim = fixture()
	var arcane: SimTowerV2 = tower_at(sim, "arcane", 5, "A")
	enemy = target_at(sim, Vector3(2, 0, 0))
	for index in range(12): impact(sim, arcane, enemy)
	check(float(impact(sim, arcane, enemy).damage) == 64, "Prisma heat reaches its finite damage cap")
	var replacement: SimEnemyV2 = target_at(sim, Vector3(3, 0, 0))
	check(float(impact(sim, arcane, replacement).damage) == 32, "Prisma loses heat when it changes target")
	replacement.position = Vector3(50, 0, 0)
	sim._update_weapons()
	check(arcane.focus_target == -1 and arcane.focus_stacks == 0, "Prisma loses heat immediately when its target leaves range")
	sim = fixture()
	var support: SimTowerV2 = tower_at(sim, "banner", 1)
	archer = tower_at(sim, "archer", 1, "", 1)
	var second: SimTowerV2 = tower_at(sim, "banner", 1, "", 2)
	check(is_equal_approx(float(sim.buffs_for(archer).haste), 0.1), "Two equal support auras do not stack")
	check(float(sim.buffs_for(support).haste) == 0 and float(sim.buffs_for(second).haste) == 0, "Support towers cannot buff themselves or create a support cycle")
	enemy = target_at(sim, Vector3.ZERO)
	sim._release(archer, enemy)
	check(archer.cooldown_until - sim.ticks < 30, "Support haste produces an actual faster attack interval")
	sim._update_weapons()
	check(support.pending_target == -1 and second.pending_target == -1, "Support towers never select enemies")
	var flight_ticks: Array[int] = []
	for altitude: float in [0, 50]:
		var flight: BattleSimV2 = fixture()
		var shooter: SimTowerV2 = tower_at(flight, "archer")
		var flying: SimEnemyV2 = target_at(flight, Vector3(4, altitude, 0), "air")
		flight._release(shooter, flying)
		var elapsed: int = 0
		while not flight.projectiles.is_empty() and elapsed < 100:
			flight._update_projectiles()
			elapsed += 1
		flight_ticks.append(elapsed)
	check(flight_ticks[0] == flight_ticks[1], "Decorative altitude does not change authoritative projectile travel time")
	var normal: BattleSimV2 = ensemble()
	var fast: BattleSimV2 = ensemble()
	for index in range(600): normal.advance(1.0 / 60)
	for index in range(300): fast.advance(2.0 / 60)
	check(normal.summary() == fast.summary(), "Advanced fields, status, support and multi-shot preserve one/two-times equivalence")
	check(normal.fields.size() == fast.fields.size(), "Field lifecycle remains identical across playback speeds")
	check(normal.tower_on_pad(1).supported_attacks == fast.tower_on_pad(1).supported_attacks and normal.tower_on_pad(1).supported_attacks > 0, "Support accounting is useful and deterministic")
	print("P5 arsenal: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func ensemble() -> BattleSimV2:
	var sim: BattleSimV2 = fixture()
	tower_at(sim, "frost", 5, "A", 0)
	tower_at(sim, "banner", 5, "B", 1)
	tower_at(sim, "archer", 5, "B", 2)
	for index in range(8):
		var enemy: SimEnemyV2 = target_at(sim, Vector3.ZERO, "air" if index % 2 else "ground")
		enemy.health = 100000
		enemy.maximum_health = 100000
		enemy.speed = 0.2
	return sim
