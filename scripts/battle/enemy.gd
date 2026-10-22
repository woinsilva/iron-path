class_name Enemy extends PathFollow2D

@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var movement_component: MovementComponent = $MovementComponent

@export var reward: int = 10
@export var leak_damage: int = 1
@export var movement_layer: TargetingComponent.TargetLayer = TargetingComponent.TargetLayer.GROUND

var resolved: bool = false
var _last_visual_health: float = -1.0

func _ready() -> void:
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	_on_health_changed(health_component.current_health, health_component.max_health)
	movement_component.reached_end.connect(_on_reached_end)

func _on_died() -> void:
	if resolved:
		return
	resolved = true
	# Enviar sinal para GameSession ou BattleManager para dar dinheiro
	var battle = get_tree().get_first_node_in_group("battle_manager")
	if battle and battle.has_method("add_coins"):
		battle.add_coins(reward)
	queue_free()

func _on_reached_end() -> void:
	if resolved:
		return
	resolved = true
	var battle = get_tree().get_first_node_in_group("battle_manager")
	if battle and battle.has_method("take_leak_damage"):
		battle.take_leak_damage(leak_damage)
	queue_free()

func _on_health_changed(current: float, maximum: float) -> void:
	if _last_visual_health >= 0.0 and current < _last_visual_health:
		$Sprite2D.flash_hit()
	_last_visual_health = current
	health_bar.max_value = maxf(1.0, maximum)
	health_bar.value = clampf(current, 0.0, maximum)
