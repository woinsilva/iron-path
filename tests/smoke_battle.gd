extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func make_battle() -> BattleManager:
	var battle: BattleManager = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	return battle

func run() -> void:
	var battle: BattleManager = make_battle()
	await process_frame
	check(battle.get_node("BattleHUD").battle_manager == battle, "HUD connects to battle before parent ready")
	var probe: Enemy = load("res://scenes/enemies/grunt.tscn").instantiate()
	battle.get_node("MapRoot/Map01/EnemyPath").add_child(probe)
	check(probe.health_bar.value == 10.0 and probe.health_bar.max_value == 10.0, "Health bar starts full")
	var visual: AnimatedSprite2D = probe.get_node("Sprite2D")
	check(visual.sprite_frames.get_frame_count("walk") == 4, "Walk atlas contains four frames")
	await create_timer(0.2).timeout
	check(probe.progress > 0.0 and visual.is_playing() and visual.frame > 0, "Walking animation advances with enemy movement")
	paused = true
	var paused_frame: int = visual.frame
	var paused_progress: float = probe.progress
	await create_timer(0.15, true).timeout
	check(visual.frame == paused_frame and probe.progress == paused_progress, "Pause freezes both animation and movement")
	paused = false
	probe.health_component.take_damage(5.0)
	check(probe.health_bar.value == 5.0, "Health bar tracks damage through health signal")
	probe.health_component.take_damage(50.0)
	check(probe.health_bar.value == 0.0, "Health bar clamps lethal damage to zero")
	probe.free()
	battle.coins = 150
	var pad: BuildPad = battle.get_node("MapRoot/Map01/Pads/BuildPad1")
	battle._on_pad_selected(pad)
	check(pad.state == BuildPad.PadState.BUILDING and battle.coins == 100, "Purchase debits once and starts construction")
	battle._on_pad_selected(pad)
	check(battle.coins == 100, "Repeated purchase does not debit twice")
	paused = true
	var progress: float = pad.current_build_time
	await create_timer(0.1, true).timeout
	check(pad.current_build_time == progress, "Pause freezes construction")
	paused = false
	Engine.time_scale = 12.0
	await create_timer(3.2).timeout
	check(pad.state == BuildPad.PadState.READY, "Construction completes and enables weapon")
	battle._on_pad_selected(battle.get_node("MapRoot/Map01/Pads/BuildPad2"))
	battle._on_pad_selected(battle.get_node("MapRoot/Map01/Pads/BuildPad3"))
	await create_timer(3.2).timeout
	battle.wave_manager.start_wave()
	var elapsed: float = 0.0
	while battle.wave_manager.current_state == WaveManager.State.WAVE_ACTIVE and elapsed < 80.0:
		await create_timer(0.5, true).timeout
		elapsed += 0.5
	check(battle.wave_manager.current_state == WaveManager.State.VICTORY, "Built defenses complete wave with victory")
	check(battle.get_node("BattleHUD").status_label.text == "VITÓRIA!", "Victory text preserves Portuguese UTF-8")
	check(battle.lives == 20 and battle.coins == 50, "All five enemies killed, reward exactly once, no leaks")
	check(get_nodes_in_group("enemies").is_empty(), "No surviving enemies after victory")
	paused = false
	battle.free()
	await process_frame
	battle = make_battle()
	await process_frame
	battle.wave_manager.start_wave()
	elapsed = 0.0
	while battle.wave_manager.current_state == WaveManager.State.WAVE_ACTIVE and elapsed < 80.0:
		await create_timer(0.5, true).timeout
		elapsed += 0.5
	check(battle.wave_manager.current_state == WaveManager.State.DEFEAT and battle.lives == 0, "Undefended enemies leak and cause defeat")
	check(battle.coins == 150, "Leaks award no coins")
	pad = battle.get_node("MapRoot/Map01/Pads/BuildPad1")
	battle._on_pad_selected(pad)
	check(not pad.has_tower() and battle.coins == 150, "Terminal state rejects purchases")
	paused = false
	battle.free()
	Engine.time_scale = 1.0
	await process_frame
	print("Integration failures: %d" % failures)
	quit(1 if failures else 0)
