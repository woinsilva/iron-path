extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_12.json"
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	battle.simulation.build(0,"anti_air")
	for tick in range(181): battle._physics_process(1.0/60)
	var tower: SimTowerV2 = battle.simulation.tower_on_pad(0)
	var enemy: SimEnemyV2 = battle.simulation.spawn_enemy("flyer_heavy",1,10)
	battle._physics_process(1.0/60)
	var actor: RiggedActor3D = battle.enemy_views[enemy.id]
	var aim: Vector3 = actor.impact_position()
	battle.simulation._release(tower,enemy)
	var shot: Dictionary = battle.simulation.projectiles.values().back()
	shot.position = enemy.position
	battle._sync_projectiles()
	var display: Node3D = battle.projectile_views[int(shot.id)]
	check(absf(display.position.y - aim.y) < .001 and display.position.y > 2, "Anti-air projectile reaches the actual flying body instead of the ground")
	check(actor.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_ON and actor.model.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "World movement interpolates while rendered wing animation remains independent")
	check(display.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_ON and not display.has_meta("interpolation_spawn"), "Fresh projectile resets its interpolation history after world placement")
	check(enemy.health == enemy.maximum_health, "Synchronizing projectile visuals cannot apply logical damage")
	shot.damage = 10000 # Impact-position fixture, not a campaign damage configuration.
	battle.simulation._update_projectiles()
	battle._handle_events(battle.simulation.consume_events())
	var effect: MeshInstance3D = battle._effects.back().node as MeshInstance3D
	check(enemy.health == 0 and absf(effect.position.y - aim.y) < .1, "Lethal hit retains the pre-death body impact point after retiring the target")
	var crawler: SimEnemyV2 = battle.simulation.spawn_enemy("swarm",0,10)
	battle._physics_process(1.0/60)
	var ground: RiggedActor3D = battle.enemy_views[crawler.id]
	check(ground.impact_position().y < 1 and ground.impact_position().y > ground.position.y, "Low crawler exposes its actual shell height instead of a humanoid hit point")
	battle.queue_free()
	await process_frame
	print("P9 visual aim: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
