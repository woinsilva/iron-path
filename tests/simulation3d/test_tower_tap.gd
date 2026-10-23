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
	battle.stage_path = "res://data/campaign/stage_02.json"
	root.add_child(battle)
	current_scene = battle
	battle.set_physics_process(false)
	while battle._warming_up: await process_frame
	var placed: int = battle.simulation.build_at(battle.simulation.pads[3], "archer")
	check(placed >= 0 and battle._selected_pad == -1, "Placing a tower does not select it")
	for tick in range(400): battle._physics_process(1.0 / 60)
	var tower: SimTowerV2 = battle.simulation.tower_on_pad(placed)
	var screen: Vector2 = battle.diorama.camera.unproject_position(tower.position + Vector3(0, 0.6, 0))
	var priority: String = tower.priority
	for pressed: bool in [true, false]:
		var touch: InputEventScreenTouch = InputEventScreenTouch.new()
		touch.position = screen
		touch.pressed = pressed
		battle._unhandled_input(touch)
		check(battle._selected_pad == (-1 if pressed else placed), "Tower is selected on release, not on press" if pressed else "Release completes the tap")
		await process_frame
	check(battle._selected_pad == placed and battle._actions.visible, "Tapping a built tower opens its card")
	check(tower.priority == priority, "The tap that opens the card does not press a card button")
	var card: Rect2 = battle._actions.get_global_rect()
	check(not card.has_point(screen), "The card opens away from the tapped tower")
	battle.queue_free()
	await process_frame
	print("P13 tower tap: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
