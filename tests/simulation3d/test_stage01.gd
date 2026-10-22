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
	var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_01.json")
	check(stage.waves.size() == 10, "First stage contains ten authored waves")
	for strategy in range(3):
		var sim: BattleSimV2 = StageSessionV2.create(stage)
		if strategy < 2:
			sim.build(0, "archer")
			sim.build(1, "archer" if strategy == 0 else "cannon")
		sim.start_first_wave()
		var valid_economy: bool = true
		for index in range(72000):
			if sim._terminal():
				break
			if strategy < 2 and index % 30 == 0:
				for pad in range(2, 9):
					if sim.tower_on_pad(pad) == null:
						sim.build(pad, "archer" if pad % 3 != 2 else "cannon")
				for pad in range(9):
					sim.upgrade(pad)
			sim.step()
			valid_economy = valid_economy and sim.coins >= 0
			sim.consume_events()
		check(valid_economy, "Strategy %d never creates negative money" % strategy)
		if strategy < 2:
			check(sim.state == BattleSimV2.State.VICTORY, "Legal strategy %d wins without injected money" % strategy)
			check(sim.wave_index == 10 and sim.spawned == 106, "Strategy %d resolves all automatic waves" % strategy)
			check(sim.kills + sim.leaks == sim.spawned, "Strategy %d resolves every enemy once" % strategy)
		else:
			check(sim.state == BattleSimV2.State.DEFEAT, "No defense loses the first stage")
			check(sim.kills == 0 and sim.earned == 0, "Unopposed enemies grant no rewards")
		print("Stage strategy ", strategy, ": ", sim.summary())
	print("P3 stage: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
