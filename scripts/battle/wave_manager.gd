class_name WaveManager extends Node

signal wave_started(wave_index: int)
signal wave_ended(wave_index: int)
signal all_waves_completed()

enum State { PREPARATION, WAVE_ACTIVE, INTERMISSION, VICTORY, DEFEAT }

var current_state: State = State.PREPARATION
var current_wave_index: int = 0
var total_waves: int = 1

@export var grunt_scene: PackedScene
var enemies_to_spawn: int = 0
var spawn_timer: float = 0.0

func _process(delta: float) -> void:
	if current_state == State.WAVE_ACTIVE:
		if enemies_to_spawn > 0:
			spawn_timer -= delta
			if spawn_timer <= 0:
				spawn_enemy()
				enemies_to_spawn -= 1
				spawn_timer = 1.0 # 1 segundo entre spawns
		else:
			# Checar se ainda existem inimigos vivos
			var enemies = get_tree().get_nodes_in_group("enemies")
			if enemies.size() == 0:
				end_wave()

func start_wave() -> void:
	if current_state != State.PREPARATION and current_state != State.INTERMISSION:
		return
	
	current_state = State.WAVE_ACTIVE
	enemies_to_spawn = 5 # Fixado para MVP
	spawn_timer = 1.0
	wave_started.emit(current_wave_index)

func spawn_enemy() -> void:
	if not grunt_scene:
		return
	var map = get_tree().get_first_node_in_group("map")
	if map and map.has_node("EnemyPath"):
		var path = map.get_node("EnemyPath")
		var grunt = grunt_scene.instantiate()
		path.add_child(grunt)

func end_wave() -> void:
	wave_ended.emit(current_wave_index)
	current_wave_index += 1
	if current_wave_index >= total_waves:
		current_state = State.VICTORY
		all_waves_completed.emit()
	else:
		current_state = State.INTERMISSION
