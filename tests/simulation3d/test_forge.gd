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
	var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_08.json")
	var sim: BattleSimV2 = StageSessionV2.create(stage)
	var boss: SimEnemyV2 = sim.spawn_enemy("boss_colossus", 0, 30)
	boss.speed = 0
	sim.ticks = 240
	sim._update_enemy_abilities()
	check(boss.ability_until == 360 and boss.shield == 0 and boss.pending_ability == "shield", "Forge barrier announces a full two-second windup")
	sim.ticks = 360
	sim._update_enemy_abilities()
	check(boss.shield == 300 and boss.shield_until == 600 and boss.ability_shields_left == 1, "Forge barrier has explicit amount, lifetime and finite charges")
	sim.ticks = 600
	sim._update_enemy_abilities()
	check(boss.shield == 0 and boss.health == boss.maximum_health, "Temporary shield expires without healing the boss")
	sim.ticks = 960
	sim._update_enemy_abilities()
	check(boss.pending_ability == "summon" and boss.ability_until == 1080, "Next cycle announces reinforcements instead of another barrier")
	sim.ticks = 1080
	sim._update_enemy_abilities()
	check(boss.summons_spawned == 2 and sim._active_reinforcements(boss.id) == 2, "Reinforcement pulse spawns its bounded pair")
	var correct_children: bool = true
	for enemy: SimEnemyV2 in sim.enemies.values():
		if enemy.summoner_id != boss.id: continue
		correct_children = correct_children and enemy.reward == 0 and enemy.route_id == boss.route_id and enemy.distance > 28 and enemy.distance < 30
		correct_children = correct_children and enemy.position.is_equal_approx(sim.routes[0].sample_baked(enemy.distance))
		sim.damage(enemy.id, 1000, "pure")
	check(correct_children and sim.earned == 0, "Summons start beside their parent on the authoritative route and pay no reward")
	for time in range(1081, 12000):
		sim.ticks = time
		sim._update_enemy_abilities()
	check(boss.summons_spawned == 6 and sim._active_reinforcements(boss.id) <= 4, "Lifetime and concurrent reinforcement caps remain bounded over repeated cycles")
	check(boss.ability_shields_left == 0, "Forge cannot create unlimited barrier charges")
	sim.damage(boss.id, 100000, "pure")
	check(sim.earned == 100 and sim._active_reinforcements(boss.id) > 0, "Boss pays exactly its reward while surviving reinforcements remain real enemies")
	sim.wave_index = 20
	sim.state = BattleSimV2.State.WAVE_ACTIVE
	sim.step()
	check(sim.state == BattleSimV2.State.WAVE_ACTIVE, "Final wave waits for remaining summoned enemies after boss death")
	for child: SimEnemyV2 in sim.enemies.values(): sim.damage(child.id, 1000, "pure")
	sim.step()
	check(sim.state == BattleSimV2.State.VICTORY and sim.earned == 100, "Clearing reinforcements finishes the wave without farming currency")
	var aura_sim: BattleSimV2 = StageSessionV2.create(stage)
	var source: SimEnemyV2 = aura_sim.spawn_enemy("standardbearer")
	var target: SimEnemyV2 = aura_sim.spawn_enemy("grunt")
	var immune: SimEnemyV2 = aura_sim.spawn_enemy("boss_colossus")
	aura_sim._update_enemy_abilities()
	check(is_equal_approx(aura_sim.speed_aura_for(target), .2) and aura_sim.speed_aura_for(source) == 0 and aura_sim.speed_aura_for(immune) == 0, "Persistent standard aura accelerates allies but not itself or bosses")
	var source2: SimEnemyV2 = aura_sim.spawn_enemy("standardbearer")
	aura_sim._update_enemy_abilities()
	check(is_equal_approx(aura_sim.speed_aura_for(target), .2), "Overlapping identical speed auras do not stack")
	aura_sim.damage(source.id, 1000, "pure")
	aura_sim.damage(source2.id, 1000, "pure")
	check(aura_sim.speed_aura_for(target) == 0, "Killing the aura sources removes their bonus immediately")
	var one: BattleSimV2 = StageSessionV2.create(stage)
	var two: BattleSimV2 = StageSessionV2.create(stage)
	var a: SimEnemyV2 = one.spawn_enemy("boss_colossus")
	var b: SimEnemyV2 = two.spawn_enemy("boss_colossus")
	a.speed = 0
	b.speed = 0
	for frame in range(2400): one.advance(1.0 / 60)
	for frame in range(1200): two.advance(1.0 / 30)
	check(one.summary() == two.summary() and a.shield == b.shield and a.summons_spawned == b.summons_spawned, "Forge cycles and reinforcements are equivalent at one and two times speed")
	print("P7 forge rules: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
