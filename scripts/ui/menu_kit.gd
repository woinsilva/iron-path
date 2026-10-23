## Shared look for the campaign menus: theme, panels, icon buttons and touch feedback.
class_name MenuKitV2
extends RefCounted

const GOLD: Color = Color("ecd49a")
const MUTED: Color = Color("b0c6c5")
const INK: Color = Color("06161a")
const BIOME_COLORS: Dictionary = {"vale": Color("8fcf8a"), "canyon": Color("e39a68"), "swamp": Color("b49be0")}
const ICONS: String = "res://art/ui/icons/"

static var _theme: Theme
static var _heading: FontVariation
static var _bold: FontVariation
static var _display: FontFile


static func box(fill: Color, border: Color, radius: int, width: int, padding: int = 18) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	style.content_margin_left = padding + 8
	style.content_margin_right = padding + 8
	style.anti_aliasing = true
	return style


## Lilita One (SIL OFL, art/fonts) for titles and buttons; the default font fills any glyph it lacks.
static func display_font() -> FontFile:
	if _display == null:
		_display = load("res://art/fonts/LilitaOne-Regular.ttf") as FontFile
		_display.fallbacks = [ThemeDB.fallback_font]
	return _display


static func heading_font() -> FontVariation:
	if _heading == null:
		_heading = FontVariation.new()
		_heading.base_font = display_font()
		_heading.spacing_glyph = 1
	return _heading


static func bold_font() -> FontVariation:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = display_font()
	return _bold


static func theme() -> Theme:
	if _theme != null: return _theme
	_theme = Theme.new()
	for type_name: String in ["Button", "OptionButton"]:
		_theme.set_stylebox("normal", type_name, skin("teal"))
		_theme.set_stylebox("hover", type_name, skin("teal", Color(1.15, 1.15, 1.15)))
		_theme.set_stylebox("pressed", type_name, skin("gold"))
		_theme.set_stylebox("hover_pressed", type_name, skin("gold", Color(1.08, 1.08, 1.08)))
		_theme.set_stylebox("disabled", type_name, skin("grey", Color(1, 1, 1, 0.75)))
		_theme.set_stylebox("focus", type_name, StyleBoxEmpty.new())
		_theme.set_constant("outline_size", type_name, 6)
		_theme.set_color("font_outline_color", type_name, Color(0.03, 0.1, 0.12, 0.9))
		_theme.set_color("font_color", type_name, Color("f3f6ee"))
		for state: String in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			_theme.set_color(state, type_name, Color("fff6dc"))
		_theme.set_color("font_disabled_color", type_name, Color("7c9393"))
		_theme.set_color("icon_normal_color", type_name, Color("f3f6ee"))
		_theme.set_color("icon_disabled_color", type_name, Color("7c9393"))
		_theme.set_font("font", type_name, bold_font())
		_theme.set_constant("h_separation", type_name, 14)
	var track: StyleBoxFlat = box(Color("0c2125"), Color("2f5d60"), 10, 1, 7)
	_theme.set_stylebox("slider", "HSlider", track)
	var filled: StyleBoxFlat = box(Color("d8b465"), Color("ecd49a"), 10, 1, 7)
	_theme.set_stylebox("grabber_area", "HSlider", filled)
	_theme.set_stylebox("grabber_area_highlight", "HSlider", filled)
	for scrollbar: String in ["VScrollBar", "HScrollBar"]:
		for entry: Array in [["scroll", Color(0, 0, 0, 0.18)], ["grabber", Color("2f5d60")], ["grabber_highlight", Color("4b8084")], ["grabber_pressed", GOLD]]:
			_theme.set_stylebox(str(entry[0]), scrollbar, box(entry[1], Color(0, 0, 0, 0), 6, 0, 5))
	var tooltip: StyleBoxFlat = box(Color("0b1d21"), GOLD, 12, 1, 12)
	_theme.set_stylebox("panel", "TooltipPanel", tooltip)
	_theme.set_font_size("font_size", "TooltipLabel", 24)
	_theme.set_color("font_color", "TooltipLabel", Color("eef2ea"))
	return _theme


## Glossy mobile button skin (art/ui/skins): gradient body, thick outline, highlight band, drop lip.
static func skin(name: String, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = load("res://art/ui/skins/button_%s.svg" % name) as Texture2D
	style.set_texture_margin_all(34)
	style.texture_margin_bottom = 40
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 14
	style.content_margin_bottom = 22
	style.modulate_color = tint
	return style


## Chunky mobile button: a darker bottom edge that reads as a pressable surface.
static func _raised(fill: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = box(fill, border, 22, 2)
	style.border_width_bottom = 7
	style.border_color = border
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	return style


static func primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal", skin("gold"))
	button.add_theme_stylebox_override("hover", skin("gold", Color(1.08, 1.08, 1.08)))
	button.add_theme_stylebox_override("pressed", skin("gold", Color(0.9, 0.9, 0.9)))
	button.add_theme_stylebox_override("hover_pressed", skin("gold", Color(0.95, 0.95, 0.95)))
	for color: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		button.add_theme_color_override(color, Color("3a2408"))
	button.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.8, 0.5))
	button.add_theme_constant_override("outline_size", 2)


