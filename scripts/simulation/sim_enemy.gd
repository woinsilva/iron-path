class_name SimEnemyV2 extends RefCounted

var id: int
var type_id: String
var health: float
var maximum_health: float
var burrow_distance: float = 0
var burrow_speed: float = 0
var speed: float
var magic_resistance: float = 0.0
var armor: float
var reward: int
var leak: int
var layer: String
var distance: float = 0.0
var position: Vector3 = Vector3.ZERO
var alive: bool = true
var route_id: int = 0
var spawned_tick: int = 0
var statuses: Array[Dictionary] = []
var boss: bool = false
var ability: Dictionary = {}
var next_ability_tick: int = 0
var ability_until: int = 0
var rally_until: int = 0
var pending_ability: String = "rally"
var ability_shields_left: int = 0
var ability_cycle_index: int = 0
var shield_until: int = 0
var summons_spawned: int = 0
var summoner_id: int = -1
var shield: float = 0
var maximum_shield: float = 0
var shield_recharges_left: int = 0
var shield_recharge_ticks: int = 0
var last_damage_tick: int = -1
var support: Dictionary = {}
var support_casts: int = 0
var next_support_tick: int = 0

func _init(sequence: int, key: String, definition: Dictionary) -> void:
	var barrier: Dictionary = definition.get("shield", {})
	maximum_shield = maxf(0, float(barrier.get("amount", 0)))
	shield = maximum_shield
	shield_recharges_left = maxi(0, int(barrier.get("recharges", 0)))
	shield_recharge_ticks = maxi(1, int(round(float(barrier.get("delay", 5)) * 60)))
	support = definition.get("support", {}).duplicate(true)
	boss = bool(definition.get("boss", false))
	ability = definition.get("ability", {}).duplicate(true)
	assert(ability.is_empty() or str(ability.kind) in ["rally", "forge_cycle", "summon_limited", "ruin_cycle"], "Enemy ability requires an implemented rule")
	ability_shields_left = int(ability.get("shield_casts", 0))
	id = sequence
	type_id = key
	maximum_health = float(definition.hp)
	health = maximum_health
	speed = float(definition.speed)
	burrow_distance = maxf(0, float(definition.get("burrow_distance", 0)))
	burrow_speed = maxf(0, float(definition.get("burrow_speed", speed)))
	armor = float(definition.get("armor", 0.0))
	magic_resistance = clampf(float(definition.get("magic_resistance", 0.0)), 0.0, 0.9)
	reward = int(definition.reward)
	leak = int(definition.leak)
	layer = str(definition.layer)

func underground() -> bool:
	return distance < burrow_distance
