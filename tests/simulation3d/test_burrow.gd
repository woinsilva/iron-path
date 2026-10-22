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
	var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_09.json")
	var sim: BattleSimV2 = StageSessionV2.create(stage)
	var enemy: SimEnemyV2 = sim.spawn_enemy("burrower", 0, 11.99)
	check(enemy.underground(), "Burrower starts hidden only before its declared emergence point")
	check(sim.damage(enemy.id, 100, "pure") == 0 and not sim.apply_status(enemy.id, "slow", .5, 3, 7), "Buried enemies reject direct damage and control")
	check(not sim._layer_matches({"layer":"both"}, enemy), "Area chain and piercing filters exclude underground enemies")
	sim.build(0, "cannon")
	var tower: SimTowerV2 = sim.tower_on_pad(0)
	tower.position = enemy.position
	check(not sim._valid_target(tower, enemy), "Ground towers cannot acquire a buried target")
	sim._move_enemies()
	check(not enemy.underground() and is_equal_approx(enemy.distance, 12), "Emergence occurs at the exact announced route distance")
	var emerged: int = 0
	for event: Dictionary in sim.consume_events():
		if str(event.kind) == "emerged": emerged += 1
	sim._move_enemies()
	for event: Dictionary in sim.consume_events():
		if str(event.kind) == "emerged": emerged += 1
	check(emerged == 1 and sim._valid_target(tower, enemy), "Emergence emits once and exposes the enemy to ordinary ground towers")
	check(sim.damage(enemy.id, 20, "physical") == 17 and sim.apply_status(enemy.id, "slow", .5, 3, 7), "Emerged enemies receive normal armor damage and control")
	var one: BattleSimV2 = StageSessionV2.create(stage)
	var two: BattleSimV2 = StageSessionV2.create(stage)
	var a: SimEnemyV2 = one.spawn_enemy("burrower")
	var b: SimEnemyV2 = two.spawn_enemy("burrower")
	for frame in range(600): one.advance(1.0 / 60)
	for frame in range(300): two.advance(2.0 / 60)
	check(a.distance == b.distance and a.position == b.position and not a.underground(), "Burrow movement and emergence are equivalent at one and two times speed")
	print("P8 burrow: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
