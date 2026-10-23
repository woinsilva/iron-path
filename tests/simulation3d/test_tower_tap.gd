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
	# Releasing a ghost on the road (red) cancels the placement instead of keeping the card armed.
	battle._select_pad(-1)
	battle._begin_placement("cannon")
	var road: Vector3 = battle.simulation.routes[0].sample_baked(10.0)
	var release: InputEventScreenTouch = InputEventScreenTouch.new()
	release.position = battle.diorama.camera.unproject_position(road)
	release.pressed = false
	var towers_before: int = battle.simulation.towers.size()
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.position = release.position
	battle._unhandled_input(drag)
	battle._unhandled_input(release)
	check(battle._placing.is_empty() and not is_instance_valid(battle._ghost) and battle.simulation.towers.size() == towers_before, "Dropping a red ghost removes it and builds nothing")
	battle.queue_free()
	await process_frame
	print("P13 tower tap: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
