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
	var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_12.json")
	var sim: BattleSimV2 = StageSessionV2.create(stage)
	var boss: SimEnemyV2 = sim.spawn_enemy("boss_ruin", 0, 30)
	sim.ticks = 240
	sim._update_enemy_abilities()
	check(boss.pending_ability == "posture_physical" and boss.ability_until == 360 and sim.remaining_armor(boss) == 8, "Ruin physical posture announces itself before changing armor")
	sim.ticks = 360
	sim._update_enemy_abilities()
	check(sim.remaining_armor(boss) == 20 and sim.damage(boss.id, 100, "pure") == 100, "Physical posture adds twelve armor without blocking pure damage")
	sim.apply_status(boss.id, "corrosion", 100, 10, 3)
	check(sim.remaining_armor(boss) == 10, "Corrosion remains capped at half the current posture armor")
	sim.ticks = 660
	check(sim.remaining_armor(boss) == 4, "Posture expires after five seconds and corrosion remains bounded")
	boss.health = boss.maximum_health * .5
	sim.ticks = 960
	sim._update_enemy_abilities()
	check(boss.pending_ability == "summon" and boss.health == boss.maximum_health * .5, "Middle health phase selects limited reinforcement without healing")
	sim.ticks = 1080
	sim._update_enemy_abilities()
	check(boss.summons_spawned == 2 and boss.rally_until == 1380, "Middle phase reuses bounded announced reinforcements")
	sim.ticks = 1680
	sim._update_enemy_abilities()
	check(boss.pending_ability == "aura", "Middle phase alternates reinforcements with its speed aura")
	var ally: SimEnemyV2 = sim.spawn_enemy("grunt", 0, 30)
	sim.ticks = 1800
	sim._update_enemy_abilities()
	check(is_equal_approx(sim.speed_aura_for(ally), .2) and sim.speed_aura_for(boss) == 0, "Ruin aura accelerates nearby allies without accelerating the boss")
	boss.health = boss.maximum_health * .3
	boss.ability_cycle_index = 4
	sim.ticks = 2400
	sim._update_enemy_abilities()
	check(boss.pending_ability == "posture_magic" and is_equal_approx(sim.effective_magic_resistance(boss), .2), "Final phase announces magical protection while the old base resistance still applies")
	sim.ticks = 2520
	sim._update_enemy_abilities()
	check(is_equal_approx(sim.effective_magic_resistance(boss), .6), "Final posture applies the declared sixty percent magical resistance")
	sim.ticks = 2820
	check(is_equal_approx(sim.effective_magic_resistance(boss), .2), "Magical posture ends and restores a vulnerable window")
	var one: BattleSimV2 = StageSessionV2.create(stage)
	var two: BattleSimV2 = StageSessionV2.create(stage)
	var a: SimEnemyV2 = one.spawn_enemy("boss_ruin")
	var b: SimEnemyV2 = two.spawn_enemy("boss_ruin")
	a.health = a.maximum_health * .3
	b.health = b.maximum_health * .3
	for frame in range(3000): one.advance(1.0 / 60)
	for frame in range(1500): two.advance(2.0 / 60)
	check(one.summary() == two.summary() and a.pending_ability == b.pending_ability and a.summons_spawned == b.summons_spawned, "Ruin phases remain deterministic at one and two times speed")
	print("P8 ruin rules: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
