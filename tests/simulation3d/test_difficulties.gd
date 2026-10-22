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
	var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_01.json")
	var original: Dictionary = stage.duplicate(true)
	var normal: BattleSimV2 = StageSessionV2.create(stage)
	var adventure: BattleSimV2 = StageSessionV2.create(stage, "adventure")
	var veteran: BattleSimV2 = StageSessionV2.create(stage, "veteran")
	check(normal.coins == 200 and normal.lives == 20 and normal.catalog.enemies.grunt.hp == 70 and normal.waves[0].interval == 8, "Normal keeps its tested budget health and authored intervals")
	check(adventure.coins == 230 and adventure.lives == 25 and adventure.catalog.enemies.grunt.hp == 60 and adventure.waves[0].interval == 10, "Adventure keeps its original assistance profile")
	check(veteran.coins == normal.coins and veteran.lives == 20 and veteran.catalog.enemies.grunt.hp == 76 and veteran.waves[0].interval == 6, "Veteran uses the revised threat profile without added money")
	check(is_equal_approx(veteran.catalog.enemies.grunt.speed, 1.428), "Veteran speed increase matches its declared two percent")
	check(stage == original and normal.catalog.enemies.grunt.hp == 70, "Difficulty creation cannot mutate authored stages or another difficulty session")
	var later: BattleSimV2 = StageSessionV2.create(StageSessionV2.read_stage("res://data/campaign/stage_09.json"), "veteran")
	check(later.catalog.towers.cannon.branches.A.levels.size() == 2 and later.coins == 1500, "Veteran retains real campaign level five choices and integer budget")
	print("P8 difficulties: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
