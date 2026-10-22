class_name CampaignAppV2 extends Node
var _shutting_down: bool = false
var _audio: AudioServiceNode
var _audio_save_timer: Timer
var _save: SaveServiceNode
var progress: Dictionary
var battle: BattleViewV2
var menu: CanvasLayer
var difficulty: String = "normal"
var selected_stage_path: String = "res://data/campaign/stage_01.json"
var _status: Label
var _theme: Theme
var _bold_font: FontVariation
var _intro: Control
const GOLD: Color = Color("ecd49a")
const MUTED: Color = Color("b0c6c5")
const INTRO_VIDEO: String = "res://art/branding/intro_logo.ogv"
## Safety net in case the video never reports completion; the clip itself runs 5.6 s.
const INTRO_TIMEOUT: float = 12.0
func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	get_tree().root.go_back_requested.connect(_handle_back)
	_save = get_node("/root/SaveService") as SaveServiceNode
	progress = _save.load_game()
	_audio = get_node("/root/AudioService") as AudioServiceNode
	_audio.apply_settings(progress.settings)
	_audio.play_vale()
	_audio_save_timer = Timer.new()
	_audio_save_timer.wait_time = 0.35
	_audio_save_timer.one_shot = true
	_audio_save_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_audio_save_timer)
	_audio_save_timer.timeout.connect(_save_audio_preferences)
	_show_menu()
	_play_intro()
## Studio logo shown once at launch over the already-built menu; any click, touch or key skips it.
func _play_intro() -> void:
	if DisplayServer.get_name() == "headless" or not ResourceLoader.exists(INTRO_VIDEO): return
	var stream: VideoStream = load(INTRO_VIDEO) as VideoStream
	if stream == null: return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "IntroLayer"
	layer.layer = 100
	add_child(layer)
	_intro = Control.new()
	_intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(_intro)
	var black: ColorRect = ColorRect.new()
	black.color = Color.BLACK
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro.add_child(black)
	var frame: AspectRatioContainer = AspectRatioContainer.new()
	frame.ratio = 16.0 / 9.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro.add_child(frame)
	var player: VideoStreamPlayer = VideoStreamPlayer.new()
	player.stream = stream
	player.expand = true
	player.bus = AudioServiceNode.BUS_MUSIC
	player.volume_db = -4.0
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(player)
	player.finished.connect(_finish_intro)
	_intro.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed(): _finish_intro()
	)
	_audio.stop_music()
	# The first frames stall on menu construction and shader warm-up; starting before they are drawn skips the opening.
	for _frame: int in range(2): await RenderingServer.frame_post_draw
	if not is_instance_valid(_intro): return
	player.play()
	get_tree().create_timer(INTRO_TIMEOUT).timeout.connect(_finish_intro)
func _finish_intro() -> void:
	if not is_instance_valid(_intro): return
	var fading: Control = _intro
	_intro = null
	fading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween()
	tween.tween_property(fading, "modulate:a", 0.0, 0.6)
	tween.tween_callback(fading.get_parent().queue_free)
	_audio.play_vale()
