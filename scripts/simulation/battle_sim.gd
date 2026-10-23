class_name BattleSimV2 extends RefCounted
## Fixed tick, node-free simulation. Presentation consumes events; never grants damage/rewards.

enum State { PREPARATION, WAVE_ACTIVE, INTERMISSION, VICTORY, DEFEAT }
const TICK_RATE: int = 60
const STEP: float = 1.0 / TICK_RATE
var state: State = State.PREPARATION
var paused: bool = false
var ticks: int = 0
var coins: int = 200
var lives: int = 20
var initial_lives: int = 20
var wave_index: int = 0
var interval_until: int = 0
var enemies: Dictionary = {}
var towers: Dictionary = {}
var projectiles: Dictionary = {}
var fields: Dictionary = {}
var _active_speed_auras: Array[SimEnemyV2] = []
var pads: PackedVector3Array = PackedVector3Array()
var routes: Array[Curve3D] = []
var catalog: Dictionary
var movement_rules: Dictionary = {}
var placement_rules: Dictionary = {}
var air_routes: Array[int] = []
## Ground the stage forbids for building besides the roads (rivers, cliffs), as XZ rectangles.
var blocked_zones: Array[Rect2] = []
var waves: Array = []
var events: Array[Dictionary] = []
var kills: int = 0
var leaks: int = 0
var leaked_types: Dictionary = {}
var leaked_layers: Dictionary = {}
var earned: int = 0
var spent: int = 0
var spawned: int = 0
var useful_damage: float = 0.0
var control_delay: float = 0.0
var _next_id: int = 1
var _spawn_queue: Array[Dictionary] = []
var _spawn_cursor: int = 0
var _pad_locks: Dictionary = {}
var _accumulator: float = 0.0

func _init(definitions: Dictionary, route_list: Array[Curve3D], build_pads: PackedVector3Array, wave_list: Array, starting_coins: int = 200, starting_lives: int = 20) -> void:
	catalog = definitions
	movement_rules = definitions.get("movement", {"lane_spacing": 0.6, "body_radius": 0.42, "boss_scale": 1.8, "lane_change_speed": 1.8})
	placement_rules = definitions.get("placement", {"road_clearance": 1.9, "tower_spacing": 1.85, "bounds": [-20.0, 20.0, -11.0, 11.0]})
	routes = route_list
	pads = build_pads
	waves = wave_list
	coins = starting_coins
	lives = starting_lives
	initial_lives = starting_lives

static func load_catalog() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/core.json").trim_prefix("\ufeff")) as Dictionary

func _sequence() -> int:
	var value: int = _next_id
	_next_id += 1
	return value

func _terminal() -> bool:
	return state == State.VICTORY or state == State.DEFEAT

func advance(delta: float) -> void:
	if paused or _terminal():
		return
	_accumulator += maxf(0.0, delta)
	while _accumulator + 0.00000001 >= STEP:
		_accumulator -= STEP
		step()
		if _terminal():
			break

func step() -> void:
	if paused or _terminal():
		return
	ticks += 1
	_update_work()
	if state == State.INTERMISSION and ticks >= interval_until:
		_start_wave()
	if state == State.WAVE_ACTIVE:
		while _spawn_cursor < _spawn_queue.size() and int(_spawn_queue[_spawn_cursor].tick) <= ticks:
			var entry: Dictionary = _spawn_queue[_spawn_cursor]
			spawn_enemy(str(entry.enemy), int(entry.route))
			_spawn_cursor += 1
	_update_enemy_abilities()
	_update_enemy_support()
	_update_fields()
	_move_enemies()
	if _terminal():
		return
	_update_statuses()
	_update_supports()
	_update_weapons()
	_update_projectiles()
	if state == State.WAVE_ACTIVE and _spawn_cursor >= _spawn_queue.size() and enemies.is_empty():
		_finish_wave()

func start_first_wave() -> bool:
	if paused or state != State.PREPARATION or waves.is_empty():
		return false
	_start_wave()
	return true

func _start_wave() -> void:
	if _terminal() or wave_index >= waves.size():
		return
	state = State.WAVE_ACTIVE
	var wave: Dictionary = waves[wave_index]
	wave_index += 1
	_spawn_queue.clear()
	_spawn_cursor = 0
	var next_start: int = ticks
	for group: Dictionary in wave.groups:
		var start: int = ticks + int(round(float(group.at) * TICK_RATE)) if group.has("at") else next_start
		var spacing: int = maxi(1, int(round(float(group.interval) * TICK_RATE)))
		for index in range(int(group.count)):
			_spawn_queue.append({"tick": start + index * spacing, "enemy": str(group.enemy), "route": int(group.get("route", 0))})
		next_start = start + maxi(0, int(group.count) - 1) * spacing + 2 * TICK_RATE
	_spawn_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.tick) < int(b.tick))
	events.append({"kind": "wave_started", "wave": wave_index})

func _finish_wave() -> void:
	events.append({"kind": "wave_completed", "wave": wave_index})
	if wave_index >= waves.size():
		_end(State.VICTORY)
	else:
		state = State.INTERMISSION
		interval_until = ticks + int(round(float(waves[wave_index].get("interval", 8.0)) * TICK_RATE))
		events.append({"kind": "intermission", "until": interval_until})

func call_wave_early() -> bool:
	if paused or state != State.INTERMISSION:
		return false
	var bonus: int = mini(5, maxi(0, (interval_until - ticks) / TICK_RATE))
	coins += bonus
	earned += bonus
	_start_wave()
	return true

func _end(result: State) -> void:
	if _terminal():
		return
	state = result
	_spawn_queue.clear()
	projectiles.clear()
	fields.clear()
	_active_speed_auras.clear()
	events.append({"kind": "finished", "victory": state == State.VICTORY})

