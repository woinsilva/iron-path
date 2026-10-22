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
	var sim: BattleSimV2 = StageSessionV2.create(StageSessionV2.read_stage("res://data/campaign/stage_10.json"))
	var source: SimEnemyV2 = sim.spawn_enemy("summoner", 0, 30)
	source.speed = 0
	sim.ticks = 240
	sim._update_enemy_abilities()
	check(source.pending_ability == "summon" and source.ability_until == 360, "Summoner announces two full seconds before creating reinforcements")
	sim.ticks = 359
	sim._update_enemy_abilities()
	check(source.summons_spawned == 0, "Summoner cannot spawn before its warning finishes")
	sim.ticks = 360
	sim._update_enemy_abilities()
	check(source.summons_spawned == 2 and sim._active_reinforcements(source.id) == 2, "Summoner creates its declared pair")
	var legal: bool = true
	for child: SimEnemyV2 in sim.enemies.values():
		if child.summoner_id != source.id: continue
		legal = legal and child.reward == 0 and child.route_id == source.route_id and child.position.is_equal_approx(sim.routes[0].sample_baked(child.distance))
	check(legal, "Summons inherit the source route and never pay farmable rewards")
	for time in range(361, 3000):
		sim.ticks = time
		sim._update_enemy_abilities()
	check(source.summons_spawned == 4 and sim._active_reinforcements(source.id) == 4, "Concurrent cap prevents an unbounded living swarm")
	for child: SimEnemyV2 in sim.enemies.values():
		if child.summoner_id == source.id: sim.damage(child.id, 1000, "pure")
	for time in range(3000, 6000):
		sim.ticks = time
		sim._update_enemy_abilities()
	check(source.summons_spawned == 6 and sim.earned == 0, "Lifetime cap allows only six summons even after earlier children die")
	sim.damage(source.id, 1000, "pure")
	var spawned: int = sim.spawned
	for time in range(6000, 9000):
		sim.ticks = time
		sim._update_enemy_abilities()
	check(sim.spawned == spawned and sim.earned == 20, "Killing the source stops future summons and pays only its own reward")
	print("P8 summoner: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