func _show_menu() -> void:
	_audio.play_vale()
	_audio.stop_sfx()
	get_tree().paused = false
	Engine.time_scale = 1.0
	if is_instance_valid(battle):
		battle.queue_free()
		battle = null
	if is_instance_valid(menu):
		menu.queue_free()
	menu = CanvasLayer.new()
	add_child(menu)
	var root: Control = _backdrop(menu)
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.3)
	var margin: MarginContainer = _margin(root, 56)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var gutter: MarginContainer = MarginContainer.new()
	gutter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gutter.add_theme_constant_override("margin_right", 28)
	scroll.add_child(gutter)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 28)
	gutter.add_child(column)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 32)
	column.add_child(header)
	var emblem: TextureRect = TextureRect.new()
	emblem.texture = load("res://art/branding/icon.png") as Texture2D
	emblem.custom_minimum_size = Vector2(150, 150)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(emblem)
	var titles: VBoxContainer = VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.add_theme_constant_override("separation", 2)
	header.add_child(titles)
	var title: Label = _text(titles, "IRON PATH", 84, GOLD)
	title.add_theme_font_override("font", _heading_font())
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color("06161a"))
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	_text(titles, "Guardiões do caminho", 34, Color("d9e4dc"))
	_text(column, "Construa, evolua e combine sua defesa. A primeira onda é sua escolha; as demais chegam sozinhas.", 26, MUTED)
	var choices: HBoxContainer = HBoxContainer.new()
	choices.add_theme_constant_override("separation", 18)
	column.add_child(choices)
	_text(choices, "Dificuldade", 28, MUTED).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for pair: Array in [["adventure", "Aventura"], ["normal", "Normal"], ["veteran", "Veterano"]]:
		var key: String = pair[0]
		var button: Button = _button(choices, str(pair[1]) + ("  ✓" if difficulty == key else ""), func() -> void: difficulty = key; _show_menu())
		button.toggle_mode = true
		button.set_pressed_no_signal(difficulty == key)
		button.custom_minimum_size = Vector2(260, 80)
		button.tooltip_text = "Mais recursos e tempo" if key == "adventure" else ("Inimigos com 8% mais vida e 2% mais velocidade; intervalos de 6 s" if key == "veteran" else "Dificuldade de referência")
	var outcome: String = ""
	var outcome_body: String = ""
	if stage_unlocked(13):
		outcome = "OS TRÊS CAMINHOS PROTEGIDOS"
		outcome_body = "O Guardião da Ruína caiu. Experimente outras formações ou uma dificuldade maior."
	elif stage_unlocked(9):
		outcome = "GARGANTA RUBRA PROTEGIDA"
		outcome_body = "A Forja silenciou. As ruínas do Pântano Sombrio guardam o último caminho."
	elif stage_unlocked(5):
		outcome = "VALE VERDE PROTEGIDO"
		outcome_body = "O Capitão caiu. Além do portão, as pontes da Garganta Rubra exigirão novas combinações e especializações."
	if not outcome.is_empty():
		var banner: VBoxContainer = _card(column, GOLD)
		_text(banner, outcome, 34, GOLD).add_theme_font_override("font", _heading_font())
		_text(banner, outcome_body, 26)
	for biome: Array in [["VALE VERDE", Color("a8c3ac"), 1], ["GARGANTA RUBRA", Color("ce9b75"), 5], ["PÂNTANO SOMBRIO", Color("b6a0ce"), 9]]:
		var accent: Color = biome[1]
		var region: VBoxContainer = _card(column, accent)
		_text(region, str(biome[0]), 34, accent).add_theme_font_override("font", _heading_font())
		var grid: GridContainer = GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 18)
		grid.add_theme_constant_override("v_separation", 18)
		region.add_child(grid)
		for index in range(int(biome[2]), int(biome[2]) + 4):
			var path: String = "res://data/campaign/stage_%02d.json" % index
			var stage: Dictionary = StageSessionV2.read_stage(path)
			var best: Dictionary = progress.progress.campaign.get(str(stage.id) + ":" + difficulty, {})
			var stars: int = int(best.get("stars", 0))
			var available: bool = stage_unlocked(index)
			var cell: VBoxContainer = VBoxContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_theme_constant_override("separation", 6)
			grid.add_child(cell)
			var stage_button: Button = _button(cell, "%02d   %s\n%s" % [index, str(stage.name), "★".repeat(stars) + "☆".repeat(3 - stars) if available else "Bloqueada"], func() -> void: _prepare_stage(path))
			stage_button.name = "Stage_%02d" % index
			stage_button.custom_minimum_size = Vector2(0, 124)
			stage_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			stage_button.disabled = not available
			stage_button.tooltip_text = "Conclua a fase anterior em uma dificuldade para abrir este caminho." if not available else ""
			if stars > 0: stage_button.add_theme_color_override("font_color", Color("f6e3ad"))
			_text(cell, "%d ondas • %d famílias • Nível %d" % [stage.waves.size(), stage.allowed_towers.size(), int(stage.max_level)], 21, MUTED)
	_text(column, "Toque numa base de pedra e confirme a torre. Amplie a cobertura e melhore sua defesa durante os intervalos.", 25, MUTED)
	var optional: Array = StageSessionV2.read_stage("res://data/campaign/challenges.json").challenges
	var challenge_card: VBoxContainer = null
	for challenge: Dictionary in optional:
		var challenge_stage: int = int(challenge.stage)
		if not stage_unlocked(challenge_stage + 1): continue
		if challenge_card == null:
			challenge_card = _card(column, GOLD)
			_text(challenge_card, "DESAFIOS OPCIONAIS", 32, GOLD).add_theme_font_override("font", _heading_font())
			_text(challenge_card, "Revisite os finais dos biomas. Os desafios usam as regras da fase e seus recordes; não são necessários para avançar.", 25, MUTED)
		var completed: bool = challenge_completed(challenge)
		var replay_path: String = "res://data/campaign/stage_%02d.json" % challenge_stage
		var replay: Button = _button(challenge_card, str(challenge.name) + ("  ✓" if completed else ""), func() -> void: _prepare_stage(replay_path))
		replay.name = "Challenge_" + str(challenge.id)
		_text(challenge_card, str(challenge.description), 24)
	var extras: HBoxContainer = HBoxContainer.new()
	extras.add_theme_constant_override("separation", 18)
	column.add_child(extras)
	_button(extras, "Laboratório do Arsenal", func() -> void: _prepare_stage("res://data/campaign/arsenal_lab.json")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(extras, "Guia de torres e inimigos", _show_guide).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var settings: VBoxContainer = _card(column, Color("6f9a9c"))
	_text(settings, "AJUSTES", 32, Color("a8c3ac")).add_theme_font_override("font", _heading_font())
	var graphics: OptionButton = OptionButton.new()
	graphics.custom_minimum_size = Vector2(300, 88)
	graphics.add_theme_font_size_override("font_size", 30)
	for label: String in ["Gráficos: Economia", "Gráficos: Equilibrado", "Gráficos: Qualidade"]: graphics.add_item(label)
	var profiles: Array[String] = ["economy", "balanced", "quality"]
	graphics.select(profiles.find(str(progress.settings.get("graphics_profile", "balanced"))))
	graphics.item_selected.connect(func(index: int) -> void:
		progress.settings.graphics_profile = profiles[index]
		if not _save.save_game(progress): _status.text = "Não foi possível salvar a preferência gráfica."
	)
	settings.add_child(graphics)
	for entry: Array in [["music_volume", "Música e ambiente"], ["sfx_volume", "Efeitos e interface"]]:
		var setting: String = entry[0]
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		settings.add_child(row)
		var caption: Label = _text(row, str(entry[1]), 26, Color("a8c3ac"))
		caption.custom_minimum_size = Vector2(340, 0)
		var slider: HSlider = HSlider.new()
		slider.custom_minimum_size = Vector2(400, 64)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = int(progress.settings.get(setting, 100))
		row.add_child(slider)
		var readout: Label = _text(row, "%d%%" % int(slider.value), 26)
		readout.custom_minimum_size = Vector2(90, 0)
		slider.value_changed.connect(func(value: float) -> void:
			progress.settings[setting] = int(value)
			readout.text = "%d%%" % int(value)
			_audio.apply_settings(progress.settings)
			_audio_save_timer.start()
		)
	_status = _text(column, "", 25, GOLD)
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 24)
	column.add_child(footer)
	_button(footer, "Créditos e licenças", _show_credits)
	var version: Label = _text(footer, "Versão 0.9.0-rc1 · Candidata para validação", 22, Color("8ba4a4"))
	version.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	version.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
