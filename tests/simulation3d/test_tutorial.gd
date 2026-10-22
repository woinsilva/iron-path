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
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	check(battle._hint.text.begins_with("1/3"), "New defender receives an in-game first action")
	battle._select_pad(0)
	check(battle._hint.text.begins_with("2/3") and battle.simulation.coins == 200, "Selecting a pad teaches purchase without spending money")
	check((battle._purchase_buttons.archer as Button).text.contains("4.2 m") and (battle._purchase_buttons.cannon as Button).text.contains("Terra"), "Purchase buttons explain reach and target layer before payment")
	battle._purchase("archer")
	check(battle._hint.text.begins_with("3/3"), "Construction leads into the first-wave instruction")
	battle._show_help()
	var before: int = battle.simulation.ticks
	battle.simulation.advance(5)
	check(paused and battle.simulation.paused and battle.simulation.ticks == before, "Help overlay freezes the battle rather than costing the player time")
	battle._dismiss_help()
	check(not paused and not battle.simulation.paused, "Closing help restores a previously running battle")
	for index in range(180): battle._physics_process(1.0 / 60)
	var completions: Array[int] = [0]
	battle.tutorial_finished.connect(func() -> void: completions[0] += 1)
	battle._start_or_early()
	battle._start_or_early()
	check(completions[0] == 1 and not battle.tutorial_enabled, "Tutorial completes exactly once when the first defense starts")
	check(battle._hint.text.begins_with("Defesa iniciada.") and not battle._hint.text.contains("toque em Iniciar defesa"), "Started defense replaces the stale first-wave instruction")
	battle._toggle_pause()
	battle._show_help()
	battle._dismiss_help()
	check(paused and battle.simulation.paused, "Closing help preserves an existing manual pause")
	battle.queue_free()
	await process_frame
	check(not paused, "Leaving tutorial battle clears residual global pause")
	print("P6 tutorial: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
