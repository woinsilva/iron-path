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
var _intro: Control
## "home" (title screen) or "map" (campaign); battles return to the map.
var _screen: String = "home"
const GOLD: Color = MenuKitV2.GOLD
const MUTED: Color = MenuKitV2.MUTED
const BIOMES: Array = [["vale", "VALE VERDE", 1], ["canyon", "GARGANTA RUBRA", 5], ["swamp", "PÂNTANO SOMBRIO", 9]]
const STAGES_PER_BIOME: int = 4
const BIOME_WIDTH: float = 1560.0
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
	menu.name = "Menu"
	add_child(menu)
	var root: Control = _screen_root(menu)
	if _screen == "map": _build_map(root)
	else: _build_home(root)
	_status = MenuKitV2.label(root, "", 26, GOLD)
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_status.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_status.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_status.offset_bottom = -24
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.25)
func _open_screen(screen: String) -> void:
	_screen = screen
	_show_menu()
func _return_to_map() -> void:
	_screen = "map"
	_show_menu()
func _screen_root(layer: CanvasLayer) -> Control:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = MenuKitV2.theme()
	layer.add_child(root)
	return root
## Opaque full-screen sheet over the menu, used by guide, formation and credits.
func _full_layer(layer_name: String, depth: int, art: String = "res://art/ui/backdrop_vale.jpg") -> VBoxContainer:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = layer_name
	layer.layer = depth
	add_child(layer)
	var root: Control = _screen_root(layer)
	MenuKitV2.cover(root, art)
	MenuKitV2.shade(root, 0.82, 0.95)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	MenuKitV2.safe_margin(root, 40).add_child(column)
	root.modulate.a = 0.0
	root.position.y = 40
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(root, "modulate:a", 1.0, 0.2)
	tween.tween_property(root, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return column
## Dimmed overlay with a centered card; tapping outside the card closes it.
func _modal(layer_name: String, accent: Color, width: float) -> VBoxContainer:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = layer_name
	layer.layer = 15
	add_child(layer)
	var root: Control = _screen_root(layer)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.01, 0.04, 0.05, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed(): layer.queue_free()
	)
	root.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var card: VBoxContainer = MenuKitV2.panel(center, accent, 36)
	card.custom_minimum_size = Vector2(width, 0)
	var holder: Control = card.get_parent() as Control
	holder.resized.connect(func() -> void: holder.pivot_offset = holder.size / 2)
	holder.scale = Vector2(0.9, 0.9)
	holder.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(holder, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 1.0, 0.15)
	return card
func _top_bar(parent: Node, title: String, back: Callable) -> HBoxContainer:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 24)
	parent.add_child(bar)
	_wire(MenuKitV2.icon_button(bar, "back", "Voltar"), back)
	var heading: Label = MenuKitV2.label(bar, title, 52, GOLD, true)
	heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.clip_text = true
	return bar
func _text(parent: Node, content: String, size: int, color: Color = Color.WHITE) -> Label:
	return MenuKitV2.label(parent, content, size, color)
