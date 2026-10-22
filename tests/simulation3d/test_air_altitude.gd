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
	for index in [2,3,5,8,12]:
		var battle: BattleViewV2 = BattleViewV2.new()
		battle.stage_path = "res://data/campaign/stage_%02d.json" % index
		root.add_child(battle)
		current_scene = battle
		battle.set_physics_process(false)
		var route: int = 1 if battle.simulation.routes.size() > 1 else 0
		var enemy: SimEnemyV2 = battle.simulation.spawn_enemy("flyer_heavy" if index >= 8 else "flyer",route,10)
		var logical_height: float = enemy.position.y
		battle._physics_process(1.0/60)
		var actor: FlyingActorV2 = battle.enemy_views[enemy.id] as FlyingActorV2
		check(actor != null and actor.position.y >= 2.29 and enemy.position.y == logical_height, "Stage %02d keeps actual flying body above the ground without changing its logical route" % index)
		battle.queue_free()
		await process_frame
	print("P9 air altitude: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
