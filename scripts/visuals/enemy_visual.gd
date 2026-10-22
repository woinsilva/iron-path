extends AnimatedSprite2D
## Presentation follows movement; never changes the enemy path, hitbox or health.

@export var walk_texture: Texture2D

var _previous_position: Vector2
var _base_position: Vector2
var _step_phase: float = 0.0
var _hit_tween: Tween

func _ready() -> void:
	_previous_position = get_parent().global_position
	_base_position = position
	sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("walk")
	sprite_frames.set_animation_speed("walk", 8.0)
	var cell_size: Vector2 = walk_texture.get_size() / 2.0
	for index in range(4):
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = walk_texture
		atlas.region = Rect2(Vector2(index % 2, index >> 1) * cell_size, cell_size)
		sprite_frames.add_frame("walk", atlas)
	play("walk")

func _process(delta: float) -> void:
	var world_position: Vector2 = get_parent().global_position
	get_parent().z_index = clampi(int(world_position.y), 0, 2000)
	var displacement: Vector2 = world_position - _previous_position
	_previous_position = world_position
	if displacement.length_squared() < 0.001:
		pause()
		position = _base_position
		return
	if absf(displacement.x) > 0.1:
		flip_h = displacement.x < 0.0
	if not is_playing():
		play("walk")
	speed_scale = clampf(displacement.length() / maxf(delta, 0.001) / 100.0, 0.4, 1.8)
	_step_phase += displacement.length() * 0.15
	position = _base_position + Vector2(0.0, sin(_step_phase) * 1.5)

func flash_hit() -> void:
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()
	modulate = Color(1.45, 1.18, 1.05)
	_hit_tween = create_tween()
	_hit_tween.tween_property(self, "modulate", Color.WHITE, 0.12)
