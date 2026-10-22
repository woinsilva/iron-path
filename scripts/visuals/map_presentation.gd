extends Node2D
## Painted terrain plus a road drawn from the actual enemy route.

@onready var route: Path2D = $EnemyPath

func _ready() -> void:
	queue_redraw()

func _stroke(points: PackedVector2Array, width: float, color: Color, offset: Vector2) -> void:
	var shifted: PackedVector2Array = PackedVector2Array()
	for point in points:
		shifted.append(point + offset)
	draw_polyline(shifted, color, width, true)
	for index in range(route.curve.point_count):
		draw_circle(route.curve.get_point_position(index) + offset, width * 0.5, color)

func _draw() -> void:
	if not is_instance_valid(route):
		return
	var points: PackedVector2Array = route.curve.get_baked_points()
	_stroke(points, 106.0, Color(0.10, 0.17, 0.10, 0.28), Vector2(4, 10))
	_stroke(points, 98.0, Color("796345"), Vector2(0, 3))
	_stroke(points, 92.0, Color("c49c62"), Vector2.ZERO)
	_stroke(points, 76.0, Color("d2ad74"), Vector2(0, -3))
	# Fixed seed keeps decoration stable between runs.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42107
	var distance: float = 24.0
	while distance < route.curve.get_baked_length() - 30.0:
		var center: Vector2 = route.curve.sample_baked(distance)
		var tangent: Vector2 = (route.curve.sample_baked(distance + 2.0) - center).normalized()
		var normal: Vector2 = tangent.orthogonal()
		var edge: float = rng.randf_range(34.0, 40.0) * (-1.0 if rng.randf() < 0.5 else 1.0)
		var pebble: Vector2 = center + normal * edge
		draw_circle(pebble + Vector2(1, 2), 3.2, Color(0.29, 0.25, 0.18, 0.30))
		draw_circle(pebble, 2.4, Color("e3c995"))
		var fleck: Vector2 = center + normal * rng.randf_range(-25.0, 25.0)
		draw_line(fleck, fleck + tangent * rng.randf_range(3.0, 9.0), Color(0.48, 0.34, 0.19, 0.13), 1.4, true)
		distance += rng.randf_range(14.0, 28.0)
