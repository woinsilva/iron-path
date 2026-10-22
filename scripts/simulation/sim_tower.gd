class_name SimTowerV2 extends RefCounted

enum State { BUILDING, READY, UPGRADING }
var id: int
var pad: int
var type_id: String
var position: Vector3
var state: State = State.BUILDING
var level: int = 1
var branch: String = ""
var investment: int = 0
var work_paid: int = 0
var work_ticks: int = 0
var work_elapsed: int = 0
var pending_level: int = 1
var pending_branch: String = ""
var attack_sequence: int = 0
var focus_target: int = -1
var focus_stacks: int = 0
var ready_tick: int = 0
var last_support_pulse: int = -1
var cooldown_until: int = 0
var windup_until: int = 0
var pending_target: int = -1
var priority: String = "first"
var damage_done: float = 0.0
var control_delay: float = 0.0
var supported_attacks: int = 0
var kills: int = 0

func _init(sequence: int, slot: int, key: String, point: Vector3) -> void:
	id = sequence
	pad = slot
	type_id = key
	position = point
