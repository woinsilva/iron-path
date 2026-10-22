class_name RuinGuardianActorV2 extends ColossusActorV2
func _ready() -> void:
	stone_color = Color("405e57")
	face_color = Color("809386")
	metal_color = Color("a8aa79")
	core_color = Color("bc94e1")
	super._ready()
	for sign: float in [-1, 1]:
		_block("head", Vector3(0.18, 0.8, 0.25), Vector3(sign * 0.4, 0.42, 0), SceneCraft3D.material(metal_color))
		_block("chest", Vector3(0.32, 0.22, 0.7), Vector3(sign * 0.65, 0.1, 0), SceneCraft3D.material(stone_color))
		_block("chest", Vector3(0.12, 0.6, 0.12), Vector3(sign * 0.65, 0.38, 0), core_material)
	_block("head", Vector3(0.26, 0.26, 0.12), Vector3(0, 0.34, 0.35), core_material)
	health_anchor.position.y = 2.35

func set_posture(kind: String, active: bool) -> void:
	var colors: Dictionary = {"posture_physical": "dcc07b", "posture_magic": "bc94e1", "aura": "77c8c1", "summon": "d39cae"}
	var tint: Color = Color(str(colors.get(kind, "bc94e1"))) if active else core_color
	core_material.albedo_color = tint
	core_material.emission = tint