func _text(parent: Node, content: String, size: int, color: Color = Color.WHITE) -> Label:
	var label: Label = Label.new()
	label.text = content
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF if parent is HBoxContainer else TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label
func _button(parent: Node, content: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = content
	button.custom_minimum_size = Vector2(300, 96)
	button.add_theme_font_size_override("font_size", 32)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void: _audio.play_event("ui", AudioServiceNode.BUS_UI); action.call())
	parent.add_child(button)
	return button
## Full-screen themed root with the shared gradient backdrop; every menu layer builds on it.
func _backdrop(layer: CanvasLayer) -> Control:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = _menu_theme()
	layer.add_child(root)
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color("17383e"))
	gradient.set_color(1, Color("081619"))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.3, 0.0)
	texture.fill_to = Vector2(1.1, 1.2)
	var background: TextureRect = TextureRect.new()
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	return root
func _primary(button: Button) -> void:
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style: StyleBoxFlat = _box(Color("e0bf72") if state != "hover" else Color("f2d38a"), Color("fff0c2"), 14, 2 if state != "focus" else 4)
		button.add_theme_stylebox_override(state, style)
	for color: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color, Color("1b2a22"))
func _margin(parent: Control, size: int) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, size)
	parent.add_child(margin)
	return margin
## Rounded panel with a colored top accent; returns the inner column for content.
func _card(parent: Node, accent: Color) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = _box(Color(0.06, 0.15, 0.17, 0.82), Color(accent, 0.55), 18, 2)
	style.border_width_top = 5
	style.border_color = accent
	style.set_content_margin_all(28)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 16)
	panel.add_child(inner)
	return inner
