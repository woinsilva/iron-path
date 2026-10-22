class_name BuildManager extends Node

@export var archer_scene: PackedScene
@export var tower_cost: int = 50
@export var tower_build_time: float = 3.0

func can_build(pad: BuildPad, cost: int, current_coins: int) -> bool:
	if not is_instance_valid(pad) or cost < 0 or pad.has_tower():
		return false
	if current_coins < cost:
		return false
	return true

func build_tower(pad: BuildPad, tower_type: String) -> bool:
	if not is_instance_valid(pad) or pad.has_tower() or archer_scene == null or tower_type != "archer":
		return false
		
	# MVP fixado em Arqueira
	var tower = archer_scene.instantiate()
	pad.build_tower(tower, tower_build_time, tower_cost, tower_type)
	return true