func spawn_enemy(type_id: String, route_index: int = 0, at_distance: float = 0.0, summoner_id: int = -1) -> SimEnemyV2:
	if _terminal() or not catalog.enemies.has(type_id) or route_index < 0 or route_index >= routes.size():
		return null
	var enemy: SimEnemyV2 = SimEnemyV2.new(_sequence(), type_id, catalog.enemies[type_id])
	enemy.route_id = route_index
	enemy.distance = clampf(at_distance, 0, maxf(0, routes[route_index].get_baked_length() - 0.1))
	enemy.position = routes[route_index].sample_baked(enemy.distance)
	enemy.summoner_id = summoner_id
	if summoner_id >= 0: enemy.reward = 0
	enemy.spawned_tick = ticks
	if not enemy.ability.is_empty(): enemy.next_ability_tick = ticks + int(round(float(enemy.ability.get("initial_delay", enemy.ability.cooldown)) * TICK_RATE))
	if not enemy.support.is_empty() and str(enemy.support.kind) == "heal": enemy.next_support_tick = ticks + int(round(float(enemy.support.period) * TICK_RATE))
	enemies[enemy.id] = enemy
	spawned += 1
	events.append({"kind": "spawned", "id": enemy.id, "type": type_id, "position": enemy.position})
	return enemy

func _move_enemies() -> void:
	for item: SimEnemyV2 in enemies.values():
		item.previous_distance = item.distance
		var movement: float = movement_factor(item)
		var was_underground: bool = item.underground()
		var pace: float = item.burrow_speed if was_underground else item.speed
		item.distance += pace * (1.0 + speed_aura_for(item)) * movement * STEP
		if was_underground and not item.underground():
			item.distance = item.burrow_distance
			events.append({"kind": "emerged", "id": item.id, "position": routes[item.route_id].sample_baked(item.distance)})
		if item.speed > 0.0 and movement < 1.0:
			var delay: float = (1.0 - movement) * STEP
			control_delay += delay
			var source: int = -1
			var strongest: float = 0.0
			for effect: Dictionary in item.statuses:
				if str(effect.kind) == "slow" and int(effect.until) > ticks and (float(effect.power) > strongest or (is_equal_approx(float(effect.power), strongest) and int(effect.source) < source)):
					strongest = float(effect.power)
					source = int(effect.source)
			if towers.has(source): (towers[source] as SimTowerV2).control_delay += delay
		var route: Curve3D = routes[item.route_id]
		item.position = route.sample_baked(minf(item.distance, route.get_baked_length()))
		if item.distance + 0.00001 >= route.get_baked_length():
			_resolve_enemy(item, false, -1)
			if lives <= 0:
				_end(State.DEFEAT)
				return
	_separate_enemies()

## Keeps walkers from passing through each other. Rules (range, splash, leaks) still use the road's centre line,
## so towers reach every lane exactly as before; lanes only decide who waits and where each body is drawn.
func _separate_enemies() -> void:
	var columns: Dictionary = {}
	for item: SimEnemyV2 in enemies.values():
		if item.underground(): continue
		# Flyers queue among themselves; ground walkers never wait for something overhead.
		var key: int = item.route_id * 2 + (1 if item.layer == "air" else 0)
		if not columns.has(key): columns[key] = []
		(columns[key] as Array).append(item)
	for key: int in columns:
		var column: Array = columns[key]
		column.sort_custom(func(a: SimEnemyV2, b: SimEnemyV2) -> bool: return a.distance > b.distance or (is_equal_approx(a.distance, b.distance) and a.id < b.id))
		var route: Curve3D = routes[(column[0] as SimEnemyV2).route_id]
		for index in range(column.size()):
			var item: SimEnemyV2 = column[index]
			var blocker: SimEnemyV2 = _lane_blocker(column, index, item.target_lateral)
			if blocker != null:
				var lane: float = _free_lane(column, index, item)
				if is_nan(lane):
					item.distance = maxf(item.previous_distance, minf(item.distance, blocker.distance - _gap(item, blocker)))
				else:
					item.target_lateral = lane
			elif not is_zero_approx(item.target_lateral) and _lane_open(column, index, item, 0.0):
				item.target_lateral = 0.0
			item.lateral = move_toward(item.lateral, item.target_lateral, float(movement_rules.lane_change_speed) * STEP)
			item.position = route.sample_baked(minf(item.distance, route.get_baked_length()))

func _gap(item: SimEnemyV2, other: SimEnemyV2) -> float:
	return float(movement_rules.body_radius) * ((float(movement_rules.boss_scale) if item.boss else 1.0) + (float(movement_rules.boss_scale) if other.boss else 1.0))

## Nearest walker ahead that shares this lane closely enough to be walked into.
func _lane_blocker(column: Array, index: int, lateral: float) -> SimEnemyV2:
	var item: SimEnemyV2 = column[index]
	for ahead in range(index - 1, -1, -1):
		var other: SimEnemyV2 = column[ahead]
		var gap: float = _gap(item, other)
		if other.distance - item.distance > gap: break
		if absf(other.lateral - lateral) < float(movement_rules.lane_spacing) * 0.6: return other
	return null

## True when nobody within body reach, ahead or behind, stands in or is heading for that lane.
## The column is sorted by distance, so the scan stops as soon as walkers are out of reach.
func _lane_open(column: Array, index: int, item: SimEnemyV2, lane: float) -> bool:
	var reach: float = float(movement_rules.body_radius) * 2.0 * float(movement_rules.boss_scale)
	var width: float = float(movement_rules.lane_spacing) * 0.6
	for direction: int in [-1, 1]:
		var other_index: int = index + direction
		while other_index >= 0 and other_index < column.size():
			var other: SimEnemyV2 = column[other_index]
			if absf(other.distance - item.distance) > reach: break
			if absf(other.distance - item.distance) <= _gap(item, other) and (absf(other.lateral - lane) < width or absf(other.target_lateral - lane) < width): return false
			other_index += direction
	return true

