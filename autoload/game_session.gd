## Autoload: GameSession
## Manages session-wide game state: current map, difficulty, coins, lives.
## Does NOT run per-enemy logic each frame.
class_name GameSessionService
extends Node


## Emitted when coins change.
signal coins_changed(new_amount: int)
## Emitted when lives change.
signal lives_changed(new_amount: int)
## Emitted when game speed changes.
signal speed_changed(new_speed: float)


## Current map id being played.
var current_map_id: StringName = &""
## Current difficulty index (0=Easy, 1=Normal, 2=Hard).
var current_difficulty: int = 1

var _coins: int = 0
var _lives: int = 20
var _game_speed: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Returns current coin count.
func get_coins() -> int:
	return _coins


## Adds coins (amount can be negative for spending). Returns false if
## the result would be negative.
func add_coins(amount: int) -> bool:
	var result: int = _coins + amount
	if result < 0:
		return false
	_coins = result
	coins_changed.emit(_coins)
	return true


## Sets coins to a specific value. Used during initialization.
func set_coins(amount: int) -> void:
	assert(amount >= 0, "Coins cannot be negative")
	_coins = amount
	coins_changed.emit(_coins)


## Returns current life count.
func get_lives() -> int:
	return _lives


## Removes lives. Returns remaining lives.
func remove_lives(amount: int) -> int:
	assert(amount >= 0, "Cannot remove negative lives")
	_lives = maxi(0, _lives - amount)
	lives_changed.emit(_lives)
	return _lives


## Sets lives to a specific value. Used during initialization.
func set_lives(amount: int) -> void:
	assert(amount >= 0, "Lives cannot be negative")
	_lives = amount
	lives_changed.emit(_lives)


## Returns current game speed multiplier (1.0 or 2.0).
func get_game_speed() -> float:
	return _game_speed


## Toggles between 1× and 2× speed.
func toggle_speed() -> void:
	_game_speed = 1.0 if _game_speed >= 2.0 else 2.0
	speed_changed.emit(_game_speed)


## Resets session state for a new battle.
func reset_session(map_id: StringName, difficulty: int, starting_coins: int, starting_lives: int) -> void:
	current_map_id = map_id
	current_difficulty = clampi(difficulty, 0, 2)
	_coins = starting_coins
	_lives = starting_lives
	_game_speed = 1.0
	coins_changed.emit(_coins)
	lives_changed.emit(_lives)
	speed_changed.emit(_game_speed)
