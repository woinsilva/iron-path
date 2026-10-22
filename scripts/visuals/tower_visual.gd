extends Node2D
## Recoil is cosmetic. Combat timing remains in WeaponComponent.

var _recoil: Tween

func _ready() -> void:
	z_index = clampi(int(global_position.y), 0, 2000)

func play_attack() -> void:
	if _recoil and _recoil.is_valid():
		_recoil.kill()
	var visual: Sprite2D = $Sprite2D
	visual.position = Vector2(0.0, -32.0)
	visual.rotation = -0.025
	_recoil = create_tween()
	_recoil.set_parallel(true)
	_recoil.tween_property(visual, "position:y", -35.0, 0.06)
	_recoil.tween_property(visual, "rotation", 0.025, 0.06)
	_recoil.chain().tween_property(visual, "position:y", -32.0, 0.15)
	_recoil.parallel().tween_property(visual, "rotation", 0.0, 0.15)
