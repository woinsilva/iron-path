extends Node
const STAGE_INDEX: int = 3
const READ_EXISTING_REPORT: bool = false
const MAX_WALL_SECONDS: float = 0
## Legal full-stage automated play; separate APK/package and no campaign save writes.
var battle: BattleViewV2
var _last_purchase_tick: int = -30
var _last_wall: int
var _started_wall: int
var _samples: Array[float] = []
var _slow_frames: Array[Dictionary] = []
var _peak_enemies: int = 0
var _peak_memory: int = 0
var _last_wave: int = -1
var _finished: bool = false
var _plan: Array[String] = ["archer", "cannon", "anti_air", "frost", "venom", "cannon", "archer", "frost", "anti_air"]
func _ready() -> void:
	if READ_EXISTING_REPORT:
		_finished = true
		var stored: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://benchmark.json")) as Dictionary
		print("IRON_REPORT_META ", JSON.stringify(_compact_report(stored)))
		for frame: Dictionary in stored.get("slow_frames", []): print("IRON_SLOW_FRAME ", JSON.stringify(frame))
		get_tree().quit()
		return
	Engine.max_fps = 60
	Engine.time_scale = 2
	battle = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_%02d.json" % STAGE_INDEX
	if STAGE_INDEX == 8:
		battle.stage = StageSessionV2.read_stage(battle.stage_path)
		battle.stage.allowed_towers = ["cannon", "arcane", "frost", "anti_air", "banner"]
		_plan = ["cannon", "cannon", "arcane", "arcane", "frost", "cannon", "frost", "arcane", "cannon", "arcane", "cannon", "frost", "banner", "anti_air"]
	if STAGE_INDEX == 12:
		battle.stage = StageSessionV2.read_stage(battle.stage_path)
		battle.stage.allowed_towers = ["cannon", "bleed", "frost", "banner", "anti_air"]
		_plan = ["cannon", "cannon", "cannon", "bleed", "frost", "cannon", "frost", "banner", "cannon", "anti_air", "cannon", "bleed", "bleed", "anti_air"]
	battle.battle_completed.connect(_completed)
	add_child(battle)
	battle.apply_graphics_profile("balanced")
	if STAGE_INDEX == 8:
		for pad in [1, 7, 6, 12, 13]: battle.simulation.build(pad, _plan[pad])
		(get_node("/root/AudioService") as AudioServiceNode).play_region("canyon")
	elif STAGE_INDEX == 12:
		for pad in [2, 6, 7, 12, 13]: battle.simulation.build(pad, _plan[pad])
		(get_node("/root/AudioService") as AudioServiceNode).play_region("swamp")
	else:
		battle.simulation.build(0, _plan[0])
		battle.simulation.build(1, _plan[1])
	_started_wall = Time.get_ticks_usec()
	_last_wall = _started_wall
	print("IRON_BENCHMARK_START stage%02d normal balanced Vulkan Mobile; emulator host metrics" % STAGE_INDEX)
func _physics_process(_delta: float) -> void:
	if _finished: return
	var sim: BattleSimV2 = battle.simulation
	if STAGE_INDEX == 8:
		if sim.state == BattleSimV2.State.PREPARATION: _prepare_forge(sim)
		elif sim.ticks - _last_purchase_tick >= 30:
			_last_purchase_tick = sim.ticks
			_manage_forge(sim)
	elif STAGE_INDEX == 12:
		if sim.state == BattleSimV2.State.PREPARATION: _prepare_swamp(sim)
		elif sim.ticks - _last_purchase_tick >= 30:
			_last_purchase_tick = sim.ticks
			_manage_swamp(sim)
	else:
		if sim.ticks - _last_purchase_tick >= 30:
			_last_purchase_tick = sim.ticks
			for pad in range(2, 9):
				if sim.tower_on_pad(pad) == null:
					if not sim.build(pad, _plan[pad]): break
			for pad in range(9): sim.upgrade(pad)
		if sim.state == BattleSimV2.State.PREPARATION and sim.ticks >= 360:
			sim.start_first_wave()
	if sim.wave_index != _last_wave:
		_last_wave = sim.wave_index
		print("IRON_BENCHMARK_WAVE ", JSON.stringify(sim.summary()))
	_peak_enemies = maxi(_peak_enemies, sim.enemies.size())
	_peak_memory = maxi(_peak_memory, OS.get_static_memory_usage())
func _process(_delta: float) -> void:
	if _finished: return
	var now: int = Time.get_ticks_usec()
	if now - _started_wall > 10000000:
		var frame_ms: float = float(now - _last_wall) / 1000.0
		_samples.append(frame_ms)
		if frame_ms > 33.4 and _slow_frames.size() < 80:
			_slow_frames.append({"ms":frame_ms,"tick":battle.simulation.ticks,"wave":battle.simulation.wave_index,"enemies":battle.simulation.enemies.size(),"state":battle.simulation.state})
	_last_wall = now
	if MAX_WALL_SECONDS > 0 and float(now - _started_wall) / 1000000 >= MAX_WALL_SECONDS:
		_completed(battle.simulation.summary())
