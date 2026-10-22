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
	var boss: SimEnemyV2 = battle.simulation.spawn_enemy("boss_ruin", 0, 30)
	battle._physics_process(1.0 / 60)
	var actor: RuinGuardianActorV2 = battle.enemy_views[boss.id] as RuinGuardianActorV2
	check(actor != null and actor.skeleton.get_bone_count() == 23 and battle._boss_panel.visible, "Final guardian uses its own skeletal stone body and dedicated health panel")
	battle.simulation.ticks = 240
	battle._physics_process(1.0 / 60)
	check(battle._boss_label.text.contains("Preparando Postura física") and battle._enemy_areas.has(boss.id), "Final guardian warning describes its physical posture before activation")
	battle.simulation.ticks = 360
	battle._physics_process(1.0 / 60)
	check(str((battle._enemy_areas[boss.id] as Node3D).get_meta("pool_key")) == "posture_physical", "World signal switches from warning to the active physical posture")
	battle.simulation.paused = true
	var previous: int = battle.simulation.ticks
	battle._physics_process(1.0)
	check(battle.simulation.ticks == previous, "Pause freezes final guardian posture clock")
	battle.simulation.paused = false
	battle.simulation.damage(boss.id, 10000, "pure")
	battle._physics_process(1.0 / 60)
	check(actor.dead and not battle._boss_panel.visible and not battle._enemy_areas.has(boss.id), "Final guardian death clears posture area and health panel")
	battle.simulation.wave_index = 24
	battle._show_result(true)
	check(battle._result_body.text.contains("Campanha concluída!"), "Last stage presents the complete campaign ending")
	battle.queue_free()
	await process_frame
	print("P8 ruin world: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
