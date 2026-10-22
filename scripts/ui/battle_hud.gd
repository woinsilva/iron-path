class_name BattleHUD extends CanvasLayer

@onready var lives_label: Label = $Panel/LivesLabel
@onready var coins_label: Label = $Panel/CoinsLabel
@onready var wave_label: Label = $Panel/WaveLabel
@onready var start_button: Button = $Panel/StartButton
@onready var status_label: Label = $CenterContainer/StatusLabel

var battle_manager: BattleManager

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	battle_manager = get_parent() as BattleManager
	if battle_manager:
		battle_manager.stats_changed.connect(_on_stats_changed)
		battle_manager.game_over.connect(_on_game_over)
		if battle_manager.wave_manager:
			battle_manager.wave_manager.wave_started.connect(_on_wave_started)
			
	start_button.pressed.connect(_on_start_pressed)
	$Panel/PauseButton.pressed.connect(_on_pause_pressed)
	$Panel/RestartButton.pressed.connect(_on_restart_pressed)

func _on_stats_changed(lives: int, coins: int) -> void:
	lives_label.text = "Vidas: " + str(lives)
	coins_label.text = "Moedas: " + str(coins)

func _on_wave_started(index: int) -> void:
	wave_label.text = "Onda: " + str(index + 1)
	start_button.disabled = true

func _on_start_pressed() -> void:
	if battle_manager and battle_manager.wave_manager:
		battle_manager.wave_manager.start_wave()

func _on_game_over(victory: bool) -> void:
	status_label.visible = true
	if victory:
		status_label.text = "VITÓRIA!"
		status_label.modulate = Color(0, 1, 0)
	else:
		status_label.text = "DERROTA!"
		status_label.modulate = Color(1, 0, 0)

func _on_pause_pressed() -> void:
	if battle_manager.wave_manager.current_state in [WaveManager.State.VICTORY, WaveManager.State.DEFEAT]:
		return
	get_tree().paused = not get_tree().paused
	$Panel/PauseButton.text = "Continuar" if get_tree().paused else "Pausar"
	start_button.disabled = get_tree().paused or battle_manager.wave_manager.current_state != WaveManager.State.PREPARATION

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
