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
	for dimensions: Vector2i in [Vector2i(1920,1080),Vector2i(2400,1080)]:
		root.size = dimensions
		for index in range(1,13):
			var battle: BattleViewV2 = BattleViewV2.new()
			battle.stage_path = "res://data/campaign/stage_%02d.json" % index
			battle.stage = StageSessionV2.read_stage(battle.stage_path)
			battle.stage.allowed_towers = (battle.stage.allowed_towers as Array).slice(0,5)
			root.add_child(battle)
			current_scene = battle
			battle.set_physics_process(false)
			await process_frame
			await process_frame
			var clear: bool = true
			var boss_clear: bool = true
			var viewport: Rect2 = root.get_visible_rect()
			var top_bottom: float = (battle._next_wave.get_parent() as Control).get_global_rect().end.y
			var bottom_top: float = (battle._context.get_parent() as Control).get_global_rect().position.y
			for pad: Vector3 in battle.simulation.pads:
				var point: Vector2 = battle.diorama.camera.unproject_position(pad)
				clear = clear and point.y - 30 > top_bottom and point.y + 30 < bottom_top and point.x > 35 and point.x < viewport.size.x - 35
				if index in [4,8,12]: boss_clear = boss_clear and not battle._boss_panel.get_global_rect().intersects(Rect2(point - Vector2(35,30), Vector2(70,60)))
			check(clear and boss_clear, "Stage %02d keeps every build base clear of HUD and boss panel at %d:%d" % [index,dimensions.x,dimensions.y])
			battle.queue_free()
			await process_frame
	print("P9 framing: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
