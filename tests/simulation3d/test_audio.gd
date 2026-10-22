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
	var service: AudioServiceNode = root.get_node("AudioService") as AudioServiceNode
	service.play_vale()
	check(service._music.stream is AudioStreamOggVorbis and service._ambience.stream is AudioStreamOggVorbis, "Music and ambience load actual compressed audio streams")
	check(absf(service._music.stream.get_length() - 42.666667) < 0.02, "Vale theme preserves its authored sixteen-bar duration")
	check(absf(service._ambience.stream.get_length() - 12) < 0.02, "Ambience preserves its twelve-second loop")
	check((service._music.stream as AudioStreamOggVorbis).loop and (service._ambience.stream as AudioStreamOggVorbis).loop, "Both region streams loop continuously")
	service.set_bus_volume(AudioServiceNode.BUS_MUSIC, 0)
	check(service.get_bus_volume(AudioServiceNode.BUS_MUSIC) == 0, "Zero volume mutes the music bus")
	service.set_bus_volume(AudioServiceNode.BUS_MUSIC, 150)
	check(service.get_bus_volume(AudioServiceNode.BUS_MUSIC) == 100, "Volume clamps at the user-facing maximum")
	service.apply_settings({"music_volume": 35, "sfx_volume": 60})
	check(service.get_bus_volume(AudioServiceNode.BUS_MUSIC) == 35 and service.get_bus_volume(AudioServiceNode.BUS_SFX) == 60 and service.get_bus_volume(AudioServiceNode.BUS_UI) == 60, "Saved music and effect preferences control their actual buses")
	paused = true
	check(not service._music.can_process() and not service._ambience.can_process() and service.can_process(), "Pause suspends region playback nodes while preference controls remain available")
	paused = false
	check(service._music.can_process(), "Resume restores the region playback node")
	service.play_region("canyon")
	check(service._music.stream.resource_path.ends_with("canyon_theme.ogg") and absf(service._music.stream.get_length() - 48) < 0.02, "Canyon selects its distinct original forty-eight-second score")
	var canyon_stream: AudioStream = service._music.stream
	service.play_region("canyon")
	check(service._music.stream == canyon_stream, "Selecting the current biome preserves its configured stream")
	service.play_region("swamp")
	check(service._music.stream.resource_path.ends_with("swamp_theme.ogg") and absf(service._music.stream.get_length() - 40) < .02, "Swamp selects its original forty-second theme")
	check(service._ambience.stream.resource_path.ends_with("swamp_ambience.ogg"), "Swamp selects its own wind and insect ambience")
	service.play_vale()
	check(service._music.stream.resource_path.ends_with("vale_theme.ogg"), "Return to Vale restores the correct region theme")
	service.stop_music()
	check(service._music.stream == null and service._ambience.stream == null, "Stopping region audio releases owned stream references")
	print("P6 audio: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
