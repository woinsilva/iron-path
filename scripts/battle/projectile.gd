class_name Projectile extends Area2D

@export var speed: float = 400.0
var damage: float = 5.0
var damage_type: int = 0
var target: Node2D = null
var direction: Vector2 = Vector2.ZERO

var effect_type: int = 0
var effect_power: float = 0.0
var effect_duration: float = 0.0
var splash_radius: float = 0.0
var tower_id: int = 0

func setup(_target: Node2D, _damage: float, _damage_type: int, _effect: Array = [], _splash: float = 0.0, _source_id: int = 0) -> void:
	target = _target
	damage = _damage
	damage_type = _damage_type
	if _effect.size() >= 3:
		effect_type = _effect[0]
		effect_power = _effect[1]
		effect_duration = _effect[2]
	splash_radius = _splash
	tower_id = _source_id
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	
	position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if is_instance_valid(target) and area.get_parent() == target:
		apply_damage(target)

func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(target) and body == target:
		explode(target)

func explode(initial_target: Node2D) -> void:
	if splash_radius > 0:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.global_position.distance_to(global_position) <= splash_radius:
				apply_damage(enemy)
	else:
		apply_damage(initial_target)
	queue_free()

func apply_damage(enemy: Node2D) -> void:
	if enemy.has_node("HealthComponent"):
		var health = enemy.get_node("HealthComponent") as HealthComponent
		health.take_damage(damage, damage_type)
	if effect_type > 0 and enemy.has_node("StatusComponent"):
		var status = enemy.get_node("StatusComponent")
		status.apply_effect(effect_type, effect_power, effect_duration, tower_id)
