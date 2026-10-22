## Approved autoload: local buses, region music and bounded sound playback.
class_name AudioServiceNode extends Node
const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_UI: StringName = &"UI"
const MAX_COMBAT_SFX: int = 12
const CUES: Array[String] = ["ui", "archer", "cannon", "frost", "venom", "anti_air", "bleed", "arcane", "banner", "impact", "heal", "rally", "shield_break", "summon"]
var _voices: Array[AudioStreamPlayer] = []
var _ui_voice: AudioStreamPlayer
var _cue_cache: Dictionary = {}
var _cue_due: Dictionary = {}
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus: StringName in [BUS_MUSIC, BUS_SFX, BUS_UI]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, BUS_MASTER)
	_music = AudioStreamPlayer.new()
	_music.bus = BUS_MUSIC
	_music.volume_db = -18
	_music.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_music)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = BUS_MUSIC
	_ambience.volume_db = -12
	_ambience.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_ambience)
	for index in range(MAX_COMBAT_SFX):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = BUS_SFX
		voice.volume_db = -18
		voice.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(voice)
		_voices.append(voice)
	_ui_voice = AudioStreamPlayer.new()
	_ui_voice.bus = BUS_UI
	_ui_voice.volume_db = -18
	_ui_voice.max_polyphony = 2
	_ui_voice.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui_voice)
func apply_settings(settings: Dictionary) -> void:
	set_bus_volume(BUS_MUSIC, int(settings.get("music_volume", 100)))
	set_bus_volume(BUS_SFX, int(settings.get("sfx_volume", 100)))
	set_bus_volume(BUS_UI, int(settings.get("sfx_volume", 100)))
func play_vale() -> void:
	play_region("vale")
func play_region(region: String) -> void:
	var prefix: String = region if region in ["canyon", "swamp"] else "vale"
	var theme_path: String = "res://art/audio/" + prefix + "_theme.ogg"
	if _music.stream != null and _music.stream.resource_path == theme_path: return
	stop_music()
	var theme: AudioStreamOggVorbis = load(theme_path) as AudioStreamOggVorbis
	var ambience: AudioStreamOggVorbis = load("res://art/audio/" + prefix + "_ambience.ogg") as AudioStreamOggVorbis
	theme.loop = true
	ambience.loop = true
	_music.stream = theme
	_ambience.stream = ambience
	# Headless runs validate configured streams without creating device playback.
	if DisplayServer.get_name() != "headless":
		_music.play()
		_ambience.play()
func stop_music() -> void:
	_music.stop()
	_ambience.stop()
	_music.stream = null
	_ambience.stream = null
func set_bus_volume(bus_name: StringName, volume_percent: int) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	assert(index >= 0, "Audio bus must exist before changing its volume")
	var value: int = clampi(volume_percent, 0, 100)
	AudioServer.set_bus_mute(index, value == 0)
	if value > 0: AudioServer.set_bus_volume_db(index, linear_to_db(value / 100.0))
func get_bus_volume(bus_name: StringName) -> int:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0 or AudioServer.is_bus_mute(index): return 0
	return roundi(db_to_linear(AudioServer.get_bus_volume_db(index)) * 100)

func _exit_tree() -> void:
	if is_instance_valid(_music) and is_instance_valid(_ambience): stop_music()
	stop_sfx()

func shutdown() -> void:
	stop_music()
	stop_sfx()
	if DisplayServer.get_name() == "headless": return
	# Let the audio thread consume stop commands and release its previous playback.
	# Driver timing is queried once at shutdown, never on the per-frame path.
	var drain: float = 2.0 * maxf(1.0 / AudioServer.get_mix_rate(), AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency())
	await get_tree().create_timer(drain, true, false, true).timeout

func _load_cue(cue: String) -> AudioStreamWAV:
	if not _cue_cache.has(cue): _cue_cache[cue] = load("res://art/audio/sfx/" + cue + ".wav") as AudioStreamWAV
	return _cue_cache[cue] as AudioStreamWAV
func play_event(cue: String, bus: StringName = BUS_SFX) -> bool:
	if cue not in CUES or bus not in [BUS_SFX, BUS_UI] or DisplayServer.get_name() == "headless": return false
	if AudioServer.is_bus_mute(AudioServer.get_bus_index(bus)): return false
	var now: int = Time.get_ticks_msec()
	var key: String = cue + str(bus)
	if now < int(_cue_due.get(key, -1)): return false
	var voice: AudioStreamPlayer = _ui_voice if bus == BUS_UI else null
	if voice == null:
		for candidate: AudioStreamPlayer in _voices:
			if not candidate.playing:
				voice = candidate
				break
	if voice == null: return false
	voice.stream = _load_cue(cue)
	voice.play()
	_cue_due[key] = now + (150 if cue in ["rally", "heal", "shield_break", "summon"] else 75)
	return true
func stop_sfx() -> void:
	for voice: AudioStreamPlayer in _voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	if is_instance_valid(_ui_voice):
		_ui_voice.stop()
		_ui_voice.stream = null