func _completed(result: Dictionary) -> void:
	_finished = true
	_samples.sort()
	var report: Dictionary = result.duplicate(true)
	report.completed_full_stage = battle.simulation.state == BattleSimV2.State.VICTORY
	report.sample_window = "startup" if MAX_WALL_SECONDS > 0 else "full_stage"
	report.stage_index = STAGE_INDEX
	report.wall_seconds = float(Time.get_ticks_usec() - _started_wall) / 1000000
	report.frames_measured = _samples.size()
	report.frame_ms_median = _samples[int(_samples.size() * 0.5)] if not _samples.is_empty() else 0
	report.frame_ms_p95 = _samples[mini(_samples.size() - 1, int(_samples.size() * 0.95))] if not _samples.is_empty() else 0
	report.frame_ms_p99 = _samples[mini(_samples.size() - 1, int(_samples.size() * 0.99))] if not _samples.is_empty() else 0
	report.frame_ms_max = _samples.back() if not _samples.is_empty() else 0
	report.slow_frames = _slow_frames
	report.peak_enemies = _peak_enemies
	report.peak_static_memory_bytes = _peak_memory
	report.adapter = RenderingServer.get_video_adapter_name()
	report.platform = OS.get_name()
	report.note = "Emulator uses PC GPU. This is not Galaxy S23 Ultra certification."
	var file: FileAccess = FileAccess.open("user://benchmark.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("IRON_BENCHMARK_COMPLETE ", JSON.stringify(_compact_report(report)))
	for frame: Dictionary in _slow_frames: print("IRON_SLOW_FRAME ", JSON.stringify(frame))
	battle._result_body.text += "\nEnsaio automático concluído; métricas registradas no log."

func _prepare_forge(sim: BattleSimV2) -> void:
	if sim.ticks >= 2580: sim.start_first_wave()
	elif sim.ticks >= 1860:
		if sim.tower_on_pad(1).level < 2: sim.upgrade(1)
	elif sim.ticks >= 1140:
		if sim.tower_on_pad(7).level < 3: sim.upgrade(7)
	elif sim.ticks >= 420:
		if sim.tower_on_pad(7).level < 2: sim.upgrade(7)

func _manage_forge(sim: BattleSimV2) -> void:
	if sim.wave_index == 20:
		for tower: SimTowerV2 in sim.towers.values():
			if tower.type_id in ["arcane", "cannon"]: tower.priority = "strongest"
	if (sim.wave_index == 19 and sim.state == BattleSimV2.State.INTERMISSION) or sim.wave_index == 20:
		var focus: SimTowerV2 = sim.tower_on_pad(3)
		if focus == null: sim.build(3, "arcane")
		elif focus.level < 4: sim.upgrade(3, "A" if focus.level == 3 else "")
		else:
			var second: SimTowerV2 = sim.tower_on_pad(2)
			if second != null and second.level < 3: sim.upgrade(2)
	else:
		var core_ready: bool = true
		for target_level in [2, 3]:
			for priority_pad in [7, 1, 13, 6]:
				var tower: SimTowerV2 = sim.tower_on_pad(priority_pad)
				if tower.level < target_level:
					core_ready = false
					sim.upgrade(priority_pad)
					break
			if not core_ready: break
		if core_ready and sim.tower_on_pad(13).level < 4:
			if sim.state == BattleSimV2.State.INTERMISSION: sim.upgrade(13, "A")
			core_ready = false
		if core_ready and sim.tower_on_pad(7).level < 4:
			if sim.state == BattleSimV2.State.INTERMISSION: sim.upgrade(7, "A")
			core_ready = false
		if core_ready and sim.tower_on_pad(1).level < 4:
			if sim.state == BattleSimV2.State.INTERMISSION: sim.upgrade(1, "B")
			core_ready = false
		if core_ready and sim.wave_index < 17:
			for pad in range(_plan.size()):
				if sim.tower_on_pad(pad) == null and not sim.build(pad, _plan[pad]): break
			for pad in range(_plan.size()):
				var tower: SimTowerV2 = sim.tower_on_pad(pad)
				if tower != null: sim.upgrade(pad, ("A") if tower.level >= 3 else "")

func _prepare_swamp(sim: BattleSimV2) -> void:
	if sim.ticks >= 2580: sim.start_first_wave()
	elif sim.ticks >= 1860:
		if sim.tower_on_pad(12).level < 2: sim.upgrade(12)
	elif sim.ticks >= 1140:
		if sim.tower_on_pad(2).level < 3: sim.upgrade(2)
	elif sim.ticks >= 420:
		if sim.tower_on_pad(2).level < 2: sim.upgrade(2)

func _manage_swamp(sim: BattleSimV2) -> void:
	var pending: bool = false
	for level in [2, 3, 4]:
		for pad in [13, 2, 12, 6]:
			var tower: SimTowerV2 = sim.tower_on_pad(pad)
			if tower.level < level:
				pending = true
				sim.upgrade(pad, ("A" if pad == 13 else "B") if tower.level >= 3 else "")
				break
		if pending: break
	if not pending:
		for pad in [2, 13, 12]:
			var focus: SimTowerV2 = sim.tower_on_pad(pad)
			if focus.level < 5:
				pending = true
				sim.upgrade(pad)
				break
	if not pending:
		for pad in range(_plan.size()):
			if sim.tower_on_pad(pad) == null and not sim.build(pad, _plan[pad]): break
		for pad in range(_plan.size()):
			var tower: SimTowerV2 = sim.tower_on_pad(pad)
			if tower != null: sim.upgrade(pad, "A" if tower.level >= 3 else "")

func _compact_report(report: Dictionary) -> Dictionary:
	var compact: Dictionary = report.duplicate(true)
	compact.erase("slow_frames")
	return compact
