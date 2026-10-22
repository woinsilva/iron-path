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
	var sim: BattleSimV2 = BattleSimV2.new(BattleSimV2.load_catalog(), [route], PackedVector3Array(), [], 200, 100)
	sim.spawn_enemy("boss_captain")
	var escort: SimEnemyV2 = sim.spawn_enemy("grunt")
	escort.speed = 0.7 # Isolate aura timing by holding the escort near its captain.
	return sim
func tick(sim: BattleSimV2, count: int) -> void:
	for index in range(count): sim.step()
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var sim: BattleSimV2 = fixture()
	var boss: SimEnemyV2 = sim.enemies.values()[0]
	var escort: SimEnemyV2 = sim.enemies.values()[1]
	tick(sim, 179)
	check(boss.ability_until == 0 and sim.speed_aura_for(escort) == 0, "Captain gives a clear initial arrival before telegraphing")
	tick(sim, 1)
	check(boss.ability_until == sim.ticks + 108 and sim.speed_aura_for(escort) == 0, "Rally announces one-point-eight seconds before applying its effect")
	sim.paused = true
	var paused_until: int = boss.ability_until
	tick(sim, 120)
	check(sim.ticks == 180 and boss.ability_until == paused_until, "Pause freezes boss windup and its deadline")
	sim.paused = false
	tick(sim, 108)
	check(boss.ability_until == 0 and boss.rally_until == sim.ticks + 240, "Rally activates for exactly four simulation seconds")
	check(is_equal_approx(sim.speed_aura_for(escort), 0.25) and sim.speed_aura_for(boss) == 0, "Rally strengthens nearby escort but never the captain itself")
	var other: SimEnemyV2 = sim.spawn_enemy("boss_captain")
	other.rally_until = boss.rally_until
	sim._update_enemy_abilities()
	check(is_equal_approx(sim.speed_aura_for(escort), 0.25), "Two rally auras use the strongest bonus instead of adding")
	escort.position = Vector3(90, 0, 0)
	check(sim.speed_aura_for(escort) == 0, "Escort outside the announced radius gains no bonus")
	tick(sim, 240)
	check(boss.rally_until <= sim.ticks and sim.speed_aura_for(escort) == 0, "Rally expires without a lingering invisible aura")
	sim = fixture()
	boss = sim.enemies.values()[0]
	tick(sim, 180)
	sim.damage(boss.id, 100000, "pure")
	tick(sim, 200)
	check(sim.kills == 1 and sim.earned == 60, "Captain death rewards once and cancels a pending telegraph")
	var activated: bool = false
	for event: Dictionary in sim.consume_events():
		if str(event.kind) == "enemy_ability_active": activated = true
	check(not activated, "A defeated captain cannot release its scheduled rally")
	var normal: BattleSimV2 = fixture()
	var fast: BattleSimV2 = fixture()
	for index in range(1800): normal.advance(1.0 / 60)
	for index in range(900): fast.advance(2.0 / 60)
	check(normal.summary() == fast.summary(), "Boss and escort preserve one/two-times simulation equivalence")
	var definitions: Dictionary = BattleSimV2.load_catalog()
	for pair: Array in [["armored", "guardian"], ["boss_captain", "captain"]]:
		var key: String = pair[0]
		var actor: RiggedActor3D = RiggedActor3D.new()
		actor.model_path = "res://art/models/%s.glb" % str(pair[1])
		actor.set_meta("type_id", key)
		actor.set_meta("equipment", definitions.enemies[key].equipment)
		root.add_child(actor)
		check(actor.skeleton.get_bone_count() == 23 and actor.player.has_animation("walk") and actor.player.has_animation("death"), "%s preserves actual bones and locomotion/death clips" % key)
		if key == "boss_captain":
			check(actor.player.has_animation("rally"), "Captain has its own skeletal rally gesture")
			actor.perform_rally(1.8)
			actor.animation_tree.advance(0.2)
			check(bool(actor.animation_tree.get("parameters/Rally/active")), "Telegraph gesture blends over the locomotion graph")
			actor.die()
			actor.animation_tree.advance(0.4)
			check(actor.dead and not bool(actor.animation_tree.get("parameters/Rally/active")), "Death interrupts the telegraph gesture")
		actor.queue_free()
	await process_frame
	print("P6 captain: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