func _box(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(18)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.anti_aliasing = true
	return style
func _heading_font() -> FontVariation:
	if _bold_font == null:
		_bold_font = FontVariation.new()
		_bold_font.base_font = ThemeDB.fallback_font
		_bold_font.variation_embolden = 0.7
		_bold_font.spacing_glyph = 2
	return _bold_font
func _menu_theme() -> Theme:
	if _theme != null: return _theme
	_theme = Theme.new()
	var bold: FontVariation = FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.35
	for type_name: String in ["Button", "OptionButton"]:
		_theme.set_stylebox("normal", type_name, _box(Color("183b41"), Color("2f5d60"), 14, 2))
		_theme.set_stylebox("hover", type_name, _box(Color("21515a"), Color("ecd49a"), 14, 2))
		_theme.set_stylebox("pressed", type_name, _box(Color("5a4a22"), GOLD, 14, 3))
		_theme.set_stylebox("hover_pressed", type_name, _box(Color("6a5728"), Color("fff0c2"), 14, 3))
		_theme.set_stylebox("disabled", type_name, _box(Color(0.08, 0.17, 0.19, 0.6), Color(0.2, 0.3, 0.32, 0.5), 14, 2))
		_theme.set_stylebox("focus", type_name, _box(Color(0, 0, 0, 0), Color("ecd49a"), 14, 3))
		_theme.set_color("font_color", type_name, Color("eef2ea"))
		_theme.set_color("font_hover_color", type_name, Color("fff6dc"))
		_theme.set_color("font_pressed_color", type_name, Color("fff6dc"))
		_theme.set_color("font_hover_pressed_color", type_name, Color("fff6dc"))
		_theme.set_color("font_focus_color", type_name, Color("fff6dc"))
		_theme.set_color("font_disabled_color", type_name, Color("6d8484"))
		_theme.set_font("font", type_name, bold)
	var track: StyleBoxFlat = _box(Color("0c2125"), Color("2f5d60"), 8, 1)
	track.set_content_margin_all(5)
	_theme.set_stylebox("slider", "HSlider", track)
	var filled: StyleBoxFlat = _box(Color("c9a75e"), Color("ecd49a"), 8, 1)
	filled.set_content_margin_all(5)
	_theme.set_stylebox("grabber_area", "HSlider", filled)
	_theme.set_stylebox("grabber_area_highlight", "HSlider", filled)
	for scrollbar: String in ["VScrollBar", "HScrollBar"]:
		for entry: Array in [["scroll", Color(0, 0, 0, 0.18)], ["grabber", Color("2f5d60")], ["grabber_highlight", Color("4b8084")], ["grabber_pressed", Color("ecd49a")]]:
			var bar: StyleBoxFlat = _box(entry[1], Color(0, 0, 0, 0), 6, 0)
			bar.set_content_margin_all(6)
			_theme.set_stylebox(str(entry[0]), scrollbar, bar)
	var tooltip: StyleBoxFlat = _box(Color("0b1d21"), Color("ecd49a"), 10, 1)
	tooltip.set_content_margin_all(12)
	_theme.set_stylebox("panel", "TooltipPanel", tooltip)
	_theme.set_font_size("font_size", "TooltipLabel", 24)
	_theme.set_color("font_color", "TooltipLabel", Color("eef2ea"))
	return _theme
func _launch_stage(path: String = "") -> void:
	if is_instance_valid(battle) and battle.is_inside_tree(): return
	if not path.is_empty():
		selected_stage_path = path
	if is_instance_valid(menu):
		menu.queue_free()
	battle = BattleViewV2.new()
	battle.stage_path = selected_stage_path
	battle.stage = StageSessionV2.read_stage(selected_stage_path)
	_audio.play_region(str(battle.stage.get("biome", "vale")))
	var saved_formation: Array = progress.progress.get("formations", {}).get(str(battle.stage.id), [])
	if not saved_formation.is_empty():
		var available: Array = battle.stage.allowed_towers
		var formation: Array = []
		for key: String in saved_formation:
			if key in available: formation.append(key)
		if not formation.is_empty(): battle.stage.allowed_towers = formation
	battle.difficulty = difficulty
	battle.tutorial_enabled = not bool(progress.get("tutorial_completed", false))
	battle.tutorial_finished.connect(_complete_tutorial)
	battle.exit_requested.connect(_show_menu)
	battle.restart_requested.connect(_restart_stage)
	battle.battle_completed.connect(_record_result)
	add_child(battle)
	battle.apply_graphics_profile(str(progress.settings.get("graphics_profile", "balanced")))
func _restart_stage() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	var old: BattleViewV2 = battle
	old.process_mode = Node.PROCESS_MODE_DISABLED
	old.hide()
	for layer: Node in old.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).hide()
	old.queue_free()
	battle = null
	_launch_stage()
