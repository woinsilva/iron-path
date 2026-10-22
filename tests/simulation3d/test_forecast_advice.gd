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
	root.size = Vector2i(1920,1080)
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_10.json"
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	battle._show_forecast()
	var body: Label = battle._help_layer.find_child("InfoBody",true,false) as Label
	check(body.text.contains("Onda 1") and body.text.contains("Onda 2") and body.text.contains("Escavador"), "Forecast exposes two upcoming authored waves and their actual enemy rules")
	var tick: int = battle.simulation.ticks
	battle.simulation.advance(3)
	check(paused and battle.simulation.ticks == tick, "Forecast pauses battle clocks while the player reads")
	battle._dismiss_help()
	check(not paused and not battle.simulation.paused, "Closing forecast restores a previously running battle")
	battle._toggle_pause()
	battle._show_forecast()
	battle._dismiss_help()
	check(paused and battle.simulation.paused, "Closing forecast preserves an existing manual pause")
	battle._toggle_pause()
	var route: Curve3D = battle.simulation.routes[1]
	var flyer: SimEnemyV2 = battle.simulation.spawn_enemy("flyer_heavy",1,route.get_baked_length()-.11)
	for frame in range(10): battle._physics_process(1.0/60)
	check(not flyer.alive and battle.simulation.leaked_types.get("flyer_heavy",0) == 1 and battle.simulation.leaked_layers.get("air",0) == 1, "Escaped enemy is counted once by real type and target layer")
	battle._show_result(false)
	check(battle._result_body.text.contains("Vespa Couraçada"), "Result identifies the actual enemy that breached the defense")
	check(battle._result_body.text.contains("Farol Celeste") and battle._result_body.text.contains("moedas"), "Result advice responds to airborne leaks and unused resources")
	await process_frame
	await process_frame
	check(root.get_visible_rect().encloses(battle._result.get_global_rect()), "Detailed result and replay controls remain inside the phone layout")
	battle.queue_free()
	await process_frame
	print("P9 forecast and advice: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
