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
	for index in [1,5,9,10,11,12]:
		var battle: BattleViewV2 = BattleViewV2.new()
		battle.stage_path = "res://data/campaign/stage_%02d.json" % index
		root.add_child(battle)
		current_scene = battle
		battle.set_physics_process(false)
		var verge: MultiMeshInstance3D = battle.diorama.get_node("RoadVergeStones") as MultiMeshInstance3D
		check(verge.multimesh.instance_count >= 20, "Stage %02d batches roadside detail into real instanced geometry" % index)
		if index >= 9:
			var hero: Node3D = battle.diorama.get_node("SwampLandmark%d" % index) as Node3D
			var clear: bool = battle.diorama._distance_from_route(hero.position) > 4 and not battle.diorama._is_reserved(hero.position,4)
			check(clear, "Stage %02d has its own exterior landmark outside roads and tower bases" % index)
		if index == 5:
			var center: Vector3 = battle.diorama.bridge_centers[0]
			var low: float = battle.diorama.walk_surface_height(center + Vector3(0,0,2.5))
			var middle: float = battle.diorama.walk_surface_height(center + Vector3(0,0,2.1))
			var high: float = battle.diorama.walk_surface_height(center)
			check(low < middle and middle < high and is_equal_approx(high,.2), "Bridge entry rises continuously to its actual deck height")
		await process_frame
		var phase: float = float(battle.diorama._water_surface.get_shader_parameter("phase"))
		paused = true
		for frame in range(3): await process_frame
		check(float(battle.diorama._water_surface.get_shader_parameter("phase")) == phase, "Stage %02d freezes water motion during pause" % index)
		paused = false
		battle.queue_free()
		await process_frame
	print("P9 scenery: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