func _record_result(result: Dictionary) -> void:
	if int(result.state) == BattleSimV2.State.VICTORY and str(result.stage).begins_with("stage_"):
		if not _save.record_battle(progress, result):
			battle._result_body.text += "\nNão foi possível salvar. Seu resultado segue visível nesta tela."

func stage_unlocked(index: int) -> bool:
	if index <= 1: return true
	for mode: String in ["adventure", "normal", "veteran"]:
		var previous: Dictionary = progress.progress.campaign.get("stage_%02d:" % (index - 1) + mode, {})
		if int(previous.get("stars", 0)) > 0: return true
	return false

func _show_guide() -> void:
	if has_node("GuideLayer"): return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "GuideLayer"
	layer.layer = 20
	add_child(layer)
	var margin: MarginContainer = _margin(_backdrop(layer), 50)
	var outer: VBoxContainer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 20)
	margin.add_child(outer)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 28)
	outer.add_child(top)
	_button(top, "Voltar ao mapa", func() -> void: layer.queue_free())
	var guide_title: Label = _text(top, "GUIA DE TORRES E INIMIGOS", 44, GOLD)
	guide_title.add_theme_font_override("font", _heading_font())
	guide_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 20)
	scroll.add_child(column)
	var catalog: Dictionary = BattleSimV2.load_catalog()
	_text(column, "TORRES", 42, GOLD).add_theme_font_override("font", _heading_font())
	for definition: Dictionary in catalog.towers.values():
		var first: Dictionary = definition.levels[0]
		var tower_card: VBoxContainer = _card(column, Color("a8c3ac"))
		_text(tower_card, "%s · %d moedas · %.1f m" % [str(definition.name), int(first.cost), float(first.range)], 32, Color("a8c3ac"))
		_text(tower_card, str(definition.description), 28)
		for branch: String in definition.get("branches", {}):
			var specialization: Dictionary = definition.branches[branch]
			_text(tower_card, "L4/L5 · %s: %s" % [specialization.name, specialization.description], 25, MUTED)
	_text(column, "INIMIGOS", 42, GOLD).add_theme_font_override("font", _heading_font())
	for enemy_id: String in catalog.enemies:
		var definition: Dictionary = catalog.enemies[enemy_id]
		if bool(definition.get("lab_only", false)): continue
		var boss: bool = bool(definition.get("boss", false))
		var enemy_card: VBoxContainer = _card(column, Color("dba17b") if boss else Color("ce9b75"))
		var heading: Label = _text(enemy_card, "%s · %d vida · %d moedas · Vazamento %d" % [str(definition.name), int(definition.hp), int(definition.reward), int(definition.leak)], 32, Color("dba17b") if boss else Color("a8c3ac"))
		heading.name = "EnemyGuide_" + enemy_id
		_text(enemy_card, "%s · %.2f m/s · Armadura %d · Resistência mágica %d%%" % ["Aéreo" if str(definition.layer) == "air" else "Terrestre", float(definition.speed), int(definition.get("armor", 0)), roundi(float(definition.get("magic_resistance", 0)) * 100)], 25, MUTED)
		_text(enemy_card, str(definition.description), 28)
	_text(column, "CONTROLE E VENENO", 42, GOLD).add_theme_font_override("font", _heading_font())
	_text(_card(column, GOLD), "Lentidão: vale a maior fonte, com movimento mínimo de 35% da base. Chefes aceitam até 40% de lentidão. Veneno: até três fontes diferentes; a mesma torre renova o efeito. Dano a cada 0,5 s; chefes recebem metade da duração. Pausar congela tudo. Estrela azul: lentidão; triângulo verde: veneno; losango vermelho: sangramento; contorno âmbar: corrosão. As formas acima da vida distinguem os efeitos mesmo sem cor.", 28)

