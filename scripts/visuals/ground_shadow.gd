extends Node2D

@export var radius: Vector2 = Vector2(24.0, 9.0)
@export_range(0.0, 1.0) var opacity: float = 0.28

func _draw() -> void:
	draw_set_transform(Vector2(5.0, 4.0), 0.0, radius)
	draw_circle(Vector2.ZERO, 1.0, Color(0.06, 0.10, 0.08, opacity))
