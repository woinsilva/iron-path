extends SceneTree
## Controlled benchmarks: targets have artificial HP, never campaign economy or win-rate claims.
const CASES: Array[String] = ["single", "armor", "resistance", "swarm", "air", "air_swarm", "control", "reach"]
var rows: Array[Dictionary] = []
func fixture(support_case: bool = false, scenario: String = "single") -> BattleSimV2:
	var route: Curve3D = Curve3D.new()
	route.add_point((Vector3(0, 0, 4.3) if support_case else Vector3(5.2, 0, 0)) if scenario == "reach" else (Vector3.ZERO if support_case else Vector3(3, 0, 0)))
	route.add_point(Vector3(100, 0, 0))
	return BattleSimV2.new(BattleSimV2.load_catalog(), [route], PackedVector3Array([Vector3.ZERO, Vector3(3, 0, 0), Vector3(-3, 0, 0), Vector3(0, 0, 3), Vector3(0, 0, -3)]), [], 100000, 100)
func tick(sim: BattleSimV2, count: int) -> void:
	for index in range(count): sim.step()
func build(sim: BattleSimV2, family: String, level: int, branch: String, pad: int = 0) -> SimTowerV2:
	sim.build(pad, family)
	var tower: SimTowerV2 = sim.tower_on_pad(pad)
	tick(sim, tower.work_ticks)
	for next in range(2, level + 1):
		sim.upgrade(pad, branch if next == 4 else "")
		tick(sim, tower.work_ticks)
	return tower
func measure(family: String, level: int, branch: String, scenario: String) -> Dictionary:
	var support_case: bool = family == "banner"
	var sim: BattleSimV2 = fixture(support_case, scenario)
	var tower: SimTowerV2 = build(sim, family, level, branch)
	if support_case:
		for pad in range(1, 5): build(sim, "archer", 3, "", pad)
	var count: int = 12 if scenario in ["swarm", "air_swarm", "control", "reach"] else 1
	for index in range(count):
		var enemy: SimEnemyV2 = sim.spawn_enemy("flyer" if scenario in ["air", "air_swarm"] else "grunt")
		enemy.health = 100000
		enemy.maximum_health = 100000
		enemy.speed = 0.2 if scenario == "control" else 0
		enemy.armor = 18 if scenario == "armor" else 0
		enemy.magic_resistance = 0.6 if scenario == "resistance" else 0
		enemy.distance = index * 0.38
		enemy.position = sim.routes[0].sample_baked(enemy.distance)
	var start: int = sim.ticks
	tick(sim, 720)
	var row: Dictionary = {"family": family, "level": level, "branch": branch, "case": scenario, "investment": tower.investment, "seconds": float(sim.ticks - start) / 60, "useful_damage": sim.useful_damage, "dps": sim.useful_damage / 12, "control_delay_seconds": sim.control_delay, "supported_attacks": tower.supported_attacks, "damage_per_100_coins": sim.useful_damage / maxi(1, tower.investment) * 100}
	return row
func _initialize() -> void:
	for family: String in BattleSimV2.load_catalog().towers:
		for level in range(1, 4):
			for scenario: String in CASES: rows.append(measure(family, level, "", scenario))
		for branch: String in ["A", "B"]:
			for level in [4, 5]:
				for scenario: String in CASES: rows.append(measure(family, level, branch, scenario))
	var report: Dictionary = {"note": "Controlled artificial targets, twelve simulation seconds. Not a campaign win-rate, human playtest or device benchmark. Support rows include four L3 archers; compare support configurations to each other, not directly with isolated damage towers.", "rows": rows}
	var file: FileAccess = FileAccess.open("res://test-results/arsenal-reference.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("ARSENAL_REFERENCE_CASES ", rows.size())
	for row: Dictionary in rows:
		if int(row.level) == 5 and str(row.case) in ["single", "swarm", "air", "air_swarm", "control", "reach"]:
			print("REFERENCE ", JSON.stringify(row))
	quit()