func _prepare_stage(path: String) -> void:
	if has_node("FormationLayer"): return
	var stage: Dictionary = StageSessionV2.read_stage(path)
	var required: int = mini(5, stage.allowed_towers.size())
	var selected: Array[String] = []
	for key: String in progress.progress.get("formations", {}).get(str(stage.id), []):
		if key in stage.allowed_towers and selected.size() < required: selected.append(key)
	if selected.is_empty():
		for key: String in (stage.allowed_towers as Array).slice(0, required): selected.append(key)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "FormationLayer"
	layer.layer = 10
	add_child(layer)
	var margin: MarginContainer = _margin(_backdrop(layer), 60)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	margin.add_child(column)
	_text(column, str(stage.name), 52, GOLD).add_theme_font_override("font", _heading_font())
	_text(column, "Escolha %d famílias para esta defesa. A formação fica salva para sua próxima tentativa." % required, 28)
	if stage.has("air_route_points"):
		_text(column, "Atenção: voadores chegam pela trilha dourada. Garanta cobertura aérea; Canhão e Alquimista atingem apenas o chão.", 28, Color("ecd49a"))
	for wave: Dictionary in stage.waves:
		var revealed: bool = false
		for group: Dictionary in wave.groups:
			var definition: Dictionary = BattleSimV2.load_catalog().enemies[str(group.enemy)]
			if bool(definition.get("boss", false)):
				_text(column, "Chefe: " + str(definition.name) + ". " + str(definition.description), 25, Color("dba17b"))
				revealed = true
				break
		if revealed: break
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	column.add_child(grid)
	var confirm: Button = Button.new()
	confirm.name = "FormationConfirm"
	confirm.text = "Entrar na fase"
	confirm.custom_minimum_size = Vector2(300, 96)
	confirm.add_theme_font_size_override("font_size", 32)
	_primary(confirm)
	var buttons: Dictionary = {}
	var catalog: Dictionary = BattleSimV2.load_catalog()
	for type_id: String in stage.allowed_towers:
		var key: String = type_id
		var definition: Dictionary = catalog.towers[key]
		var button: Button = Button.new()
		button.name = "Formation_" + key
		button.custom_minimum_size = Vector2(500, 112)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 28)
		button.tooltip_text = str(definition.description)
		grid.add_child(button)
		buttons[key] = button
		button.pressed.connect(func() -> void:
			if key in selected: selected.erase(key)
			elif selected.size() < required: selected.append(key)
			_refresh_formation(buttons, selected, required, confirm, catalog)
		)
	_refresh_formation(buttons, selected, required, confirm, catalog)
	var gap: Control = Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(gap)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 20)
	column.add_child(actions)
	_button(actions, "Voltar ao mapa", func() -> void: layer.queue_free())
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	actions.add_child(confirm)
	confirm.pressed.connect(func() -> void:
		if not progress.progress.has("formations"): progress.progress.formations = {}
		progress.progress.formations[str(stage.id)] = selected.duplicate()
		var saved: bool = _save.save_game(progress)
		layer.queue_free()
		_launch_stage(path)
		if not saved: battle._hint.text = "Formação aplicada. Não foi possível salvar a preferência no dispositivo."
	)
