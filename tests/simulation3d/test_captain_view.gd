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
	call_deferred("run")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_04.json"
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	var clear_layout: bool = true
	for pad: Vector3 in battle.simulation.pads:
		clear_layout = clear_layout and pad.distance_to(battle.simulation.routes[0].get_closest_point(pad)) >= 2.2
	check(clear_layout, "Gate stage keeps all building bases off the road")
	var elite: SimEnemyV2 = battle.simulation.spawn_enemy("grunt_elite")
	battle._physics_process(1.0 / 60)
	check((battle.enemy_views[elite.id] as Node3D).find_child("EliteArmor", true, false) != null, "Elite protection is attached to its actual skeleton")
	var captain: SimEnemyV2 = battle.simulation.spawn_enemy("boss_captain")
	for index in range(181): battle._physics_process(1.0 / 60)
	var actor: RiggedActor3D = battle.enemy_views[captain.id]
	check(actor.model_path.ends_with("captain.glb") and actor.player.has_animation("rally"), "Boss spawns its distinct imported rig and gesture")
	check(battle._boss_panel.visible and battle._boss_label.text.contains("Preparando Brado"), "Boss health and windup are readable in a dedicated HUD")
	check(battle._enemy_areas.has(captain.id) and str((battle._enemy_areas[captain.id] as Node3D).get_meta("pool_key")) == "warning", "Telegraph radius is shown before its effect")
	for index in range(108): battle._physics_process(1.0 / 60)
	check(battle._boss_label.text.contains("Brado ativo") and str((battle._enemy_areas[captain.id] as Node3D).get_meta("pool_key")) == "rally", "Activation changes both countdown text and world signal")
	battle.simulation.damage(captain.id, 100000, "pure")
	battle._physics_process(1.0 / 60)
	check(not battle._boss_panel.visible and not battle._enemy_areas.has(captain.id), "Defeated boss clears its health panel and ability ring")
	battle.queue_free()
	await process_frame
	print("P6 boss world: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
