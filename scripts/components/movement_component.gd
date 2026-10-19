class_name MovementComponent extends Node

signal reached_end()

@export var speed: float = 100.0
var path_follow: PathFollow2D = null

var current_slow: float = 0.0
var is_moving: bool = true

func _ready() -> void:
	path_follow = get_parent() as PathFollow2D

func _process(delta: float) -> void:
	if path_follow and is_moving:
		# Floor speed to 35% of base
		var effective_speed = max(speed * 0.35, speed * (1.0 - current_slow))
		path_follow.progress += effective_speed * delta
		if path_follow.progress_ratio >= 1.0:
			reached_end.emit()
			# Normal logic should queue_free the enemy, handled by parent
