class_name Enemy extends PathFollow2D

@onready var health_component: HealthComponent = $HealthComponent
@onready var movement_component: MovementComponent = $MovementComponent

@export var reward: int = 10
@export var leak_damage: int = 1
@export var movement_layer: TargetingComponent.TargetLayer = TargetingComponent.TargetLayer.GROUND

func _ready() -> void:
	health_component.died.connect(_on_died)
	movement_component.reached_end.connect(_on_reached_end)

func _on_died() -> void:
	# Enviar sinal para GameSession ou BattleManager para dar dinheiro
	var battle = get_tree().get_first_node_in_group("battle_manager")
	if battle and battle.has_method("add_coins"):
		battle.add_coins(reward)
	queue_free()

func _on_reached_end() -> void:
	var battle = get_tree().get_first_node_in_group("battle_manager")
	if battle and battle.has_method("take_leak_damage"):
		battle.take_leak_damage(leak_damage)
	queue_free()
