class_name TargetingComponent extends Area2D

enum TargetLayer { GROUND, AIR, BOTH }
enum Priority { FIRST, LAST, STRONGEST, WEAKEST }

@export var range_radius: float = 150.0
@export var target_layer: TargetLayer = TargetLayer.BOTH
@export var target_priority: Priority = Priority.FIRST

var enemies_in_range: Array[Node2D] = []

func _ready() -> void:
	var shape = CircleShape2D.new()
	shape.radius = range_radius
	var col = CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies"):
		if not enemies_in_range.has(parent):
			enemies_in_range.append(parent)

func _on_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent in enemies_in_range:
		enemies_in_range.erase(parent)

func get_target() -> Node2D:
	# Limpa inimigos inválidos
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	
	if enemies_in_range.is_empty():
		return null
		
	var valid_enemies = []
	for e in enemies_in_range:
		if e is Enemy:
			if target_layer == TargetLayer.BOTH or e.movement_layer == target_layer:
				valid_enemies.append(e)
				
	if valid_enemies.is_empty():
		return null
		
	var best_target = valid_enemies[0]
	
	for enemy in valid_enemies:
		var e = enemy as Enemy
		var best = best_target as Enemy
		
		match target_priority:
			Priority.FIRST:
				if e.progress > best.progress:
					best_target = e
			Priority.LAST:
				if e.progress < best.progress:
					best_target = e
			Priority.STRONGEST:
				if e.health_component.current_health > best.health_component.current_health:
					best_target = e
			Priority.WEAKEST:
				if e.health_component.current_health < best.health_component.current_health:
					best_target = e
				
	return best_target
