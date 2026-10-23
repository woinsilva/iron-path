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
	var on_road: bool = false
	var pads_open: bool = true
	for index in range(1, 13):
		var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_%02d.json" % index)
		var sim: BattleSimV2 = StageSessionV2.create(stage)
		sim.coins = 99999
		for route in range(sim.routes.size()):
			if route in sim.air_routes: continue
			var road: Curve3D = sim.routes[route]
			var distance: float = 0.0
			while distance < road.get_baked_length():
				var point: Vector3 = road.sample_baked(distance)
				for side: float in [0.0, -0.9, 0.9]:
					if sim.can_build_at(point + Vector3(side, 0, side)): on_road = true
				distance += 0.5
		for pad: Vector3 in sim.pads: pads_open = pads_open and sim.can_build_at(pad)
	check(not on_road, "No stage accepts a tower on or beside any walking road")
	check(pads_open, "Every authored reference spot stays a legal free placement")
	var sim: BattleSimV2 = StageSessionV2.create(StageSessionV2.read_stage("res://data/campaign/stage_05.json"))
	var spot: Vector3 = sim.pads[4]
	var coins: int = sim.coins
	var pad: int = sim.build_at(spot, "archer")
	check(pad >= 0 and sim.tower_on_pad(pad) != null and sim.coins == coins - int(sim.catalog.towers.archer.levels[0].cost), "Building at a free spot charges the tower once and creates a usable slot")
	check(sim.build_at(spot + Vector3(0.6, 0, 0), "cannon") < 0 and not sim.can_build_at(spot + Vector3(0.6, 0, 0)), "Towers cannot be stacked on top of each other")
	sim.blocked_zones.append(Rect2(-2, -12, 1, 24))
	check(not sim.can_build_at(Vector3(-1.5, 0, 10.5)), "Blocked ground such as rivers refuses towers")
	check(not sim.can_build_at(Vector3(40, 0, 0)), "Towers stay inside the board")
	sim.coins = 0
	check(sim.build_at(sim.pads[6], "archer") < 0, "Free placement still requires the price")
	var air: BattleSimV2 = StageSessionV2.create(StageSessionV2.read_stage("res://data/campaign/stage_03.json"))
	var under_air: Vector3 = air.routes[1].sample_baked(air.routes[1].get_baked_length() * 0.3)
	var clear_of_ground: bool = air.routes[0].get_closest_point(under_air).distance_to(under_air) > 2.5
	check(not clear_of_ground or air.can_build_at(under_air), "Flight paths do not forbid building underneath")
	print("P12 placement: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
