class_name HealthComponent extends Node

signal died()
signal health_changed(current: float, max_health: float)

@export var max_health: float = 100.0
@export var armor: float = 0.0

var current_health: float

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float, damage_type: int = 0) -> void:
	# Dano físico (0) sofre armadura integral, Mágico (1) ignora 50%, Puro (2) ignora 100%
	var effective_armor = armor
	if damage_type == 1:
		effective_armor *= 0.5
	elif damage_type == 2:
		effective_armor = 0.0
		
	var final_damage = max(1.0, amount - effective_armor)
	current_health -= final_damage
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()