## Closest side lane with room to pass, or NAN when every lane is taken and the walker has to queue.
func _free_lane(column: Array, index: int, item: SimEnemyV2) -> float:
	var spacing: float = float(movement_rules.lane_spacing)
	var options: Array[float] = []
	if is_zero_approx(item.target_lateral): options.assign([-spacing, spacing])
	else: options.assign([0.0, -item.target_lateral])
	if item.id % 2 == 1: options.reverse()
	for lane: float in options:
		if is_equal_approx(lane, item.target_lateral): continue
		if _lane_open(column, index, item, lane): return lane
	return NAN

## Where the body is drawn: the centre line pushed sideways by the walker's lane.
func display_position(item: SimEnemyV2) -> Vector3:
	var route: Curve3D = routes[item.route_id]
	var length: float = route.get_baked_length()
	var at: float = minf(item.distance, length)
	var tangent: Vector3 = route.sample_baked(minf(length, at + 0.2)) - route.sample_baked(maxf(0.0, at - 0.2))
	tangent.y = 0
	if tangent.length_squared() < 0.000001: return item.position
	tangent = tangent.normalized()
	return item.position + Vector3(-tangent.z, 0, tangent.x) * item.lateral

func _resolve_enemy(enemy: SimEnemyV2, killed: bool, source: int) -> void:
	if not enemy.alive or not enemies.has(enemy.id):
		return
	enemy.alive = false
	enemies.erase(enemy.id)
	if killed:
		coins += enemy.reward
		earned += enemy.reward
		kills += 1
		if towers.has(source):
			(towers[source] as SimTowerV2).kills += 1
	else:
		lives = maxi(0, lives - enemy.leak)
		leaks += 1
		leaked_types[enemy.type_id] = int(leaked_types.get(enemy.type_id,0)) + 1
		leaked_layers[enemy.layer] = int(leaked_layers.get(enemy.layer,0)) + 1
	events.append({"kind": "killed" if killed else "leaked", "id": enemy.id, "position": enemy.position, "type": enemy.type_id})

func _pad_available(pad: int) -> bool:
	if paused or _terminal() or pad < 0 or pad >= pads.size() or int(_pad_locks.get(pad, -1)) == ticks:
		return false
	return true

func tower_on_pad(pad: int) -> SimTowerV2:
	for tower: SimTowerV2 in towers.values():
		if tower.pad == pad:
			return tower
	return null

## Free placement: anywhere on open ground, clear of every walking route, water and other towers.
func can_build_at(point: Vector3) -> bool:
	var bounds: Array = placement_rules.bounds
	if point.x < float(bounds[0]) or point.x > float(bounds[1]) or point.z < float(bounds[2]) or point.z > float(bounds[3]): return false
	for zone: Rect2 in blocked_zones:
		if zone.has_point(Vector2(point.x, point.z)): return false
	for index in range(routes.size()):
		if _is_air_route(index): continue
		var road: Curve3D = routes[index]
		if distance_xz(road.get_closest_point(point), point) < float(placement_rules.road_clearance): return false
	for tower: SimTowerV2 in towers.values():
		if distance_xz(tower.position, point) < float(placement_rules.tower_spacing): return false
	return true

## Builds at a free spot by turning it into a new pad, so upgrades, selling and tests keep using pad indices.
func build_at(point: Vector3, type_id: String) -> int:
	var spot: Vector3 = Vector3(point.x, 0, point.z)
	if paused or _terminal() or not can_build_at(spot) or not catalog.towers.has(type_id): return -1
	if coins < int(catalog.towers[type_id].levels[0].cost): return -1
	pads.append(spot)
	var pad: int = pads.size() - 1
	if not build(pad, type_id):
		pads.remove_at(pad)
		return -1
	return pad

## Routes flown over by air units; towers may stand under them.
func _is_air_route(index: int) -> bool:
	return index in air_routes

func build(pad: int, type_id: String) -> bool:
	if not _pad_available(pad) or tower_on_pad(pad) != null or not catalog.towers.has(type_id):
		return false
	var level: Dictionary = catalog.towers[type_id].levels[0]
	var cost: int = int(level.cost)
	if cost < 0 or coins < cost:
		return false
	var tower: SimTowerV2 = SimTowerV2.new(_sequence(), pad, type_id, pads[pad])
	tower.investment = cost
	tower.work_paid = cost
	tower.work_ticks = maxi(1, int(round(float(level.build) * TICK_RATE)))
	coins -= cost
	spent += cost
	towers[tower.id] = tower
	_pad_locks[pad] = ticks
	events.append({"kind": "build_started", "id": tower.id, "pad": pad, "type": type_id})
	return true

func next_upgrade(tower: SimTowerV2, requested_branch: String = "") -> Dictionary:
	if tower == null: return {}
	var definition: Dictionary = catalog.towers[tower.type_id]
	if tower.level < 3:
		if not requested_branch.is_empty() or tower.level >= definition.levels.size(): return {}
		return definition.levels[tower.level]
	var selected: String = requested_branch if tower.level == 3 else tower.branch
	if tower.level >= 4 and not requested_branch.is_empty() and requested_branch != tower.branch: return {}
	if not definition.get("branches", {}).has(selected): return {}
	var levels: Array = definition.branches[selected].levels
	var index: int = tower.level - 3
	return levels[index] if index < levels.size() else {}

