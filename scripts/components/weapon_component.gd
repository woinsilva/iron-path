class_name WeaponComponent extends Node2D

@export var projectile_scene: PackedScene
@export var damage: float = 5.0
@export var damage_type: int = 0
@export var attack_cooldown: float = 1.0
@export var splash_radius: float = 0.0
@export var effect_data: Array = [] # [type, power, duration]

var current_cooldown: float = 0.0
@onready var targeting: TargetingComponent = $"../TargetingComponent"

func _process(delta: float) -> void:
	if current_cooldown > 0:
		current_cooldown -= delta
		return
		
	var target = targeting.get_target()
	if target:
		fire(target)
		current_cooldown = attack_cooldown

func fire(target: Node2D) -> void:
	if not projectile_scene:
		return
		
	if get_parent().has_method("play_attack"):
		get_parent().play_attack()
	var proj = projectile_scene.instantiate() as Projectile
	var root = get_tree().get_first_node_in_group("projectile_root")
	if root:
		root.add_child(proj)
	else:
		get_tree().current_scene.add_child(proj)
		
	proj.global_position = global_position
	proj.setup(target, damage, damage_type, effect_data, splash_radius, get_instance_id())