func _refresh_formation(buttons: Dictionary, selected: Array[String], required: int, confirm: Button, catalog: Dictionary) -> void:
	for key: String in buttons:
		var button: Button = buttons[key]
		var definition: Dictionary = catalog.towers[key]
		button.text = ("✓  " if key in selected else "+  ") + str(definition.name) + "\n" + ("Terra e ar" if str(definition.layer) == "both" else ("Somente ar" if str(definition.layer) == "air" else ("Suporte de torres" if str(definition.layer) == "ally" else "Somente terra"))) + " · %d moedas" % int(definition.levels[0].cost)
		button.set_pressed_no_signal(key in selected)
		button.disabled = key not in selected and selected.size() >= required
	confirm.disabled = selected.size() != required

func _save_audio_preferences() -> void:
	if not _save.save_game(progress):
		if is_instance_valid(_status): _status.text = "Não foi possível salvar a preferência de áudio."
		elif is_instance_valid(battle): battle._hint.text = "Não foi possível salvar a preferência de áudio."

func _exit_tree() -> void:
	if is_instance_valid(_audio): _audio.stop_music()

func _complete_tutorial() -> void:
	progress.tutorial_completed = true
	if not _save.save_game(progress) and is_instance_valid(battle): battle._hint.text = "Defesa iniciada. Não foi possível salvar a conclusão da ajuda."

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _request_quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED: _flush_audio_preferences()

func _request_quit() -> void:
	if _shutting_down: return
	_shutting_down = true
	_flush_audio_preferences()
	await _audio.shutdown()
	get_tree().quit()

func challenge_completed(challenge: Dictionary) -> bool:
	var key: String = "stage_%02d:" % int(challenge.stage) + difficulty
	return int(progress.progress.campaign.get(key, {}).get("stars", 0)) >= int(challenge.stars)

func _flush_audio_preferences() -> void:
	if is_instance_valid(_audio_save_timer) and not _audio_save_timer.is_stopped():
		_audio_save_timer.stop()
		_save_audio_preferences()

func _handle_back() -> void:
	if is_instance_valid(_intro):
		_finish_intro()
		return
	if is_instance_valid(battle):
		battle.handle_back_request()
		return
	for layer: String in ["GuideLayer","FormationLayer","CreditsLayer"]:
		var overlay: Node = get_node_or_null(layer)
		if overlay != null:
			overlay.queue_free()
			return
	_request_quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(_intro) and event.is_pressed() and not event.is_echo():
		_finish_intro()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		_handle_back()
		get_viewport().set_input_as_handled()

func _show_credits() -> void:
	if has_node("CreditsLayer"): return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "CreditsLayer"
	layer.layer = 30
	add_child(layer)
	var margin: MarginContainer = _margin(_backdrop(layer), 60)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation",20)
	margin.add_child(column)
	_text(column,"IRON PATH · Créditos",42,GOLD).add_theme_font_override("font", _heading_font())
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var text: String = "Guardiões do caminho\nModelos e animações: Kay Lousberg / KayKit, pacotes Adventurers, Character Animations e Forest Nature (CC0).\nAdaptações, geometria adicional, mapas, interface, identidade visual, música e efeitos sintetizados: criados para este projeto.\nEngine: Godot 4.5.2 (MIT).\n\n"
	for file: String in ["kaykit-adventurers.txt","kaykit-character-animations.txt","kaykit-forest.txt"]:
		text += FileAccess.get_file_as_string("res://art/licenses/" + file) + "\n\n"
	text += FileAccess.get_file_as_string("res://art/licenses/godot-engine.txt")
	var body: Label = _text(scroll,text,25)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(column,"Voltar",func() -> void: layer.queue_free())