func upgrade(pad: int, requested_branch: String = "") -> bool:
	var tower: SimTowerV2 = tower_on_pad(pad)
	if not _pad_available(pad) or tower == null or tower.state != SimTowerV2.State.READY: return false
	var next: Dictionary = next_upgrade(tower, requested_branch)
	if next.is_empty(): return false
	var cost: int = int(next.cost)
	if cost < 0 or coins < cost: return false
	coins -= cost
	spent += cost
	tower.investment += cost
	tower.work_paid = cost
	tower.work_ticks = maxi(1, int(round(float(next.build) * TICK_RATE)))
	tower.work_elapsed = 0
	tower.pending_level = tower.level + 1
	tower.pending_branch = requested_branch if tower.level == 3 else tower.branch
	tower.state = SimTowerV2.State.UPGRADING
	tower.windup_until = 0
	tower.pending_target = -1
	tower.focus_target = -1
	tower.focus_stacks = 0
	_pad_locks[pad] = ticks
	events.append({"kind": "upgrade_started", "id": tower.id})
	return true

func cancel_work(pad: int) -> bool:
	var tower: SimTowerV2 = tower_on_pad(pad)
	if not _pad_available(pad) or tower == null or tower.state == SimTowerV2.State.READY:
		return false
	var refund: int = tower.work_paid if float(tower.work_elapsed) / tower.work_ticks < 0.1 else int(floor(tower.work_paid * 0.7))
	coins += refund
	spent -= refund
	_pad_locks[pad] = ticks
	if tower.state == SimTowerV2.State.BUILDING:
		towers.erase(tower.id)
		events.append({"kind": "tower_removed", "id": tower.id})
	else:
		tower.investment -= tower.work_paid
		tower.work_paid = 0
		tower.pending_level = tower.level
		tower.pending_branch = tower.branch
		tower.state = SimTowerV2.State.READY
		events.append({"kind": "work_completed", "id": tower.id, "cancelled": true})
	return true

func sell(pad: int) -> bool:
	var tower: SimTowerV2 = tower_on_pad(pad)
	if not _pad_available(pad) or tower == null or tower.state != SimTowerV2.State.READY:
		return false
	var refund: int = int(floor(tower.investment * 0.6))
	coins += refund
	spent -= refund
	towers.erase(tower.id)
	_pad_locks[pad] = ticks
	events.append({"kind": "tower_removed", "id": tower.id})
	return true

func _update_work() -> void:
	for tower: SimTowerV2 in towers.values():
		if tower.state == SimTowerV2.State.READY:
			continue
		tower.work_elapsed += 1
		if tower.work_elapsed >= tower.work_ticks:
			tower.level = tower.pending_level
			tower.branch = tower.pending_branch
			tower.ready_tick = ticks
			tower.state = SimTowerV2.State.READY
			tower.work_paid = 0
			events.append({"kind": "work_completed", "id": tower.id})

func stats(tower: SimTowerV2) -> Dictionary:
	var definition: Dictionary = catalog.towers[tower.type_id]
	if tower.level <= 3: return definition.levels[tower.level - 1]
	return definition.branches[tower.branch].levels[tower.level - 4]

