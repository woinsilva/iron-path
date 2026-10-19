class_name BuildManager extends Node

@export var archer_scene: PackedScene

func can_build(pad: BuildPad, cost: int, current_coins: int) -> bool:
	if pad.has_tower():
		return false
	if current_coins < cost:
		return false
	return true

func build_tower(pad: BuildPad, tower_type: String) -> bool:
	if pad.has_tower():
		return false
		
	# MVP fixado em Arqueira
	var tower = archer_scene.instantiate()
	pad.build_tower(tower)
	return true