func _button(parent: Node, content: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = content
	button.custom_minimum_size = Vector2(240, 96)
	button.add_theme_font_size_override("font_size", 32)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(button)
	MenuKitV2.feedback(button)
	_wire(button, action)
	return button
func _wire(button: Button, action: Callable) -> void:
	button.pressed.connect(func() -> void: _audio.play_event("ui", AudioServiceNode.BUS_UI); action.call())
func _total_stars() -> int:
	var total: int = 0
	for index in range(1, 13):
		total += int(progress.progress.campaign.get("stage_%02d:" % index + difficulty, {}).get("stars", 0))
	return total
func _star_chip(parent: Node) -> PanelContainer:
	var chip: PanelContainer = PanelContainer.new()
	chip.add_theme_stylebox_override("panel", MenuKitV2.box(Color(0.03, 0.1, 0.11, 0.85), Color(GOLD, 0.6), 40, 2, 12))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(chip)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	chip.add_child(row)
	var star: TextureRect = TextureRect.new()
	star.texture = MenuKitV2.icon("star")
	star.modulate = GOLD
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.custom_minimum_size = Vector2(44, 44)
	row.add_child(star)
	MenuKitV2.label(row, "%d / 36" % _total_stars(), 32, Color("fff6dc")).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return chip
func _build_home(root: Control) -> void:
	_live_backdrop()
	MenuKitV2.shade(root, 0.15, 0.78)
	var frame: Control = Control.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuKitV2.safe_margin(root, 44).add_child(frame)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(center)
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 26)
	center.add_child(column)
	var emblem: TextureRect = TextureRect.new()
	emblem.texture = load("res://art/branding/icon.png") as Texture2D
	emblem.custom_minimum_size = Vector2(200, 200)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(emblem)
	var title: Label = MenuKitV2.label(column, "IRON PATH", 132, GOLD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("shadow_offset_y", 8)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	var subtitle: Label = MenuKitV2.label(column, "Guardiões do caminho", 40, Color("e3ece5"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(0, 18)
	column.add_child(gap)
	var play: Button = _button(column, "JOGAR", func() -> void: _open_screen("map"))
	play.name = "PlayButton"
	play.icon = MenuKitV2.icon("play")
	play.expand_icon = false
	play.add_theme_constant_override("icon_max_width", 56)
	play.custom_minimum_size = Vector2(560, 140)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.add_theme_font_size_override("font_size", 56)
	MenuKitV2.primary(play)
	play.resized.connect(func() -> void: play.pivot_offset = play.size / 2)
	var pulse: Tween = play.create_tween().set_loops()
	pulse.tween_property(play, "modulate", Color(1.12, 1.12, 1.12), 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(play, "modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)
	var lab: Button = _button(column, "Laboratório do Arsenal", func() -> void: _prepare_stage("res://data/campaign/arsenal_lab.json"))
	lab.icon = MenuKitV2.icon("flask")
	lab.add_theme_constant_override("icon_max_width", 40)
	lab.custom_minimum_size = Vector2(560, 96)
	lab.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lab.add_theme_font_size_override("font_size", 30)
	var corner: HBoxContainer = HBoxContainer.new()
	corner.add_theme_constant_override("separation", 20)
	frame.add_child(corner)
	corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_wire(MenuKitV2.icon_button(corner, "book", "Guia de torres e inimigos"), _show_guide)
	_wire(MenuKitV2.icon_button(corner, "gear", "Ajustes"), _show_settings)
	_wire(MenuKitV2.icon_button(corner, "info", "Créditos e licenças"), _show_credits)
	var stars: PanelContainer = _star_chip(frame)
	stars.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var version: Label = MenuKitV2.label(frame, "Versão 0.9.0-rc1", 22, Color("8ba4a4"))
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
## The title screen shows the real first map, alive (wind, smoke, flags), under a slow camera drift.
func _live_backdrop() -> void:
	var stage: Dictionary = StageSessionV2.read_stage("res://data/campaign/stage_01.json")
	var view: Diorama3D = Diorama3D.new()
	view.name = "MenuDiorama"
	view.route_points = stage.route_points
	view.biome = str(stage.biome)
	view.scenery = str(stage.get("scenery", ""))
	view.stage_index = 1
	menu.add_child(view)
	var landmarks: StageLandmarksV2 = StageLandmarksV2.new()
	landmarks.entrance = view.route.sample_baked(0)
	landmarks.endpoint = view.route.sample_baked(view.route.get_baked_length())
	menu.add_child(landmarks)
	var camera: Camera3D = view.camera
	camera.size = 26.0
	var drift: Tween = view.create_tween().set_loops()
	drift.tween_property(camera, "h_offset", 5.0, 14.0).set_trans(Tween.TRANS_SINE)
	drift.parallel().tween_property(camera, "size", 22.0, 14.0).set_trans(Tween.TRANS_SINE)
	drift.tween_property(camera, "h_offset", -5.0, 14.0).set_trans(Tween.TRANS_SINE)
	drift.parallel().tween_property(camera, "size", 26.0, 14.0).set_trans(Tween.TRANS_SINE)
func _build_map(root: Control) -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color("0a1c20")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	MenuKitV2.safe_margin(root, 32).add_child(column)
	var bar: HBoxContainer = _top_bar(column, "CAMPANHA", func() -> void: _open_screen("home"))
	_star_chip(bar)
	var choices: HBoxContainer = HBoxContainer.new()
	choices.add_theme_constant_override("separation", 8)
	bar.add_child(choices)
	for pair: Array in [["adventure", "Aventura"], ["normal", "Normal"], ["veteran", "Veterano"]]:
		var key: String = pair[0]
		var button: Button = _button(choices, str(pair[1]), func() -> void: difficulty = key; _show_menu())
		button.name = "Difficulty_" + key
		button.toggle_mode = true
		button.set_pressed_no_signal(difficulty == key)
		button.custom_minimum_size = Vector2(190, 96)
		button.add_theme_font_size_override("font_size", 28)
		button.tooltip_text = "Mais recursos e tempo" if key == "adventure" else ("Inimigos com 8% mais vida e 2% mais velocidade; intervalos de 6 s" if key == "veteran" else "Dificuldade de referência")
	_wire(MenuKitV2.icon_button(bar, "flask", "Laboratório do Arsenal"), func() -> void: _prepare_stage("res://data/campaign/arsenal_lab.json"))
	_wire(MenuKitV2.icon_button(bar, "book", "Guia de torres e inimigos"), _show_guide)
	_wire(MenuKitV2.icon_button(bar, "gear", "Ajustes"), _show_settings)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "CampaignScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var strip: HBoxContainer = HBoxContainer.new()
	strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	strip.add_theme_constant_override("separation", 32)
	scroll.add_child(strip)
	var focus: int = 0
	for biome_index in range(BIOMES.size()):
		_biome_panel(strip, BIOMES[biome_index])
		if stage_unlocked(int(BIOMES[biome_index][2])): focus = biome_index
	var hint: String = "Arraste para os lados para ver os biomas · toque numa fase para ver os detalhes"
	if stage_unlocked(13): hint = "Os três caminhos estão protegidos. Experimente outras formações ou uma dificuldade maior."
	MenuKitV2.label(column, hint, 24, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_focus_biome(scroll, focus)
## Waits for the strip to be laid out, then centers the newest unlocked biome.
func _focus_biome(scroll: ScrollContainer, focus: int) -> void:
	for _frame: int in range(2): await get_tree().process_frame
	if is_instance_valid(scroll): scroll.scroll_horizontal = int(focus * (BIOME_WIDTH + 32) - (scroll.size.x - BIOME_WIDTH) / 2)
func _biome_panel(parent: Node, biome: Array) -> void:
	var key: String = biome[0]
	var first: int = int(biome[2])
	var accent: Color = MenuKitV2.BIOME_COLORS[key]
	var area: Control = Control.new()
	area.name = "Biome_" + key
	area.custom_minimum_size = Vector2(BIOME_WIDTH, 0)
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.clip_contents = true
	parent.add_child(area)
	MenuKitV2.cover(area, "res://art/ui/backdrop_%s.jpg" % key)
	MenuKitV2.shade(area, 0.2, 0.62)
	var points: Array[Vector2] = [Vector2(0.13, 0.66), Vector2(0.37, 0.36), Vector2(0.63, 0.66), Vector2(0.87, 0.36)]
	var trail: Control = Control.new()
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	area.add_child(trail)
	trail.resized.connect(trail.queue_redraw)
	trail.draw.connect(func() -> void:
		for index in range(points.size() - 1):
			var from: Vector2 = points[index] * trail.size
			var to: Vector2 = points[index + 1] * trail.size
			trail.draw_line(from, to, Color(0, 0, 0, 0.45), 18, true)
			trail.draw_dashed_line(from, to, Color("f3e3b6") if stage_unlocked(first + index + 1) else Color(1, 1, 1, 0.35), 10, 26, true, true)
	)
	var title: Label = MenuKitV2.label(area, str(biome[1]), 56, accent, true)
	title.position = Vector2(44, 30)
	var subtitle: Label = MenuKitV2.label(area, "Fases %d a %d" % [first, first + STAGES_PER_BIOME - 1], 26, Color("e3ece5"))
	subtitle.position = Vector2(48, 104)
	for offset in range(STAGES_PER_BIOME):
		_stage_node(area, first + offset, points[offset], accent)
	for challenge: Dictionary in StageSessionV2.read_stage("res://data/campaign/challenges.json").challenges:
		var challenge_stage: int = int(challenge.stage)
		if challenge_stage < first or challenge_stage >= first + STAGES_PER_BIOME or not stage_unlocked(challenge_stage + 1): continue
		var replay_path: String = "res://data/campaign/stage_%02d.json" % challenge_stage
		var replay: Button = _button(area, str(challenge.name) + ("  ✓" if challenge_completed(challenge) else ""), func() -> void: _prepare_stage(replay_path))
		replay.name = "Challenge_" + str(challenge.id)
		replay.icon = MenuKitV2.icon("trophy")
		replay.add_theme_constant_override("icon_max_width", 40)
		replay.add_theme_font_size_override("font_size", 26)
		replay.tooltip_text = "Desafio opcional: " + str(challenge.description)
		replay.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		replay.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		replay.offset_right = -32
		replay.offset_top = 32
		MenuKitV2.primary(replay)
	var border: Panel = Panel.new()
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.add_theme_stylebox_override("panel", MenuKitV2.box(Color(0, 0, 0, 0), Color(accent, 0.7), 28, 4))
	area.add_child(border)
	if not stage_unlocked(first):
		var veil: ColorRect = ColorRect.new()
		veil.color = Color(0.02, 0.05, 0.06, 0.55)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		area.add_child(veil)
		var notice: Label = MenuKitV2.label(area, "Conclua a fase %d para abrir este bioma" % (first - 1), 30, Color("e3ece5"))
		notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		notice.grow_horizontal = Control.GROW_DIRECTION_BOTH
		notice.grow_vertical = Control.GROW_DIRECTION_BEGIN
		notice.offset_bottom = -40
		notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
func _stage_node(area: Control, index: int, at: Vector2, accent: Color) -> void:
	var path: String = "res://data/campaign/stage_%02d.json" % index
	var stage: Dictionary = StageSessionV2.read_stage(path)
	var stars: int = int(progress.progress.campaign.get(str(stage.id) + ":" + difficulty, {}).get("stars", 0))
	var available: bool = stage_unlocked(index)
	var holder: VBoxContainer = VBoxContainer.new()
	holder.add_theme_constant_override("separation", 6)
	holder.custom_minimum_size = Vector2(300, 0)
	area.add_child(holder)
	holder.anchor_left = at.x
	holder.anchor_right = at.x
	holder.anchor_top = at.y
	holder.anchor_bottom = at.y
	holder.grow_horizontal = Control.GROW_DIRECTION_BOTH
	holder.offset_left = -150
	holder.offset_right = 150
	holder.offset_top = -82
	var button: Button = Button.new()
	button.name = "Stage_%02d" % index
	button.custom_minimum_size = Vector2(164, 164)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", MenuKitV2.heading_font())
	button.add_theme_font_size_override("font_size", 64)
	button.add_theme_constant_override("outline_size", 8)
	button.add_theme_color_override("font_outline_color", MenuKitV2.INK)
	var fill: Color = Color("e3bf6c") if stars > 0 else (accent.darkened(0.25) if available else Color("3d4a4c"))
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var style: StyleBoxFlat = MenuKitV2.box(fill.lightened(0.12) if state == "hover" else fill, Color("fff6dc") if available else Color("6b7a7b"), 82, 6, 0)
		style.border_width_bottom = 12
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 6)
		button.add_theme_stylebox_override(state, style)
	if available: button.text = str(index)
	else:
		button.icon = MenuKitV2.icon("lock")
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 64)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.tooltip_text = str(stage.name) if available else "Conclua a fase anterior em uma dificuldade para abrir este caminho."
	holder.add_child(button)
	MenuKitV2.feedback(button)
	_wire(button, func() -> void: _show_stage_sheet(index))
	if available and stars == 0:
		button.resized.connect(func() -> void: button.pivot_offset = button.size / 2)
		var beat: Tween = button.create_tween().set_loops()
		beat.tween_property(button, "modulate", Color(1.25, 1.2, 1.05), 0.7).set_trans(Tween.TRANS_SINE)
		beat.tween_property(button, "modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_SINE)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	holder.add_child(row)
	for slot in range(3):
		var star: TextureRect = TextureRect.new()
		star.texture = MenuKitV2.icon("star")
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.custom_minimum_size = Vector2(42, 42)
		star.modulate = GOLD if slot < stars else Color(0.1, 0.16, 0.17, 0.85)
		row.add_child(star)
	var caption: Label = MenuKitV2.label(holder, str(stage.name), 28, Color("fff6dc") if available else Color("a9b6b6"), true)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
func _show_stage_sheet(index: int) -> void:
	if has_node("StageSheet"): return
	var path: String = "res://data/campaign/stage_%02d.json" % index
	var stage: Dictionary = StageSessionV2.read_stage(path)
	var accent: Color = MenuKitV2.BIOME_COLORS.get(str(stage.get("biome", "vale")), GOLD)
	var best: Dictionary = progress.progress.campaign.get(str(stage.id) + ":" + difficulty, {})
	var stars: int = int(best.get("stars", 0))
	var available: bool = stage_unlocked(index)
	var card: VBoxContainer = _modal("StageSheet", accent, 980)
	var layer: Node = get_node("StageSheet")
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	card.add_child(header)
	var heading: Label = MenuKitV2.label(header, "%d · %s" % [index, str(stage.name)], 48, GOLD, true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_wire(MenuKitV2.icon_button(header, "close", "Fechar", 88), func() -> void: layer.queue_free())
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	for slot in range(3):
		var star: TextureRect = TextureRect.new()
		star.texture = MenuKitV2.icon("star")
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.custom_minimum_size = Vector2(64, 64)
		star.modulate = GOLD if slot < stars else Color(0.2, 0.28, 0.29)
		row.add_child(star)
	var facts: GridContainer = GridContainer.new()
	facts.columns = 2
	facts.add_theme_constant_override("h_separation", 16)
	facts.add_theme_constant_override("v_separation", 16)
	card.add_child(facts)
	var record: String = "—"
	if best.has("best_ticks"):
		var seconds: int = int(best.best_ticks) / BattleSimV2.TICK_RATE
		record = "%d:%02d" % [seconds / 60, seconds % 60]
	var entrances: int = 1 + (stage.get("extra_route_points", []) as Array).size()
	for fact: Array in [["Ondas", str(stage.waves.size())], ["Entradas de inimigos", str(entrances) + (" + trilha aérea" if stage.has("air_route_points") else "")], ["Famílias de torres", str(stage.allowed_towers.size())], ["Evolução até", "Nível %d" % int(stage.max_level)], ["Melhor tempo", record]]:
		var chip: VBoxContainer = MenuKitV2.panel(facts, Color(accent, 0.5), 16, Color(1, 1, 1, 0.05))
		(chip.get_parent() as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.add_theme_constant_override("separation", 2)
		MenuKitV2.label(chip, str(fact[0]), 22, MUTED)
		MenuKitV2.label(chip, str(fact[1]), 34, Color("fff6dc"))
	var catalog: Dictionary = BattleSimV2.load_catalog()
	for wave: Dictionary in stage.waves:
		for group: Dictionary in wave.groups:
			var definition: Dictionary = catalog.enemies[str(group.enemy)]
			if bool(definition.get("boss", false)) and not card.has_node("BossNotice"):
				MenuKitV2.label(card, "Chefe: " + str(definition.name), 28, Color("e7a982")).name = "BossNotice"
	if stage.has("air_route_points"): MenuKitV2.label(card, "Voadores chegam pela trilha dourada: leve cobertura aérea.", 26, GOLD)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 20)
	card.add_child(actions)
	_button(actions, "Fechar", func() -> void: layer.queue_free())
	var play: Button = _button(actions, "Jogar" if available else "Bloqueada", func() -> void:
		layer.queue_free()
		_prepare_stage(path)
	)
	play.name = "StagePlay"
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.disabled = not available
	if available:
		play.icon = MenuKitV2.icon("play")
		play.add_theme_constant_override("icon_max_width", 40)
		MenuKitV2.primary(play)
func _show_settings() -> void:
	if has_node("SettingsLayer"): return
	var card: VBoxContainer = _modal("SettingsLayer", Color("6f9a9c"), 1000)
	var layer: Node = get_node("SettingsLayer")
	var header: HBoxContainer = HBoxContainer.new()
	card.add_child(header)
	var heading: Label = MenuKitV2.label(header, "AJUSTES", 46, GOLD, true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wire(MenuKitV2.icon_button(header, "close", "Fechar", 88), func() -> void: layer.queue_free())
	MenuKitV2.label(card, "Gráficos", 28, MUTED)
	var profiles: Array[String] = ["economy", "balanced", "quality"]
	var graphics: HBoxContainer = HBoxContainer.new()
	graphics.add_theme_constant_override("separation", 12)
	card.add_child(graphics)
	var choices: Array[Button] = []
	for entry: Array in [["economy", "Economia"], ["balanced", "Equilibrado"], ["quality", "Qualidade"]]:
		var profile: String = entry[0]
		var option: Button = _button(graphics, str(entry[1]), func() -> void:
			progress.settings.graphics_profile = profile
			for other: Button in choices: other.set_pressed_no_signal(other.name == "Graphics_" + profile)
			if not _save.save_game(progress) and is_instance_valid(_status): _status.text = "Não foi possível salvar a preferência gráfica."
		)
		option.name = "Graphics_" + profile
		option.toggle_mode = true
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.set_pressed_no_signal(str(progress.settings.get("graphics_profile", "balanced")) == profile)
		choices.append(option)
	for entry: Array in [["music_volume", "Música e ambiente"], ["sfx_volume", "Efeitos e interface"]]:
		var setting: String = entry[0]
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		card.add_child(row)
		MenuKitV2.label(row, str(entry[1]), 28, MUTED).custom_minimum_size = Vector2(300, 0)
		var slider: HSlider = HSlider.new()
		slider.custom_minimum_size = Vector2(400, 80)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = int(progress.settings.get(setting, 100))
		row.add_child(slider)
		var readout: Label = MenuKitV2.label(row, "%d%%" % int(slider.value), 28)
		readout.custom_minimum_size = Vector2(90, 0)
		slider.value_changed.connect(func(value: float) -> void:
			progress.settings[setting] = int(value)
			readout.text = "%d%%" % int(value)
			_audio.apply_settings(progress.settings)
			_audio_save_timer.start()
		)
func _show_guide() -> void:
	if has_node("GuideLayer"): return
	var column: VBoxContainer = _full_layer("GuideLayer", 20)
	var layer: Node = get_node("GuideLayer")
	var bar: HBoxContainer = _top_bar(column, "GUIA", func() -> void: layer.queue_free())
	var pages: Dictionary = {}
	var tabs: Array[Button] = []
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)
	for entry: Array in [["towers", "Torres"], ["enemies", "Inimigos"], ["effects", "Efeitos"]]:
		var page_key: String = entry[0]
		var tab: Button = _button(bar, str(entry[1]), func() -> void:
			for key: String in pages: (pages[key] as Control).visible = key == page_key
			for other: Button in tabs: other.set_pressed_no_signal(other.name == "Tab_" + page_key)
			scroll.scroll_vertical = 0
		)
		tab.name = "Tab_" + page_key
		tab.toggle_mode = true
		tab.custom_minimum_size = Vector2(200, 96)
		tab.set_pressed_no_signal(page_key == "towers")
		tabs.append(tab)
		var page: GridContainer = GridContainer.new()
		page.columns = 2
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.add_theme_constant_override("h_separation", 22)
		page.add_theme_constant_override("v_separation", 22)
		page.visible = page_key == "towers"
		stack.add_child(page)
		pages[page_key] = page
	var catalog: Dictionary = BattleSimV2.load_catalog()
	for type_id: String in catalog.towers:
		var definition: Dictionary = catalog.towers[type_id]
		var first: Dictionary = definition.levels[0]
		var card: VBoxContainer = MenuKitV2.panel(pages.towers, Color("a8c3ac"), 22)
		(card.get_parent() as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var line: HBoxContainer = HBoxContainer.new()
		line.add_theme_constant_override("separation", 20)
		card.add_child(line)
		var portrait: TextureRect = TextureRect.new()
		portrait.texture = load("res://art/ui/tower_%s.jpg" % type_id) as Texture2D
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.custom_minimum_size = Vector2(150, 150)
		line.add_child(portrait)
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(info)
		MenuKitV2.label(info, str(definition.name), 34, Color("fff6dc"), true)
		MenuKitV2.label(info, "%s · %d moedas · alcance %.1f m" % [_layer_text(str(definition.layer)), int(first.cost), float(first.range)], 24, Color("a8c3ac"))
		MenuKitV2.label(info, str(definition.description), 24)
		for branch: String in definition.get("branches", {}):
			var specialization: Dictionary = definition.branches[branch]
			MenuKitV2.label(card, "L4–L6 · %s: %s" % [specialization.name, specialization.description], 22, MUTED)
	for enemy_id: String in catalog.enemies:
		var definition: Dictionary = catalog.enemies[enemy_id]
		if bool(definition.get("lab_only", false)): continue
		var boss: bool = bool(definition.get("boss", false))
		var card: VBoxContainer = MenuKitV2.panel(pages.enemies, Color("e7a982") if boss else Color("ce9b75"), 22)
		(card.get_parent() as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var heading: Label = MenuKitV2.label(card, str(definition.name) + ("  · CHEFE" if boss else ""), 32, Color("e7a982") if boss else Color("fff6dc"), true)
		heading.name = "EnemyGuide_" + enemy_id
		MenuKitV2.label(card, "%d vida · %d moedas · vazamento %d" % [int(definition.hp), int(definition.reward), int(definition.leak)], 24, Color("a8c3ac"))
		MenuKitV2.label(card, "%s · %.2f m/s · armadura %d · resistência mágica %d%%" % ["Aéreo" if str(definition.layer) == "air" else "Terrestre", float(definition.speed), int(definition.get("armor", 0)), roundi(float(definition.get("magic_resistance", 0)) * 100)], 22, MUTED)
		MenuKitV2.label(card, str(definition.description), 24)
	pages.effects.columns = 1
	var effects: VBoxContainer = MenuKitV2.panel(pages.effects, GOLD, 28)
	MenuKitV2.label(effects, "CONTROLE E VENENO", 34, GOLD, true)
	MenuKitV2.label(effects, "Lentidão: vale a maior fonte, com movimento mínimo de 35% da base. Chefes aceitam até 40% de lentidão. Veneno: até três fontes diferentes; a mesma torre renova o efeito. Dano a cada 0,5 s; chefes recebem metade da duração. Pausar congela tudo. Estrela azul: lentidão; triângulo verde: veneno; losango vermelho: sangramento; contorno âmbar: corrosão. As formas acima da vida distinguem os efeitos mesmo sem cor.", 28)
func _layer_text(layer: String) -> String:
	return "Terra e ar" if layer == "both" else ("Somente ar" if layer == "air" else ("Suporte de torres" if layer == "ally" else "Somente terra"))
func _prepare_stage(path: String) -> void:
	if has_node("FormationLayer"): return
	var stage: Dictionary = StageSessionV2.read_stage(path)
	var required: int = mini(5, stage.allowed_towers.size())
	var selected: Array[String] = []
	for key: String in progress.progress.get("formations", {}).get(str(stage.id), []):
		if key in stage.allowed_towers and selected.size() < required: selected.append(key)
	if selected.is_empty():
		for key: String in (stage.allowed_towers as Array).slice(0, required): selected.append(key)
	var biome: String = str(stage.get("biome", "vale"))
	var column: VBoxContainer = _full_layer("FormationLayer", 10, "res://art/ui/backdrop_%s.jpg" % (biome if biome in MenuKitV2.BIOME_COLORS else "vale"))
	var layer: Node = get_node("FormationLayer")
	_top_bar(column, str(stage.name), func() -> void: layer.queue_free())
	MenuKitV2.label(column, "Escolha %d famílias para esta defesa. A formação fica salva para sua próxima tentativa." % required, 28)
	if stage.has("air_route_points"):
		MenuKitV2.label(column, "Atenção: voadores chegam pela trilha dourada. Garanta cobertura aérea; Canhão e Alquimista atingem apenas o chão.", 26, GOLD)
	var catalog: Dictionary = BattleSimV2.load_catalog()
	var boss_shown: bool = false
	for wave: Dictionary in stage.waves:
		for group: Dictionary in wave.groups:
			var definition: Dictionary = catalog.enemies[str(group.enemy)]
			if bool(definition.get("boss", false)) and not boss_shown:
				MenuKitV2.label(column, "Chefe: " + str(definition.name) + ". " + str(definition.description), 25, Color("e7a982"))
				boss_shown = true
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	scroll.add_child(grid)
	var confirm: Button = Button.new()
	confirm.name = "FormationConfirm"
	confirm.text = "Entrar na fase"
	confirm.icon = MenuKitV2.icon("play")
	confirm.add_theme_constant_override("icon_max_width", 40)
	confirm.custom_minimum_size = Vector2(460, 110)
	confirm.add_theme_font_size_override("font_size", 36)
	confirm.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	MenuKitV2.primary(confirm)
	MenuKitV2.feedback(confirm)
	var counter: Label = Label.new()
	var buttons: Dictionary = {}
	for type_id: String in stage.allowed_towers:
		var key: String = type_id
		var definition: Dictionary = catalog.towers[key]
		var button: Button = Button.new()
		button.name = "Formation_" + key
		button.custom_minimum_size = Vector2(0, 282)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.icon = load("res://art/ui/tower_%s.jpg" % key) as Texture2D
		button.expand_icon = true
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 160)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 26)
		button.tooltip_text = str(definition.description)
		grid.add_child(button)
		MenuKitV2.feedback(button)
		buttons[key] = button
		button.pressed.connect(func() -> void:
			_audio.play_event("ui", AudioServiceNode.BUS_UI)
			if key in selected: selected.erase(key)
			elif selected.size() < required: selected.append(key)
			_refresh_formation(buttons, selected, required, confirm, catalog, counter)
		)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 24)
	column.add_child(actions)
	counter.add_theme_font_size_override("font_size", 32)
	counter.add_theme_color_override("font_color", Color("fff6dc"))
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.add_child(counter)
	actions.add_child(confirm)
	_refresh_formation(buttons, selected, required, confirm, catalog, counter)
	confirm.pressed.connect(func() -> void:
		_audio.play_event("ui", AudioServiceNode.BUS_UI)
		if not progress.progress.has("formations"): progress.progress.formations = {}
		progress.progress.formations[str(stage.id)] = selected.duplicate()
		var saved: bool = _save.save_game(progress)
		layer.queue_free()
		_launch_stage(path)
		if not saved: battle._hint.text = "Formação aplicada. Não foi possível salvar a preferência no dispositivo."
	)
func _refresh_formation(buttons: Dictionary, selected: Array[String], required: int, confirm: Button, catalog: Dictionary, counter: Label = null) -> void:
	for key: String in buttons:
		var button: Button = buttons[key]
		var definition: Dictionary = catalog.towers[key]
		button.text = ("✓  " if key in selected else "+  ") + str(definition.name) + "\n" + _layer_text(str(definition.layer)) + " · %d moedas" % int(definition.levels[0].cost)
		button.set_pressed_no_signal(key in selected)
		button.disabled = key not in selected and selected.size() >= required
	confirm.disabled = selected.size() != required
	if counter != null: counter.text = "%d de %d famílias escolhidas" % [selected.size(), required]
func _launch_stage(path: String = "") -> void:
	if is_instance_valid(battle) and battle.is_inside_tree(): return
	if not path.is_empty():
		selected_stage_path = path
	if is_instance_valid(menu):
		menu.queue_free()
	_screen = "map"
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
	battle.exit_requested.connect(_return_to_map)
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
	# Validation aid: `-- --unlock-all` opens every stage without touching the saved progress.
	if "--unlock-all" in OS.get_cmdline_user_args(): return true
	for mode: String in ["adventure", "normal", "veteran"]:
		var previous: Dictionary = progress.progress.campaign.get("stage_%02d:" % (index - 1) + mode, {})
		if int(previous.get("stars", 0)) > 0: return true
	return false

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
	for layer: String in ["StageSheet", "SettingsLayer", "GuideLayer", "FormationLayer", "CreditsLayer"]:
		var overlay: Node = get_node_or_null(layer)
		if overlay != null:
			overlay.queue_free()
			return
	if _screen == "map":
		_open_screen("home")
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
	var column: VBoxContainer = _full_layer("CreditsLayer", 30)
	var layer: Node = get_node("CreditsLayer")
	_top_bar(column, "CRÉDITOS E LICENÇAS", func() -> void: layer.queue_free())
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var card: VBoxContainer = MenuKitV2.panel(scroll, GOLD, 32)
	(card.get_parent() as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuKitV2.label(card, "IRON PATH · Guardiões do caminho", 36, GOLD, true)
	var text: String = "Modelos e animações: Kay Lousberg / KayKit, pacotes Adventurers, Character Animations e Forest Nature (CC0).
Adaptações, geometria adicional, mapas, interface, identidade visual, música e efeitos sintetizados: criados para este projeto.
Engine: Godot 4.5.2 (MIT).

"
	for file: String in ["kaykit-adventurers.txt", "kaykit-character-animations.txt", "kaykit-forest.txt"]:
		text += FileAccess.get_file_as_string("res://art/licenses/" + file) + "

"
	text += FileAccess.get_file_as_string("res://art/licenses/godot-engine.txt")
	MenuKitV2.label(card, text, 24).size_flags_horizontal = Control.SIZE_EXPAND_FILL