static func distance_xz(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _valid_target(tower: SimTowerV2, target: SimEnemyV2) -> bool:
	if target == null or not target.alive or target.underground():
		return false
	var layer: String = str(catalog.towers[tower.type_id].layer)
	return (layer == "both" or layer == target.layer) and distance_xz(tower.position, target.position) <= effective_range(tower) + 0.00001

func choose_target(tower: SimTowerV2) -> SimEnemyV2:
	var best: SimEnemyV2 = null
	for target: SimEnemyV2 in enemies.values():
		if not _valid_target(tower, target):
			continue
		if best == null:
			best = target
			continue
		var a: float = target.distance / routes[target.route_id].get_baked_length()
		var b: float = best.distance / routes[best.route_id].get_baked_length()
		if tower.priority == "last":
			a = -a
			b = -b
		elif tower.priority == "strongest":
			a = target.health
			b = best.health
		elif tower.priority == "weakest":
			a = -target.health
			b = -best.health
		if a > b or (is_equal_approx(a, b) and target.id < best.id):
			best = target
	return best

func _update_weapons() -> void:
	for tower: SimTowerV2 in towers.values():
		if tower.state != SimTowerV2.State.READY or str(catalog.towers[tower.type_id].layer) == "ally":
			continue
		if tower.focus_target >= 0 and not _valid_target(tower, enemies.get(tower.focus_target) as SimEnemyV2):
			tower.focus_target = -1
			tower.focus_stacks = 0
		if tower.pending_target >= 0:
			if ticks < tower.windup_until:
				continue
			var target: SimEnemyV2 = enemies.get(tower.pending_target) as SimEnemyV2
			tower.pending_target = -1
			if _valid_target(tower, target):
				_release(tower, target)
			else:
				events.append({"kind": "attack_cancelled", "id": tower.id})
			continue
		if ticks >= tower.cooldown_until:
			var target: SimEnemyV2 = choose_target(tower)
			if target:
				tower.pending_target = target.id
				tower.windup_until = ticks + maxi(1, int(round(attack_windup(tower) * TICK_RATE)))
				events.append({"kind": "windup", "id": tower.id, "target": target.id})

func _release(tower: SimTowerV2, target: SimEnemyV2) -> void:
	var definition: Dictionary = catalog.towers[tower.type_id]
	var properties: Dictionary = stats(tower)
	var buff: Dictionary = buffs_for(tower)
	var rate: float = float(properties.rate) * (1.0 + float(buff.haste))
	if rate <= 0.0: return
	var credited: Dictionary = {}
	for source: int in [int(buff.haste_source), int(buff.reach_source)]:
		if towers.has(source) and not credited.has(source):
			(towers[source] as SimTowerV2).supported_attacks += 1
			credited[source] = true
	tower.cooldown_until = ticks + maxi(1, int(round(TICK_RATE / rate)) - int(round(attack_windup(tower) * TICK_RATE)))
	tower.attack_sequence += 1
	var multiplier: float = 1.0
	var crit_every: int = int(properties.get("crit_every", 0))
	if crit_every > 0 and tower.attack_sequence % crit_every == 0:
		multiplier *= float(properties.get("crit_multiplier", 2.0))
	if properties.has("focus_step"):
		tower.focus_stacks = tower.focus_stacks + 1 if tower.focus_target == target.id else 0
		tower.focus_target = target.id
		multiplier *= minf(float(properties.focus_cap), 1.0 + tower.focus_stacks * float(properties.focus_step))
	var targets: Array[SimEnemyV2] = [target]
	var count: int = clampi(int(properties.get("multishot", 1)), 1, 3)
	var candidates: Array[SimEnemyV2] = []
	for enemy: SimEnemyV2 in enemies.values():
		if enemy.id != target.id and _valid_target(tower, enemy): candidates.append(enemy)
	candidates.sort_custom(func(a: SimEnemyV2, b: SimEnemyV2) -> bool: return a.id < b.id)
	for enemy: SimEnemyV2 in candidates:
		if targets.size() >= count: break
		targets.append(enemy)
	var first_projectile: int = -1
	for victim: SimEnemyV2 in targets:
		var id: int = _sequence()
		if first_projectile < 0: first_projectile = id
		var shot: Dictionary = {
			"id": id, "source": tower.id, "family": tower.type_id, "target": victim.id,
			"position": tower.position, "origin": tower.position, "impact_point": victim.position,
			"damage": float(properties.damage) * multiplier, "damage_type": str(definition.damage_type),
			"speed": float(properties.get("projectile", definition.projectile)),
			"splash": float(properties.get("splash", definition.splash)), "layer": str(definition.layer),
			"effects": properties.get("effects", []).duplicate(true),
			"ground_target": bool(properties.get("ground_target", false)),
			"penetration": float(properties.get("penetration", 0.0)),
			"chain_count": clampi(int(properties.get("chain_count", 1)), 1, 5),
			"chain_radius": float(properties.get("chain_radius", 0.0)),
			"chain_falloff": clampf(float(properties.get("chain_falloff", 1.0)), 0.0, 1.0),
			"pierce_count": clampi(int(properties.get("pierce_count", 1)), 1, 4),
			"pierce_width": minf(0.8, float(properties.get("pierce_width", 0.0))),
			"pierce_falloff": clampf(float(properties.get("pierce_falloff", 1.0)), 0.0, 1.0),
			"range": effective_range(tower),
			"spread_count": clampi(int(properties.get("spread_count", 1)), 1, 4),
			"spread_radius": float(properties.get("spread_radius", 0.0)),
			"field": properties.get("field", {}).duplicate(true),
		}
		projectiles[id] = shot
	events.append({"kind": "released", "id": tower.id, "projectile": first_projectile, "target": target.id})
	if properties.has("focus_step"):
		events.append({"kind": "chain_link", "from": tower.position + Vector3(0, 2.5, 0), "to": target.position + Vector3(0, 1, 0), "family": "arcane", "duration": minf(0.4, 1.0 / rate)})

func _update_projectiles() -> void:
	for shot: Dictionary in projectiles.values():
		var target: SimEnemyV2 = enemies.get(int(shot.target)) as SimEnemyV2
		if not bool(shot.ground_target) and (target == null or not target.alive):
			projectiles.erase(int(shot.id))
			continue
		var destination: Vector3 = Vector3(shot.impact_point) if bool(shot.ground_target) else target.position
		var position: Vector3 = shot.position
		var travel: float = float(shot.speed) * STEP
		if distance_xz(position, destination) <= travel:
			_resolve_impact(shot, destination, target)
			events.append({"kind": "impact", "position": destination, "type": str(shot.damage_type), "family": str(shot.family), "splash": float(shot.splash), "target": int(shot.target), "ground_target": bool(shot.ground_target)})
			projectiles.erase(int(shot.id))
		else:
			var direction: Vector2 = Vector2(destination.x - position.x, destination.z - position.z).normalized()
			shot.position = position + Vector3(direction.x, 0, direction.y) * travel

func _layer_matches(shot: Dictionary, target: SimEnemyV2) -> bool:
	return target.alive and not target.underground() and (str(shot.layer) == "both" or str(shot.layer) == target.layer)

func _resolve_impact(shot: Dictionary, point: Vector3, primary: SimEnemyV2) -> void:
	if float(shot.splash) > 0.0:
		for target: SimEnemyV2 in enemies.values():
			if _layer_matches(shot, target) and distance_xz(target.position, point) <= float(shot.splash):
				_hit(shot, target)
	elif primary != null and primary.alive:
		_hit(shot, primary)
	if primary != null:
		if int(shot.chain_count) > 1: _resolve_chain(shot, primary, point)
		if int(shot.pierce_count) > 1: _resolve_pierce(shot, primary, point)
		if int(shot.spread_count) > 1: _resolve_spread(shot, primary, point)
	if not (shot.field as Dictionary).is_empty(): _create_field(shot, point)

func _resolve_chain(shot: Dictionary, primary: SimEnemyV2, point: Vector3) -> void:
	var visited: Dictionary = {primary.id: true}
	var previous: Vector3 = point
	var previous_id: int = primary.id
	var multiplier: float = 1.0
	for index in range(int(shot.chain_count) - 1):
		var best: SimEnemyV2 = null
		for candidate: SimEnemyV2 in enemies.values():
			if visited.has(candidate.id) or not _layer_matches(shot, candidate): continue
			var distance: float = distance_xz(previous, candidate.position)
			if distance > float(shot.chain_radius): continue
			if best == null or distance < distance_xz(previous, best.position) or (is_equal_approx(distance, distance_xz(previous, best.position)) and candidate.id < best.id): best = candidate
		if best == null: break
		visited[best.id] = true
		multiplier *= float(shot.chain_falloff)
		var bounce: Dictionary = shot.duplicate()
		bounce.damage = float(shot.damage) * multiplier
		_hit(bounce, best)
		events.append({"kind": "chain_link", "from": previous + Vector3(0, 1, 0), "to": best.position + Vector3(0, 1, 0), "family": str(shot.family), "duration": 0.14, "from_id": previous_id, "to_id": best.id})
		previous = best.position
		previous_id = best.id

func _resolve_pierce(shot: Dictionary, primary: SimEnemyV2, point: Vector3) -> void:
	var origin: Vector3 = shot.origin
	var direction: Vector2 = Vector2(point.x - origin.x, point.z - origin.z).normalized()
	if direction.length_squared() < 0.00001: return
	var line: Array[SimEnemyV2] = []
	for target: SimEnemyV2 in enemies.values():
		if target.id == primary.id or not _layer_matches(shot, target): continue
		var offset: Vector2 = Vector2(target.position.x - origin.x, target.position.z - origin.z)
		var along: float = offset.dot(direction)
		if along < 0 or along > float(shot.range): continue
		if absf(offset.cross(direction)) <= float(shot.pierce_width): line.append(target)
	line.sort_custom(func(a: SimEnemyV2, b: SimEnemyV2) -> bool: return distance_xz(point, a.position) < distance_xz(point, b.position) or (is_equal_approx(distance_xz(point, a.position), distance_xz(point, b.position)) and a.id < b.id))
	var multiplier: float = 1.0
	for index in range(mini(line.size(), int(shot.pierce_count) - 1)):
		multiplier *= float(shot.pierce_falloff)
		var through: Dictionary = shot.duplicate()
		through.damage = float(shot.damage) * multiplier
		_hit(through, line[index])

func _resolve_spread(shot: Dictionary, primary: SimEnemyV2, point: Vector3) -> void:
	var candidates: Array[SimEnemyV2] = []
	for target: SimEnemyV2 in enemies.values():
		if target.id != primary.id and _layer_matches(shot, target) and distance_xz(point, target.position) <= float(shot.spread_radius): candidates.append(target)
	candidates.sort_custom(func(a: SimEnemyV2, b: SimEnemyV2) -> bool: return a.id < b.id)
	for index in range(mini(candidates.size(), int(shot.spread_count) - 1)):
		for effect: Dictionary in shot.effects:
			apply_status(candidates[index].id, str(effect.kind), float(effect.power), float(effect.duration), int(shot.source))

func _create_field(shot: Dictionary, point: Vector3) -> void:
	var owned: Array[int] = []
	for id: int in fields:
		if int(fields[id].source) == int(shot.source): owned.append(id)
	if owned.size() >= 3: fields.erase(owned[0])
	var properties: Dictionary = shot.field
	var id: int = _sequence()
	fields[id] = {"id": id, "source": int(shot.source), "position": point, "radius": minf(2.5, float(properties.radius)), "until": ticks + int(round(float(properties.duration) * TICK_RATE)), "slow": float(properties.slow), "next_tick": ticks, "layer": str(shot.layer)}

func _update_fields() -> void:
	for field: Dictionary in fields.values():
		if ticks >= int(field.until):
			fields.erase(int(field.id))
			continue
		if ticks < int(field.next_tick): continue
		field.next_tick = ticks + TICK_RATE / 2
		for target: SimEnemyV2 in enemies.values():
			if (str(field.layer) == "both" or target.layer == str(field.layer)) and distance_xz(target.position, Vector3(field.position)) <= float(field.radius):
				apply_status(target.id, "slow", float(field.slow), 0.5, int(field.source))

func damage(target_id: int, amount: float, damage_type: String = "physical", source: int = -1, penetration: float = 0.0) -> float:
	var target: SimEnemyV2 = enemies.get(target_id) as SimEnemyV2
	if target == null or not target.alive or target.underground() or amount <= 0.0:
		return 0.0
	var effective_armor: float = remaining_armor(target)
	if damage_type == "magical": amount *= 1.0 - effective_magic_resistance(target)
	effective_armor *= 1.0 - clampf(penetration, 0.0, 0.75)
	if damage_type == "magical":
		effective_armor *= 0.5
	elif damage_type == "pure":
		effective_armor = 0.0
	var actual: float = maxf(1.0, amount - effective_armor)
	target.last_damage_tick = ticks
	var absorbed: float = minf(target.shield, actual)
	target.shield -= absorbed
	if absorbed > 0 and target.shield <= 0 and target.shield_until > ticks:
		target.shield_until = 0
		target.rally_until = 0
		events.append({"kind": "enemy_barrier_broken", "id": target.id})
	actual -= absorbed
	var useful: float = minf(target.health, actual) + absorbed
	target.health = maxf(0.0, target.health - actual)
	useful_damage += useful
	if towers.has(source):
		(towers[source] as SimTowerV2).damage_done += useful
	events.append({"kind": "damaged", "id": target.id, "health": target.health})
	if target.health <= 0.0:
		_resolve_enemy(target, true, source)
	return useful

func consume_events() -> Array[Dictionary]:
	var batch: Array[Dictionary] = events
	events = []
	return batch

func summary() -> Dictionary:
	return {"state": state, "ticks": ticks, "wave": wave_index, "lives": lives, "coins": coins, "kills": kills, "leaks": leaks, "spawned": spawned, "earned": earned, "spent": spent, "useful_damage": useful_damage, "control_delay": control_delay, "leaked_types": leaked_types.duplicate(), "leaked_layers": leaked_layers.duplicate()}

## P4 control effects use simulation ticks; presentation never changes their duration.
func apply_status(target_id: int, kind: String, power: float, duration: float, source: int) -> bool:
	var target: SimEnemyV2 = enemies.get(target_id) as SimEnemyV2
	if target == null or not target.alive or target.underground() or kind not in ["slow", "venom", "bleed", "corrosion"] or power <= 0.0 or duration <= 0.0:
		return false
	var lifetime: int = maxi(1, int(round(duration * TICK_RATE * (0.5 if target.boss and kind in ["venom", "bleed"] else 1.0))))
	var count: int = 0
	for effect: Dictionary in target.statuses:
		if str(effect.kind) != kind:
			continue
		count += 1
		if int(effect.source) == source:
			effect.power = power
			effect.until = ticks + lifetime
			return true
	if kind in ["venom", "bleed"] and count >= 3:
		return false
	target.statuses.append({"kind": kind, "power": power, "until": ticks + lifetime, "next_tick": ticks + TICK_RATE / 2, "source": source})
	return true

func movement_factor(target: SimEnemyV2) -> float:
	var slow: float = 0.0
	for effect: Dictionary in target.statuses:
		if str(effect.kind) == "slow" and int(effect.until) > ticks:
			slow = maxf(slow, float(effect.power))
	return 1.0 - minf(slow, 0.4 if target.boss else 0.65)

func _update_statuses() -> void:
	for target: SimEnemyV2 in enemies.values():
		for index in range(target.statuses.size() - 1, -1, -1):
			var effect: Dictionary = target.statuses[index]
			if str(effect.kind) in ["venom", "bleed"] and ticks >= int(effect.next_tick) and ticks <= int(effect.until):
				effect.next_tick = int(effect.next_tick) + TICK_RATE / 2
				damage(target.id, float(effect.power) * 0.5 * (1.25 if str(effect.kind) == "bleed" and target.speed > 0.0 else 1.0), "pure" if str(effect.kind) == "bleed" else "magical", int(effect.source))
			if ticks >= int(effect.until):
				target.statuses.remove_at(index)
			if not target.alive:
				break

func _hit(shot: Dictionary, target: SimEnemyV2) -> void:
	damage(target.id, float(shot.damage), str(shot.damage_type), int(shot.source), float(shot.get("penetration", 0.0)))
	for effect: Dictionary in shot.get("effects", []):
		apply_status(target.id, str(effect.kind), float(effect.power), float(effect.duration), int(shot.source))

func effective_magic_resistance(target: SimEnemyV2) -> float:
	if target.pending_ability == "posture_magic" and target.rally_until > ticks:
		return maxf(target.magic_resistance, float(target.ability.get("posture_resistance", 0)))
	return target.magic_resistance

func remaining_armor(target: SimEnemyV2) -> float:
	var armor: float = target.armor
	if target.pending_ability == "posture_physical" and target.rally_until > ticks: armor += float(target.ability.get("posture_armor", 0))
	var reduction: float = 0.0
	for effect: Dictionary in target.statuses:
		if str(effect.kind) == "corrosion" and int(effect.until) > ticks:
			reduction = maxf(reduction, float(effect.power))
	return maxf(0.0, armor - minf(reduction, armor * 0.5))

func buffs_for(tower: SimTowerV2) -> Dictionary:
	var haste: float = 0.0
	var reach: float = 0.0
	var haste_source: int = -1
	var reach_source: int = -1
	if tower.type_id == "banner": return {"haste": haste, "reach": reach, "haste_source": haste_source, "reach_source": reach_source}
	for support: SimTowerV2 in towers.values():
		if support.type_id != "banner" or support.state != SimTowerV2.State.READY: continue
		var values: Dictionary = stats(support)
		if distance_xz(support.position, tower.position) > float(values.range): continue
		var candidate_haste: float = float(values.get("haste", 0.0))
		var candidate_reach: float = float(values.get("reach_bonus", 0.0))
		if values.has("pulse_period"):
			var period: int = maxi(1, int(round(float(values.pulse_period) * TICK_RATE)))
			var duration: int = int(round(float(values.pulse_duration) * TICK_RATE))
			if (ticks - support.ready_tick) % period < duration: candidate_haste = maxf(candidate_haste, float(values.get("pulse_haste", 0.0)))
		if candidate_haste > haste or (candidate_haste > 0 and is_equal_approx(candidate_haste, haste) and support.id < haste_source):
			haste = candidate_haste
			haste_source = support.id
		if candidate_reach > reach or (candidate_reach > 0 and is_equal_approx(candidate_reach, reach) and support.id < reach_source):
			reach = candidate_reach
			reach_source = support.id
	return {"haste": minf(haste, 0.35), "reach": minf(reach, 0.2), "haste_source": haste_source, "reach_source": reach_source}

func effective_range(tower: SimTowerV2) -> float:
	return float(stats(tower).range) * (1.0 + float(buffs_for(tower).reach))

func attack_windup(tower: SimTowerV2) -> float:
	return float(stats(tower).get("windup", catalog.towers[tower.type_id].windup))

func _update_supports() -> void:
	for support: SimTowerV2 in towers.values():
		if support.type_id != "banner" or support.state != SimTowerV2.State.READY: continue
		var values: Dictionary = stats(support)
		if not values.has("pulse_period"): continue
		var period: int = maxi(1, int(round(float(values.pulse_period) * TICK_RATE)))
		var pulse: int = (ticks - support.ready_tick) / period
		if pulse != support.last_support_pulse:
			support.last_support_pulse = pulse
			events.append({"kind": "support_pulse", "id": support.id})

func _update_enemy_abilities() -> void:
	_active_speed_auras.clear()
	for enemy: SimEnemyV2 in enemies.values():
		if not enemy.support.is_empty() and str(enemy.support.kind) == "speed_aura": _active_speed_auras.append(enemy)
		if enemy.shield_until > 0 and ticks >= enemy.shield_until:
			enemy.shield = 0
			enemy.shield_until = 0
		if enemy.ability.is_empty(): continue
		var ability: Dictionary = enemy.ability
		if enemy.ability_until > 0:
			if ticks >= enemy.ability_until:
				enemy.ability_until = 0
				enemy.rally_until = ticks + int(round(float(ability.duration) * TICK_RATE))
				if str(ability.kind) in ["forge_cycle", "summon_limited"]:
					if enemy.pending_ability == "shield":
						enemy.shield = float(ability.shield_amount)
						enemy.maximum_shield = float(ability.shield_amount)
						enemy.shield_until = enemy.rally_until
						enemy.ability_shields_left -= 1
					else:
						_summon_forge_reinforcements(enemy)
					enemy.ability_cycle_index += 1
				if str(ability.kind) == "ruin_cycle":
					if enemy.pending_ability == "summon": _summon_forge_reinforcements(enemy)
					enemy.ability_cycle_index += 1
				enemy.next_ability_tick = ticks + maxi(1, int(round((float(ability.cooldown) - float(ability.windup)) * TICK_RATE)))
				events.append({"kind": "enemy_ability_active", "id": enemy.id, "ability": enemy.pending_ability, "until": enemy.rally_until})
		elif ticks >= enemy.next_ability_tick:
			enemy.pending_ability = "rally"
			if str(ability.kind) == "ruin_cycle":
				var ratio: float = enemy.health / enemy.maximum_health
				var can_summon: bool = enemy.summons_spawned < int(ability.summon_limit) and _active_reinforcements(enemy.id) < int(ability.active_cap)
				if ratio > 2.0 / 3: enemy.pending_ability = "posture_physical"
				elif enemy.ability_cycle_index % 2 == 1 and can_summon: enemy.pending_ability = "summon"
				else: enemy.pending_ability = "posture_magic" if ratio <= 1.0 / 3 else "aura"
			if str(ability.kind) in ["forge_cycle", "summon_limited"]:
				var can_summon: bool = enemy.summons_spawned < int(ability.summon_limit) and _active_reinforcements(enemy.id) < int(ability.active_cap)
				if enemy.ability_shields_left > 0 and (enemy.ability_cycle_index % 2 == 0 or not can_summon): enemy.pending_ability = "shield"
				elif can_summon: enemy.pending_ability = "summon"
				else:
					enemy.next_ability_tick = ticks + int(round(float(ability.cooldown) * TICK_RATE))
					continue
			enemy.ability_until = ticks + maxi(1, int(round(float(ability.windup) * TICK_RATE)))
			events.append({"kind": "enemy_telegraph", "id": enemy.id, "ability": enemy.pending_ability, "until": enemy.ability_until})
		if (str(ability.kind) == "rally" or enemy.pending_ability == "aura") and enemy.rally_until > ticks: _active_speed_auras.append(enemy)

func _active_reinforcements(source_id: int) -> int:
	var count: int = 0
	for child: SimEnemyV2 in enemies.values():
		if child.summoner_id == source_id: count += 1
	return count

func _summon_forge_reinforcements(source: SimEnemyV2) -> void:
	var ability: Dictionary = source.ability
	var amount: int = mini(int(ability.summon_count), mini(int(ability.summon_limit) - source.summons_spawned, int(ability.active_cap) - _active_reinforcements(source.id)))
	for index in range(maxi(0, amount)):
		var child: SimEnemyV2 = spawn_enemy(str(ability.summon_enemy), source.route_id, source.distance - 0.7 * (index + 1), source.id)
		if child == null: break
		source.summons_spawned += 1

func speed_aura_for(target: SimEnemyV2) -> float:
	if target.boss: return 0.0
	var bonus: float = 0.0
	for source: SimEnemyV2 in _active_speed_auras:
		if not source.alive or source.id == target.id: continue
		var radius: float = 0
		var power: float = 0
		if not source.support.is_empty() and str(source.support.kind) == "speed_aura":
			radius = float(source.support.radius)
			power = float(source.support.speed_bonus)
		elif not source.ability.is_empty() and (str(source.ability.kind) == "rally" or source.pending_ability == "aura") and source.rally_until > ticks:
			radius = float(source.ability.radius)
			power = float(source.ability.speed_bonus)
		if radius > 0 and distance_xz(source.position, target.position) <= radius: bonus = maxf(bonus, power)
	return minf(bonus, 0.5)

## Bounded healing: no self-heal, resurrection, excess healing or infinite casts.
func _update_enemy_support() -> void:
	for healer: SimEnemyV2 in enemies.values():
		if healer.maximum_shield > 0 and healer.shield <= 0 and healer.shield_recharges_left > 0 and healer.last_damage_tick >= 0 and ticks - healer.last_damage_tick >= healer.shield_recharge_ticks:
			healer.shield = healer.maximum_shield
			healer.shield_recharges_left -= 1
			events.append({"kind": "enemy_shield_recharged", "id": healer.id})
		if healer.support.is_empty() or str(healer.support.kind) != "heal": continue
		if healer.support_casts >= int(healer.support.casts) or ticks < healer.next_support_tick: continue
		var candidates: Array[SimEnemyV2] = []
		for target: SimEnemyV2 in enemies.values():
			if target.id != healer.id and target.alive and not target.underground() and target.health < target.maximum_health and distance_xz(target.position, healer.position) <= float(healer.support.radius): candidates.append(target)
		if candidates.is_empty(): continue
		candidates.sort_custom(func(a: SimEnemyV2, b: SimEnemyV2) -> bool:
			var ratio_a: float = a.health / a.maximum_health
			var ratio_b: float = b.health / b.maximum_health
			return a.id < b.id if is_equal_approx(ratio_a, ratio_b) else ratio_a < ratio_b)
		healer.support_casts += 1
		healer.next_support_tick = ticks + maxi(1, int(round(float(healer.support.period) * TICK_RATE)))
		for index in range(mini(candidates.size(), int(healer.support.targets))):
			var target: SimEnemyV2 = candidates[index]
			var restored: float = minf(float(healer.support.amount), target.maximum_health - target.health)
			target.health += restored
			events.append({"kind": "enemy_healed", "id": target.id, "source": healer.id, "amount": restored, "position": target.position})