static func icon(name: String) -> Texture2D:
	return load(ICONS + name + ".svg") as Texture2D


static func label(parent: Node, content: String, size: int, color: Color = Color.WHITE, heading: bool = false) -> Label:
	var text: Label = Label.new()
	text.text = content
	text.add_theme_font_size_override("font_size", size)
	text.add_theme_color_override("font_color", color)
	if heading:
		text.add_theme_font_override("font", heading_font())
		text.add_theme_constant_override("outline_size", maxi(4, size / 9))
		text.add_theme_color_override("font_outline_color", INK)
	# Wrapping needs a width from a vertical container; free-placed and row labels size to their text.
	var wraps: bool = not heading and (parent is VBoxContainer or parent is PanelContainer or parent is ScrollContainer)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wraps else TextServer.AUTOWRAP_OFF
	parent.add_child(text)
	return text


## Round icon-only button for corners and top bars.
static func icon_button(parent: Node, icon_name: String, tooltip: String, diameter: int = 104) -> Button:
	var button: Button = Button.new()
	button.icon = icon(icon_name)
	button.expand_icon = true
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(diameter, diameter)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var padding: int = diameter / 4
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var style: StyleBoxFlat = _raised(Color("25606a") if state == "hover" else Color("1d4a52"), GOLD if state != "normal" else Color("2f6a70"))
		style.set_corner_radius_all(diameter / 2)
		style.set_content_margin_all(padding)
		button.add_theme_stylebox_override(state, style)
	parent.add_child(button)
	feedback(button)
	return button


## Touch feedback: the button sinks while held and springs back on release.
static func feedback(button: Button) -> void:
	button.resized.connect(func() -> void: button.pivot_offset = button.size / 2)
	button.button_down.connect(func() -> void:
		button.create_tween().tween_property(button, "scale", Vector2(0.94, 0.94), 0.06)
	)
	button.button_up.connect(func() -> void:
		button.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(button, "scale", Vector2.ONE, 0.18)
	)


static func panel(parent: Node, accent: Color, padding: int = 28, fill: Color = Color(0.05, 0.13, 0.15, 0.92)) -> VBoxContainer:
	var holder: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = box(fill, Color(accent, 0.6), 26, 2, padding)
	style.border_width_top = 6
	style.border_color = accent
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	holder.add_theme_stylebox_override("panel", style)
	parent.add_child(holder)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 16)
	holder.add_child(inner)
	return inner


## Full-screen picture that keeps its aspect and covers the area.
static func cover(parent: Control, path: String) -> TextureRect:
	var picture: TextureRect = TextureRect.new()
	picture.texture = load(path) as Texture2D
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(picture)
	return picture


## Vertical darkening so text stays legible over the battlefield art.
static func shade(parent: Control, top: float, bottom: float) -> TextureRect:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0.02, 0.07, 0.08, top))
	gradient.set_color(1, Color(0.02, 0.07, 0.08, bottom))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var layer: TextureRect = TextureRect.new()
	layer.texture = texture
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(layer)
	return layer


## Margins that respect notches and rounded corners, never below the comfortable minimum.
static func safe_margin(parent: Control, minimum: int) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var insets: Dictionary = {"left": minimum, "right": minimum, "top": minimum, "bottom": minimum}
	if DisplayServer.get_name() != "headless":
		var window: Vector2 = Vector2(DisplayServer.window_get_size())
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		var screen: Vector2 = Vector2(DisplayServer.screen_get_size())
		if window.x > 0 and safe.size.x > 0 and window.is_equal_approx(screen):
			var scale: float = 1920.0 / window.x if window.x / window.y <= 16.0 / 9.0 else 1080.0 / window.y
			insets.left = maxi(minimum, int(safe.position.x * scale))
			insets.top = maxi(minimum, int(safe.position.y * scale))
			insets.right = maxi(minimum, int((screen.x - safe.end.x) * scale))
			insets.bottom = maxi(minimum, int((screen.y - safe.end.y) * scale))
	for edge: String in insets:
		margin.add_theme_constant_override("margin_" + edge, int(insets[edge]))
	parent.add_child(margin)
	return margin
