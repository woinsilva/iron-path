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
	call_deferred("run")
func run() -> void:
	var audio: AudioServiceNode = root.get_node("AudioService") as AudioServiceNode
	check(audio._voices.size() == 12 and audio._ui_voice.max_polyphony == 2, "Combat has twelve reusable voices and an independent bounded UI player")
	var valid_assets: bool = true
	for cue: String in AudioServiceNode.CUES:
		var stream: AudioStreamWAV = audio._load_cue(cue)
		valid_assets = valid_assets and stream != null and stream.get_length() > .05 and stream.get_length() < 1 and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED
	check(valid_assets and audio._cue_cache.size() == 14, "All fourteen original cues load as finite non-looping resources")
	check(not audio.play_event("not_a_cue"), "Unknown cues cannot allocate a voice")
	if DisplayServer.get_name() == "headless":
		check(not audio.play_event("cannon"), "Headless tests validate assets without creating dummy device playback")
	else:
		audio.set_bus_volume(AudioServiceNode.BUS_SFX, 100)
		audio.set_bus_volume(AudioServiceNode.BUS_UI, 100)
		var accepted: int = 0
		for index in range(12): accepted += int(audio.play_event(AudioServiceNode.CUES[index]))
		check(accepted == 12 and not audio.play_event("shield_break"), "A combat burst respects the actual twelve-voice hardware playback cap")
		check(audio.play_event("ui", AudioServiceNode.BUS_UI), "A saturated combat mix cannot starve an interface click")
		check(not audio.play_event("ui", AudioServiceNode.BUS_UI), "Immediate duplicate UI requests are rate limited")
	paused = true
	var frozen: bool = true
	for voice: AudioStreamPlayer in audio._voices: frozen = frozen and not voice.can_process()
	check(frozen and audio._ui_voice.can_process(), "Pause suspends combat cues while pause-menu feedback remains available")
	paused = false
	audio.stop_sfx()
	var released: bool = audio._ui_voice.stream == null
	for voice: AudioStreamPlayer in audio._voices: released = released and voice.stream == null
	check(released, "Stopping combat releases every owned stream reference")
	audio.set_bus_volume(AudioServiceNode.BUS_SFX, 0)
	check(not audio.play_event("cannon"), "Muted effects cannot create playback")
	await audio.shutdown()
	print("P7 SFX: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
