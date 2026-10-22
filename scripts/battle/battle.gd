class_name BattleManager extends Node

@onready var wave_manager: WaveManager = $WaveManager
@onready var build_manager: BuildManager = $BuildManager
@onready var map_root: Node2D = $MapRoot
@onready var projectile_root: Node2D = $ProjectileRoot

var lives: int = 20
var coins: int = 150

signal stats_changed(lives: int, coins: int)
signal game_over(victory: bool)

func _ready() -> void:
	add_to_group("battle_manager")
	wave_manager.all_waves_completed.connect(_on_victory)
	
	# Connectar os pads do mapa
	if map_root.get_child_count() > 0:
		var map = map_root.get_child(0)
		map.add_to_group("map")
		var pads = map.get_node_or_null("Pads")
		if pads:
			for pad in pads.get_children():
				if pad is BuildPad:
					pad.pad_selected.connect(_on_pad_selected)
					
	call_deferred("emit_stats")

func emit_stats() -> void:
	stats_changed.emit(lives, coins)

func add_coins(amount: int) -> void:
	if wave_manager.current_state in [WaveManager.State.VICTORY, WaveManager.State.DEFEAT]:
		return
	coins += amount
	emit_stats()

func take_leak_damage(amount: int) -> void:
	if wave_manager.current_state in [WaveManager.State.VICTORY, WaveManager.State.DEFEAT]:
		return
	lives = maxi(0, lives - amount)
	emit_stats()
	if lives <= 0:
		lives = 0
		_on_defeat()

func _on_pad_selected(pad: BuildPad) -> void:
	if get_tree().paused or wave_manager.current_state in [WaveManager.State.VICTORY, WaveManager.State.DEFEAT]:
		return
	var cost: int = build_manager.tower_cost
	if build_manager.can_build(pad, cost, coins):
		if not build_manager.build_tower(pad, "archer"):
			return
		coins -= cost
		emit_stats()

func _on_victory() -> void:
	wave_manager.current_state = WaveManager.State.VICTORY
	game_over.emit(true)
	get_tree().paused = true

func _on_defeat() -> void:
	wave_manager.current_state = WaveManager.State.DEFEAT
	game_over.emit(false)
	get_tree().paused = true
