extends Node3D
## P1 quality arena. This is deliberately separate from the campaign runtime.

var diorama: Diorama3D
var actors: Array[RiggedActor3D] = []
var tracks: Array[Dictionary] = []
var towers: Array[ArcherDisplay3D] = []
var _shot_timer: float = 0.0
var _time: float = 0.0
var _speed: float = 1.0
var _running: bool = false
var _motion: bool = true
var _projectiles: Array[Dictionary] = []
var _revivals: Array[Dictionary] = []
var _status: Label
var _pause_button: Button

func _ready() -> void:
	diorama = Diorama3D.new()
	add_child(diorama)
	for index in range(7):
		var actor: RiggedActor3D = RiggedActor3D.new()
		actor.name = "Goblin%d" % index
		actor.initial_phase = index * 0.13
		actor.scale = Vector3.ONE * 0.85
		add_child(actor)
		actors.append(actor)
		var distance: float = 3.0 + index * 6.0
		actor.position = diorama.route.sample_baked(distance) + Vector3(0, 0.10, 0)
		var heading: Vector3 = diorama.route.sample_baked(distance + 0.1) - diorama.route.sample_baked(distance)
		actor.set_heading(heading)
		tracks.append({"distance": distance, "direction": 1.0})
	for location: Vector3 in [Vector3(-8, 0.1, -3.3), Vector3(6, 0.1, 2.5)]:
		var tower: ArcherDisplay3D = ArcherDisplay3D.new()
		tower.position = location
		add_child(tower)
		tower.arrow_released.connect(_on_arrow_released)
		towers.append(tower)
	_build_hud()

func _physics_process(delta: float) -> void:
	_time += delta
	for index in range(actors.size()):
		var actor: RiggedActor3D = actors[index]
		if actor.dead:
			continue
		var track: Dictionary = tracks[index]
		var speed: float = (float(actor.gait_profile.run_lab_speed) if _running else float(actor.gait_profile.walk_lab_speed)) * _speed if _motion else 0.0
		var distance: float = float(track.distance) + speed * delta * float(track.direction)
		var length: float = diorama.route.get_baked_length()
		if distance > length:
			distance = length - (distance - length)
			track.direction = -1.0
		elif distance < 0.0:
			distance = -distance
			track.direction = 1.0
		track.distance = distance
		var old: Vector3 = actor.position
		actor.position = diorama.route.sample_baked(distance) + Vector3(0, 0.10, 0)
		actor.animate_motion((actor.position - old) / maxf(delta, 0.001), delta)
	for tower in towers:
		tower.aim_at(actors[1].position, delta)
	_shot_timer -= delta
	if _shot_timer <= 0.0 and _motion:
		_shot_timer = 2.1
		for tower in towers:
			tower.shoot()
	for index in range(_projectiles.size() - 1, -1, -1):
		var shot: Dictionary = _projectiles[index]
		var node: Node3D = shot.node
		node.position += Vector3(shot.velocity) * delta
		shot.remaining = float(shot.remaining) - delta
		if float(shot.remaining) <= 0.0:
			node.queue_free()
			_projectiles.remove_at(index)
	for index in range(_revivals.size() - 1, -1, -1):
		var entry: Dictionary = _revivals[index]
		entry.remaining = float(entry.remaining) - delta
		if float(entry.remaining) <= 0.0:
			(entry.actor as RiggedActor3D).revive()
			_revivals.remove_at(index)
	_status.text = "23 ossos por personagem · caminhada/corrida com transição · %.1f× · %d FPS" % [Engine.time_scale, Engine.get_frames_per_second()]

func _on_arrow_released(origin: Vector3, _direction: Vector3) -> void:
	var arrow: Node3D = load("res://art/models/arrow_bow.glb").instantiate() as Node3D
	add_child(arrow)
	arrow.global_position = origin
	var target: Vector3 = actors[1].global_position + Vector3(0, 1.0, 0)
	var direction: Vector3 = (target - origin).normalized()
	arrow.look_at(target, Vector3.UP, true)
	_projectiles.append({"node": arrow, "velocity": direction * 13.0, "remaining": origin.distance_to(target) / 13.0})

func _build_hud() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var bars: Node2D = Node2D.new()
	bars.set_script(load("res://scripts/presentation3d/health_overlay.gd"))
	bars.set("camera", diorama.camera)
	bars.set("actors", actors)
	canvas.add_child(bars)
	var top: PanelContainer = PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 92
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.08, 0.94)
	style.content_margin_left = 28
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	top.add_theme_stylebox_override("panel", style)
	canvas.add_child(top)
	var column: VBoxContainer = VBoxContainer.new()
	top.add_child(column)
	var title: Label = Label.new()
	title.text = "IRON PATH  /  Laboratório 3D"
	title.add_theme_font_size_override("font_size", 28)
	title.modulate = Color("ead6a6")
	column.add_child(title)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 18)
	column.add_child(_status)
	var bottom: PanelContainer = PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -118
	bottom.add_theme_stylebox_override("panel", style)
	canvas.add_child(bottom)
	var bottom_column: VBoxContainer = VBoxContainer.new()
	bottom.add_child(bottom_column)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bottom_column.add_child(row)
	_add_button(row, "Caminhar", func() -> void: _running = false; _speed = 1.0; _motion = true)
	_add_button(row, "Correr", func() -> void: _running = true; _speed = 1.0; _motion = true)
	_add_button(row, "Slow", func() -> void: _running = false; _speed = 0.5; _motion = true)
	_add_button(row, "Idle", func() -> void: _motion = false)
	_add_button(row, "1× / 2×", func() -> void: Engine.time_scale = 2.0 if Engine.time_scale == 1.0 else 1.0)
	_pause_button = _add_button(row, "Pausar", _toggle_pause)
	_add_button(row, "Reação", func() -> void: actors[1].react_to_hit())
	_add_button(row, "Morte", _test_death)
	var help_label: Label = Label.new()
	help_label.text = "Prova P1: modelos e cenário 3D reais. Esta arena valida a apresentação; a campanha está em desenvolvimento."
	help_label.add_theme_font_size_override("font_size", 17)
	bottom_column.add_child(help_label)

func _add_button(row: HBoxContainer, title: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(125, 48)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	row.add_child(button)
	return button

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	_pause_button.text = "Continuar" if get_tree().paused else "Pausar"

func _test_death() -> void:
	if not actors[1].dead:
		actors[1].die()
		_revivals.append({"actor": actors[1], "remaining": 2.0})

func _exit_tree() -> void:
	Engine.time_scale = 1.0
