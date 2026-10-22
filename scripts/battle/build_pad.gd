class_name BuildPad extends Area2D

signal pad_selected(pad: BuildPad)

var is_occupied: bool = false
var current_tower: Node2D = null

enum PadState { EMPTY, BUILDING, READY }
var state: PadState = PadState.EMPTY
var build_time: float = 0.0
var current_build_time: float = 0.0
var total_investment: int = 0
var tower_type_id: String = ""

func _ready() -> void:
	input_event.connect(_on_input_event)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pad_selected.emit(self)

func has_tower() -> bool:
	return is_occupied

func _process(delta: float) -> void:
	queue_redraw()
	if state == PadState.BUILDING:
		current_build_time += delta
		if current_build_time >= build_time:
			finish_build()

func build_tower(tower_node: Node2D, t_time: float, cost: int, t_id: String) -> void:
	if is_occupied:
		return
	is_occupied = true
	state = PadState.BUILDING
	current_tower = tower_node
	build_time = t_time
	current_build_time = 0.0
	total_investment = cost
	tower_type_id = t_id
	
	add_child(tower_node)
	tower_node.position = Vector2.ZERO
	# Desativa ataque enquanto constrói
	if tower_node.has_node("WeaponComponent"):
		tower_node.get_node("WeaponComponent").set_process(false)

func finish_build() -> void:
	state = PadState.READY
	if current_tower and current_tower.has_node("WeaponComponent"):
		current_tower.get_node("WeaponComponent").set_process(true)

func clear_tower() -> void:
	if current_tower:
		current_tower.queue_free()
	current_tower = null
	is_occupied = false
	state = PadState.EMPTY
	total_investment = 0
	tower_type_id = ""

func _draw() -> void:
	if state == PadState.BUILDING:
		draw_rect(Rect2(-34, 36, 68, 10), Color("202832"))
		var ratio: float = clampf(current_build_time / maxf(build_time, 0.001), 0.0, 1.0)
		draw_rect(Rect2(-32, 38, 64 * ratio, 6), Color("f29e4c"))
