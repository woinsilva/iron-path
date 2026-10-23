extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	root.add_child(battle)
	current_scene = battle
	await process_frame
	battle.set_physics_process(false)
	check(battle.simulation.state == BattleSimV2.State.PREPARATION, "3D scene starts in preparation")
	battle._select_pad(0)
	check(battle.simulation.towers.is_empty(), "Selecting pad does not spend money")
	battle._purchase("archer")
	battle._physics_process(1.0 / 60.0)
	check(battle.simulation.coins == 130 and battle.tower_views.size() == 1, "Confirmed purchase creates matching 3D tower")
	battle._toggle_pause()
	var frozen: int = battle.simulation.ticks
	battle.simulation.advance(2.0)
	check(paused and battle.simulation.ticks == frozen, "Pause freezes world and simulation")
	battle._toggle_pause()
	battle._start_or_early()
	for index in range(7200):
		battle._physics_process(1.0 / 60.0)
	check(battle.simulation.kills > 0, "Real 3D controller resolves weapon damage")
	check(battle.enemy_views.size() == battle.simulation.enemies.size(), "Enemy presentation follows authoritative live entities")
	check(battle._wave_label.text.contains("10"), "HUD displays authored wave total")
	battle._toggle_speed()
	check(Engine.time_scale == 2.0 and battle._speed.text.contains("2×"), "Speed control activates two-times simulation")
	battle._toggle_speed()
	check(Engine.time_scale == 4.0 and battle._speed.text.contains("4×"), "Speed control offers four-times simulation")
	battle._toggle_speed()
	check(Engine.time_scale == 1.0 and battle._speed.text.contains("1×"), "Speed control cycles back to normal speed")
	battle._toggle_speed()
	battle.queue_free()
	await process_frame
	check(Engine.time_scale == 1.0 and not paused, "Scene exit restores global time and pause")
	print("P2 world integration: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

