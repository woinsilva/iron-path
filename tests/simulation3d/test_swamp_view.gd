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
	battle.stage_path = "res://data/campaign/stage_09.json"
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	var clear: bool = true
	for pad: Vector3 in battle.simulation.pads:
		clear = clear and battle.simulation.can_build_at(pad)
	check(clear, "Swamp bases remain outside the new road")
	check(battle.diorama.find_children("RunicRuin*", "", false, false).size() >= 4, "Swamp has its own runic ruin geometry")
	var enemy: SimEnemyV2 = battle.simulation.spawn_enemy("resistant", 0, 24)
	battle._physics_process(1.0 / 60)
	var actor: RiggedActor3D = battle.enemy_views[enemy.id]
	check(actor.skeleton.get_bone_count() >= 23 and actor.model.find_children("RunicCrown", "", true, false).size() == 1, "Runic crown follows the actual head bone on the animated guardian")
	var crown: Node3D = actor.model.find_child("RunicCrown", true, false) as Node3D
	var halo: MeshInstance3D = crown.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	check((halo.global_transform * halo.get_aabb()).get_center().y > actor.global_position.y + 2.3 * actor.scale.y, "Runic halo stays above the helmet instead of being hidden inside it")
	battle.simulation.damage(enemy.id, 240, "pure")
	battle._physics_process(1.0 / 60)
	check(actor.dead, "Runic actor enters death and retires without holding the wave")
	var hidden: SimEnemyV2 = battle.simulation.spawn_enemy("burrower", 0, 11.99)
	battle._handle_events(battle.simulation.consume_events())
	battle._sync_enemies(1.0 / 60)
	var burrow: CrawlerActorV2 = battle.enemy_views[hidden.id] as CrawlerActorV2
	check(burrow != null and not burrow.model.visible and burrow._burrow_dust.visible, "Burrower displays a soil trail instead of an exposed body underground")
	battle._physics_process(1.0 / 60)
	check(burrow.model.visible and not burrow._burrow_dust.visible, "Burrower body emerges exactly when simulation enables targeting")
	var summoner: SimEnemyV2 = battle.simulation.spawn_enemy("summoner", 0, 30)
	battle._physics_process(1.0 / 60)
	var mage: RiggedActor3D = battle.enemy_views[summoner.id]
	check(mage.model_path.ends_with("skeleton_mage.glb") and mage.model.find_children("SummoningCrown", "", true, false).size() == 1, "Summoner has its own crown silhouette on a real animated mage rig")
	battle.queue_free()
	await process_frame
	var submerged: BattleViewV2 = BattleViewV2.new()
	submerged.stage_path = "res://data/campaign/stage_10.json"
	root.add_child(submerged)
	current_scene = submerged
	submerged.set_physics_process(false)
	var clear_branches: bool = true
	for pad: Vector3 in submerged.simulation.pads:
		for route_id in [0, 2]: clear_branches = clear_branches and submerged.simulation.routes[route_id].get_closest_point(pad).distance_to(pad) >= 2.2
	check(clear_branches, "Submerged bases stay clear of both ground routes")
	var marker: Node3D = submerged.get_node("EmergenceMarker2") as Node3D
	check(marker.position.is_equal_approx(submerged.simulation.routes[2].sample_baked(12) + Vector3(0, 0.18, 0)), "Visible emergence marker matches the authoritative tunnel distance")
	submerged.queue_free()
	await process_frame
	print("P8 swamp world: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
