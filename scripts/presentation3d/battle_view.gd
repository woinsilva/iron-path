class_name BattleViewV2 extends Node3D
## Presentation/controller for BattleSimV2. Combat never reads rendered state.

signal exit_requested()
signal restart_requested()
signal tutorial_finished()
var tutorial_enabled: bool = true
var _help_layer: CanvasLayer
var _pause_before_help: bool = false
signal battle_completed(result: Dictionary)
@export var stage_path: String = "res://data/campaign/stage_01.json"
var stage: Dictionary
var difficulty: String = "normal"
var simulation: BattleSimV2
var diorama: Diorama3D
var enemy_views: Dictionary = {}
var tower_views: Dictionary = {}
var projectile_views: Dictionary = {}
var _projectile_pool: Dictionary = {}
var _impact_pool: Dictionary = {}
var _field_views: Dictionary = {}
var _impact_markers: Dictionary = {}
var _area_pool: Dictionary = {}
var _enemy_areas: Dictionary = {}
var _boss_panel: PanelContainer
var _boss_label: Label
var _boss_health: ProgressBar
var _enemy_pool: Dictionary = {}
var _warming_up: bool = false
var _last_back_frame: int = -1
var _corpses: Array[Dictionary] = []
var _effects: Array[Dictionary] = []
var _sites: Dictionary = {}
var _pads: Array[Node3D] = []
var _selected_pad: int = -1
var _range_radius: float = -1
var _range_ring: MeshInstance3D
var _canvas: CanvasLayer
var _top_stats: Label
var _wave_label: Button
var _hint: Label
var _context: Label
var _next_wave: Label
var _start: Button
var _speed: Button
var _pause: Button
var _branch_buttons: Dictionary = {}
var _priority: Button
var _upgrade: Button
var _sell: Button
var _cancel: Button
var _purchase_buttons: Dictionary = {}
var _result: PanelContainer
var _result_title: Label
var _result_body: Label
var _last_result: Dictionary = {}

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if stage.is_empty():
		stage = JSON.parse_string(FileAccess.get_file_as_string(stage_path).trim_prefix("\ufeff")) as Dictionary
	diorama = Diorama3D.new()
	diorama.route_points = stage.get("route_points", [])
	diorama.additional_route_points = stage.get("extra_route_points", [])
	diorama.biome = str(stage.get("biome", "vale"))
	diorama.stage_index = int(stage.index)
	if int(stage.index) in [6, 7]: diorama.river_x = -20.3
	if str(stage.id) == "arsenal_lab":
		diorama.river_x = 20.3
		diorama.river_width = 1.6
	for point: Array in stage.pads:
		diorama.reserved_positions.append(Vector3(float(point[0]), 0, float(point[2])))
	if int(stage.index) in [3, 5, 8]:
		diorama.river_x = 0
		diorama.river_width = 2.2
		diorama.bridges_enabled = true
	add_child(diorama)
	var landmarks: StageLandmarksV2 = StageLandmarksV2.new()
	landmarks.forge_enabled = int(stage.index) == 8
	landmarks.fortress_enabled = int(stage.index) == 7
	landmarks.quarry_enabled = int(stage.index) == 6
	landmarks.guard_gate_enabled = int(stage.index) == 4
	landmarks.orchard_enabled = int(stage.index) == 2
	landmarks.show_mill = int(stage.index) == 1
	landmarks.entrance = diorama.route.sample_baked(0)
	landmarks.endpoint = diorama.route.sample_baked(diorama.route.get_baked_length())
	add_child(landmarks)
	simulation = StageSessionV2.create(stage, difficulty)
	_build_pads()
	_build_air_route()
	if stage.has("route_labels"):
		for route_id in range(simulation.routes.size()):
			var road: Curve3D = simulation.routes[route_id]
			var point: Vector3 = road.sample_baked(1.5) + Vector3(0, 0.14, 0)
			var forward: Vector3 = (road.sample_baked(2) - road.sample_baked(1)).normalized()
			var side: Vector3 = Vector3(-forward.z, 0, forward.x)
			var ink: StandardMaterial3D = SceneCraft3D.material(Color("dce4dd") if route_id != 1 else Color("dfbe6c"))
			SceneCraft3D.beam(self, point - forward * 0.6, point + forward * 0.6, 0.07, ink)
			for sign: float in [-1, 1]: SceneCraft3D.beam(self, point + forward * 0.6, point + side * sign * 0.4, 0.07, ink)
	for route_id: int in stage.get("burrow_routes", []):
		var emergence: Vector3 = simulation.routes[route_id].sample_baked(float(simulation.catalog.enemies.burrower.burrow_distance)) + Vector3(0, 0.18, 0)
		var marker: Node3D = Node3D.new()
		marker.name = "EmergenceMarker%d" % route_id
		marker.position = emergence
		add_child(marker)
		var surface: StandardMaterial3D = SceneCraft3D.material(Color("e0ba78"))
		for sign: float in [-1, 1]:
			SceneCraft3D.beam(marker, Vector3(sign * 0.5, 0, -0.5), Vector3(-sign * 0.5, 0, 0.5), 0.12, surface)
		var label: Label3D = Label3D.new()
		label.text = "EMERGÊNCIA"
		label.font_size = 48
		label.pixel_size = 0.009
		label.position = Vector3(0, 0.8, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.add_child(label)
	_build_hud()
	if str(stage.id) == "arsenal_lab": _hint.text = "Recursos de ensaio: 18.000 moedas. Compare torres e ramos; o laboratório não altera estrelas da campanha."
	_update_hud()
	await _prepare_enemy_models()

func _build_pads() -> void:
	for index in range(simulation.pads.size()):
		var holder: Node3D = Node3D.new()
		holder.position = simulation.pads[index] + Vector3(0, 0.1, 0)
		add_child(holder)
		SceneCraft3D.cylinder(holder, 1.0, 0.16, Vector3(0, 0.08, 0), SceneCraft3D.material(Color("aca58a")), 20)
		SceneCraft3D.cylinder(holder, 0.84, 0.05, Vector3(0, 0.18, 0), SceneCraft3D.material(Color("757f68")), 20)
		var sign: Label3D = Label3D.new()
		sign.text = "+"
		sign.font_size = 100
		sign.pixel_size = 0.008
		sign.modulate = Color("f2d78b")
		sign.position.y = 0.55
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sign.outline_size = 10
		holder.add_child(sign)
		_pads.append(holder)

func _physics_process(delta: float) -> void:
	if _warming_up: return
	simulation.advance(delta)
	_handle_events(simulation.consume_events())
	_sync_enemies(delta)
	_sync_towers(delta)
	_sync_projectiles()
	_sync_fields()
	_sync_enemy_areas()
	for index in range(_corpses.size() - 1, -1, -1):
		var entry: Dictionary = _corpses[index]
		entry.remaining = float(entry.remaining) - delta
		if float(entry.remaining) <= 0.0:
			var actor: RiggedActor3D = entry.actor
			actor.visible = false
			actor.process_mode = Node.PROCESS_MODE_DISABLED
			_recycle_actor(actor)
			_corpses.remove_at(index)
	for index in range(_effects.size() - 1, -1, -1):
		var effect: Dictionary = _effects[index]
		effect.remaining = float(effect.remaining) - delta
		var node: Node3D = effect.node
		if bool(effect.get("expand", true)): node.scale += Vector3.ONE * delta * 4.0
		if float(effect.remaining) <= 0.0:
			_retire_effect(node as MeshInstance3D)
			_effects.remove_at(index)
	var selected: SimTowerV2 = simulation.tower_on_pad(_selected_pad)
	if selected != null and not is_equal_approx(_range_radius, simulation.effective_range(selected)): _update_ring()
	_update_hud()

func _handle_events(batch: Array[Dictionary]) -> void:
	var hit_points: Dictionary = {}
	for event: Dictionary in batch:
		match str(event.kind):
			"spawned":
				var actor: RiggedActor3D
				var pool: Array = _enemy_pool.get(str(event.type), [])
				if pool.is_empty():
					actor = _create_enemy_actor(str(event.type), int(event.id) * 0.17)
				else:
					actor = pool.pop_back() as RiggedActor3D
					actor.process_mode = Node.PROCESS_MODE_INHERIT
					actor.revive()
				actor.set_meta("interpolation_spawn",true)
				actor.initial_phase = int(event.id) * 0.17
				actor.scale = Vector3.ONE * float(simulation.catalog.enemies[str(event.type)].scale)
				actor.position = Vector3(event.position) + Vector3(0, 0.1, 0)
				actor.visible = true
				var state: SimEnemyV2 = simulation.enemies.get(int(event.id)) as SimEnemyV2
				if state != null:
					var road: Curve3D = simulation.routes[state.route_id]
					actor.set_heading(road.sample_baked(minf(state.distance + 0.2, road.get_baked_length())) - road.sample_baked(state.distance))
				enemy_views[int(event.id)] = actor
			"killed", "leaked":
				if enemy_views.has(int(event.id)):
					var actor: RiggedActor3D = enemy_views[int(event.id)]
					if str(event.kind) == "killed":
						actor.die()
						_corpses.append({"actor": actor, "remaining": 1.0})
					else:
						actor.visible = false
						actor.process_mode = Node.PROCESS_MODE_DISABLED
						_recycle_actor(actor)
					enemy_views.erase(int(event.id))
			"enemy_barrier_broken":
				_sound("shield_break")
				_hint.text = "Barreira rompida! O dano volta a atingir a vida do chefe."
			"enemy_healed":
				_sound("heal")
				_make_impact({"position": event.position, "family": "heal", "splash": 0.0})
			"emerged":
				_sound("impact")
			"damaged":
				if enemy_views.has(int(event.id)):
					hit_points[int(event.id)] = (enemy_views[int(event.id)] as RiggedActor3D).impact_position()
					(enemy_views[int(event.id)] as RiggedActor3D).react_to_hit()
			"build_started":
				_create_tower(int(event.id))
			"tower_removed":
				_remove_tower(int(event.id))
			"work_completed":
				if tower_views.has(int(event.id)):
					(tower_views[int(event.id)] as Node3D).visible = true
					var upgraded: SimTowerV2 = simulation.towers[int(event.id)]
					TowerUpgradeDecorV2.apply(tower_views[int(event.id)], upgraded.level, upgraded.type_id, upgraded.branch)
				if _sites.has(int(event.id)):
					(_sites[int(event.id)] as Node3D).visible = false
			"upgrade_started":
				(tower_views[int(event.id)] as Node3D).call("cancel_attack")
				(_sites[int(event.id)] as Node3D).visible = true
			"windup":
				if tower_views.has(int(event.id)):
					var tower: SimTowerV2 = simulation.towers[int(event.id)]
					(tower_views[int(event.id)] as Node3D).call("prepare_attack", simulation.attack_windup(tower))
			"released":
				if tower_views.has(int(event.id)):
					(tower_views[int(event.id)] as Node3D).call("release_attack")
					_sound((simulation.towers[int(event.id)] as SimTowerV2).type_id)
			"enemy_telegraph":
				_sound("rally" if str(event.ability) == "rally" else "summon")
				if enemy_views.has(int(event.id)) and str(event.ability) == "rally": (enemy_views[int(event.id)] as RiggedActor3D).perform_rally(float(int(event.until) - simulation.ticks) / 60.0)
			"attack_cancelled":
				if tower_views.has(int(event.id)): (tower_views[int(event.id)] as Node3D).call("cancel_attack")
			"support_pulse":
				_sound("banner")
				if tower_views.has(int(event.id)): (tower_views[int(event.id)] as Node3D).call("prepare_attack", 1.0)
			"chain_link":
				var link: Dictionary = event.duplicate()
				for pair: Array in [["from_id","from"],["to_id","to"]]:
					var target_id: int = int(event.get(str(pair[0]),-1))
					if hit_points.has(target_id): link[str(pair[1])] = hit_points[target_id]
					elif enemy_views.has(target_id): link[str(pair[1])] = (enemy_views[target_id] as RiggedActor3D).impact_position()
				_make_chain_link(link)
			"impact":
				_sound("impact")
				var impact: Dictionary = event.duplicate()
				if not bool(event.get("ground_target",false)):
					var target_id: int = int(event.get("target",-1))
					if hit_points.has(target_id): impact.visual_position = hit_points[target_id]
					elif enemy_views.has(target_id): impact.visual_position = (enemy_views[target_id] as RiggedActor3D).impact_position()
				_make_impact(impact)
			"finished":
				_show_result(bool(event.victory))

func _create_tower(id: int) -> void:
	var tower: SimTowerV2 = simulation.towers[id]
	var display: Node3D
	if tower.type_id == "archer":
		var archer: ArcherDisplay3D = ArcherDisplay3D.new()
		archer.simulation_controlled = true
		display = archer
	elif tower.type_id == "cannon":
		display = CannonDisplay3D.new()
	elif tower.type_id == "bleed":
		display = BallistaDisplayV2.new()
	elif tower.type_id == "banner":
		display = BannerDisplayV2.new()
	else:
		var magic: MagicDisplayV2 = MagicDisplayV2.new()
		magic.family = tower.type_id
		display = magic
	display.position = tower.position + Vector3(0, 0.1, 0)
	add_child(display)
	display.visible = false
	tower_views[id] = display
	(_pads[tower.pad].get_child(2) as Label3D).visible = false
	var site: Node3D = Node3D.new()
	site.position = tower.position + Vector3(0, 0.1, 0)
	add_child(site)
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("bb8c53"))
	for x: float in [-0.9, 0.9]:
		for z: float in [-0.9, 0.9]:
			SceneCraft3D.box(site, Vector3(0.1, 1.5, 0.1), Vector3(x, 0.75, z), wood)
		SceneCraft3D.box(site, Vector3(0.1, 0.12, 1.9), Vector3(x, 1.5, 0), wood)
	SceneCraft3D.beam(site, Vector3(-0.9, 0.2, 0.9), Vector3(0.9, 1.5, 0.9), 0.08, wood)
	_sites[id] = site

func _remove_tower(id: int) -> void:
	if tower_views.has(id):
		var display: Node3D = tower_views[id]
		for index in range(_pads.size()):
			if BattleSimV2.distance_xz(_pads[index].position, display.position) < 0.2:
				(_pads[index].get_child(2) as Label3D).visible = true
		display.queue_free()
		tower_views.erase(id)
	if _sites.has(id):
		(_sites[id] as Node3D).queue_free()
		_sites.erase(id)

func _sync_enemies(delta: float) -> void:
	for id: int in enemy_views:
		var actor: RiggedActor3D = enemy_views[id]
		var state: SimEnemyV2 = simulation.enemies.get(id) as SimEnemyV2
		if state == null:
			continue
		var old: Vector3 = actor.position
		actor.position = state.position + Vector3(0, diorama.walk_surface_height(state.position), 0)
		if state.layer == "air": actor.position.y = maxf(state.position.y, float(simulation.catalog.enemies[state.type_id].flight_height)) + 0.1
		actor.health_ratio = state.health / state.maximum_health
		if actor is CrawlerActorV2:
			(actor as CrawlerActorV2).set_summoned(state.summoner_id >= 0)
			(actor as CrawlerActorV2).set_underground(state.underground())
		if actor is RuinGuardianActorV2: (actor as RuinGuardianActorV2).set_posture(state.pending_ability, state.ability_until > simulation.ticks or state.rally_until > simulation.ticks)
		if actor is ColossusActorV2: (actor as ColossusActorV2).set_ability_state(state.ability_until > simulation.ticks)
		actor.animate_motion((actor.position - old) / maxf(delta, 0.001), delta)
		if actor.has_meta("interpolation_spawn"):
			actor.reset_physics_interpolation()
			actor.remove_meta("interpolation_spawn")

func _sync_towers(delta: float) -> void:
	for id: int in tower_views:
		var tower: SimTowerV2 = simulation.towers.get(id) as SimTowerV2
		if tower == null:
			continue
		var display: Node3D = tower_views[id]
		var module: Node3D = display.get_node_or_null("LevelDecor/BranchModule") as Node3D
		if module != null and (display is CannonDisplay3D or display is ArcherDisplay3D or display is BallistaDisplayV2):
			module.rotation.y = (display.get("turret") as Node3D).rotation.y
		var target: SimEnemyV2 = simulation.enemies.get(tower.pending_target) as SimEnemyV2
		if target == null:
			target = simulation.choose_target(tower)
		if target:
			var aim: Vector3 = (enemy_views[target.id] as RiggedActor3D).impact_position() if enemy_views.has(target.id) else target.position
			(tower_views[id] as Node3D).call("aim_at", aim, delta)

func _sync_projectiles() -> void:
	for id: int in simulation.projectiles:
		var shot: Dictionary = simulation.projectiles[id]
		if not projectile_views.has(id):
			var view: Node3D = _acquire_projectile(str(shot.get("family", "archer")))
			var source: Node3D = tower_views.get(int(shot.source)) as Node3D
			view.set_meta("emitter", source.call("muzzle_position") if source != null and source.has_method("muzzle_position") else Vector3(shot.origin) + Vector3(0, 1.5, 0))
			projectile_views[id] = view
			if bool(shot.ground_target):
				var marker: Node3D = _acquire_area("mortar", float(shot.splash))
				marker.position = Vector3(shot.impact_point) + Vector3(0, 0.16, 0)
				_impact_markers[id] = marker
		var display: Node3D = projectile_views[id]
		var target: SimEnemyV2 = simulation.enemies.get(int(shot.target)) as SimEnemyV2
		if target == null and not bool(shot.ground_target): continue
		var destination: Vector3 = Vector3(shot.impact_point) if bool(shot.ground_target) else target.position
		var initial_distance: float = maxf(0.1, BattleSimV2.distance_xz(Vector3(shot.origin), destination))
		var progress: float = clampf(1.0 - BattleSimV2.distance_xz(Vector3(shot.position), destination) / initial_distance, 0.0, 1.0)
		var emitter: Vector3 = display.get_meta("emitter")
		var offset: Vector3 = emitter - Vector3(shot.origin)
		var aim: Vector3 = destination + Vector3(0,0.2 if bool(shot.ground_target) else 1,0)
		if not bool(shot.ground_target) and enemy_views.has(int(shot.target)):
			aim = (enemy_views[int(shot.target)] as RiggedActor3D).impact_position()
		var end_height: float = aim.y
		var arc: float = 3.2 if bool(shot.ground_target) else (0.55 if str(shot.family) in ["archer", "cannon", "bleed"] else 0.0)
		display.position = Vector3(shot.position) + Vector3(offset.x * (1.0 - progress), 0, offset.z * (1.0 - progress))
		display.position.y = lerpf(emitter.y,end_height,progress) + sin(progress * PI) * arc
		if display.position.distance_to(aim) > 0.001: display.look_at(aim, Vector3.UP, true)
		if display.has_meta("interpolation_spawn"):
			display.reset_physics_interpolation()
			display.remove_meta("interpolation_spawn")
	for id: int in projectile_views.keys():
		if not simulation.projectiles.has(id):
			_retire_projectile(projectile_views[id] as Node3D)
			projectile_views.erase(id)
			if _impact_markers.has(id):
				_retire_area(_impact_markers[id] as Node3D)
				_impact_markers.erase(id)

func _sync_fields() -> void:
	for id: int in simulation.fields:
		var field: Dictionary = simulation.fields[id]
		if not _field_views.has(id): _field_views[id] = _acquire_area("frost", float(field.radius))
		(_field_views[id] as Node3D).position = Vector3(field.position) + Vector3(0, 0.15, 0)
	for id: int in _field_views.keys():
		if not simulation.fields.has(id):
			_retire_area(_field_views[id] as Node3D)
			_field_views.erase(id)

func _acquire_area(kind: String, radius: float) -> Node3D:
	var pool: Array = _area_pool.get(kind, [])
	var area: Node3D
	if pool.is_empty():
		area = Node3D.new()
		area.set_meta("pool_key", kind)
		add_child(area)
		var color: Color = Color(str({"frost":"76cfed", "shield":"76cfed", "rally":"cf7658", "summon":"b69bdc", "posture_magic":"bc94e1", "posture_physical":"dcc07b", "aura":"77c8c1"}.get(kind, "d0aa65")))
		var ring: TorusMesh = TorusMesh.new()
		ring.inner_radius = 0.96
		ring.outer_radius = 1.0
		ring.rings = 32
		ring.ring_segments = 4
		SceneCraft3D.mesh(area, ring, Vector3.ZERO, SceneCraft3D.material(color))
	else: area = pool.pop_back() as Node3D
	area.scale = Vector3(radius, 1, radius)
	area.visible = true
	return area
func _retire_area(area: Node3D) -> void:
	var kind: String = str(area.get_meta("pool_key"))
	area.visible = false
	if not _area_pool.has(kind): _area_pool[kind] = []
	(_area_pool[kind] as Array).append(area)
func _make_chain_link(event: Dictionary) -> void:
	var key: String = "beam_" + str(event.family)
	var pool: Array = _impact_pool.get(key, [])
	var from: Vector3 = event.from
	var to: Vector3 = event.to
	if from.distance_to(to) < 0.01: return
	var beam: MeshInstance3D
	if pool.is_empty():
		beam = SceneCraft3D.beam(self, from, to, 0.055, SceneCraft3D.material(Color("b69be0") if str(event.family) == "arcane" else Color("e7d58e")))
		beam.set_meta("pool_key", key)
	else:
		beam = pool.pop_back() as MeshInstance3D
		(beam.mesh as BoxMesh).size = Vector3(0.055, from.distance_to(to), 0.055)
		beam.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
		beam.position = (from + to) * 0.5
	beam.scale = Vector3.ONE
	beam.visible = true
	_effects.append({"node": beam, "remaining": float(event.duration), "expand": false})

func _make_impact(event: Dictionary) -> void:
	var key: String = str(event.get("family", "archer")) + ("_area" if float(event.splash) > 0 else "")
	var pool: Array = _impact_pool.get(key, [])
	var sphere: MeshInstance3D
	if pool.is_empty():
		var color: Color = SceneCraft3D.family_color(str(event.get("family", "archer")))
		sphere = SceneCraft3D.sphere(self, 0.13 if float(event.splash) == 0.0 else 0.35, Vector3.ZERO, SceneCraft3D.material(color))
		if str(event.get("family", "")) == "heal":
			var cross: ArrayMesh = ArrayMesh.new()
			for size: Vector3 in [Vector3(0.12, 0.65, 0.12), Vector3(0.65, 0.12, 0.12)]:
				var part: BoxMesh = BoxMesh.new()
				part.size = size
				cross.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, part.surface_get_arrays(0))
			sphere.mesh = cross
			sphere.material_override = SceneCraft3D.material(Color("a9efcc"))
		sphere.set_meta("pool_key", key)
	else:
		sphere = pool.pop_back() as MeshInstance3D
	sphere.visible = true
	sphere.scale = Vector3.ONE
	sphere.position = Vector3(event.get("visual_position", Vector3(event.position) + Vector3(0, 2.8 if str(event.get("family", "")) == "heal" else 0.35, 0)))
	_effects.append({"node": sphere, "remaining": 0.45 if str(event.get("family", "")) == "heal" else 0.16, "expand": str(event.get("family", "")) != "heal"})

func _retire_effect(sphere: MeshInstance3D) -> void:
	var key: String = str(sphere.get_meta("pool_key"))
	sphere.visible = false
	if not _impact_pool.has(key): _impact_pool[key] = []
	(_impact_pool[key] as Array).append(sphere)

func _acquire_projectile(family: String) -> Node3D:
	var pool: Array = _projectile_pool.get(family, [])
	var display: Node3D
	if not pool.is_empty():
		display = pool.pop_back() as Node3D
	else:
		if family in ["archer", "bleed"]:
			display = load("res://art/models/arrow_bow.glb").instantiate() as Node3D
			if family == "bleed": display.scale = Vector3.ONE * 1.5
		else:
			display = Node3D.new()
			var color: Color = Color("35424b") if family == "cannon" else SceneCraft3D.family_color(family)
			SceneCraft3D.sphere(display, 0.18, Vector3.ZERO, SceneCraft3D.material(color))
		add_child(display)
		display.set_meta("pool_key", family)
	display.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	display.set_meta("interpolation_spawn",true)
	display.visible = true
	display.process_mode = Node.PROCESS_MODE_INHERIT
	return display

func _retire_projectile(display: Node3D) -> void:
	var key: String = str(display.get_meta("pool_key"))
	display.visible = false
	display.process_mode = Node.PROCESS_MODE_DISABLED
	if not _projectile_pool.has(key): _projectile_pool[key] = []
	(_projectile_pool[key] as Array).append(display)

func _unhandled_input(event: InputEvent) -> void:
	if _warming_up: return
	if is_instance_valid(_help_layer):
		if event.is_action_pressed("ui_cancel"): _dismiss_help()
		return
	var point: Vector2
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		point = event.position
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
	elif event.is_action_pressed("ui_cancel"):
		if _selected_pad >= 0:
			_select_pad(-1)
		else:
			_toggle_pause()
		return
	else:
		return
	var camera: Camera3D = diorama.camera
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(point), camera.project_ray_normal(point))
	if hit == null:
		return
	var selected: int = -1
	var closest: float = 1.25
	for index in range(simulation.pads.size()):
		var distance: float = BattleSimV2.distance_xz(simulation.pads[index], hit as Vector3)
		if distance < closest:
			closest = distance
			selected = index
	_select_pad(selected)

func _select_pad(index: int) -> void:
	_selected_pad = index
	_update_ring()
	_update_hud()

func _update_ring() -> void:
	if is_instance_valid(_range_ring):
		_range_ring.queue_free()
	if _selected_pad < 0:
		return
	var tower: SimTowerV2 = simulation.tower_on_pad(_selected_pad)
	var radius: float = simulation.effective_range(tower) if tower != null else 4.2
	_range_radius = radius
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(96):
		var a: float = TAU * index / 96.0
		var b: float = TAU * (index + 1) / 96.0
		var inner_a: Vector3 = Vector3(cos(a), 0, sin(a)) * (radius - 0.055)
		var inner_b: Vector3 = Vector3(cos(b), 0, sin(b)) * (radius - 0.055)
		var outer_a: Vector3 = Vector3(cos(a), 0, sin(a)) * (radius + 0.055)
		var outer_b: Vector3 = Vector3(cos(b), 0, sin(b)) * (radius + 0.055)
		for vertex: Vector3 in [inner_a, inner_b, outer_a, outer_a, inner_b, outer_b]:
			surface.add_vertex(vertex)
	var material: StandardMaterial3D = SceneCraft3D.material(Color("8bd0c4"))
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_range_ring = SceneCraft3D.mesh(self, surface.commit(), simulation.pads[_selected_pad] + Vector3(0, 0.15, 0), material)
	_range_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _toggle_pause() -> void:
	if simulation._terminal():
		return
	simulation.paused = not simulation.paused
	get_tree().paused = simulation.paused
	_update_hud()

func _toggle_speed() -> void:
	Engine.time_scale = 2.0 if Engine.time_scale == 1.0 else 1.0
	_update_hud()

func _purchase(type_id: String) -> void:
	if _selected_pad >= 0 and simulation.build(_selected_pad, type_id):
		_hint.text = "Construção iniciada. A torre atacará ao terminar a obra."
	else:
		_hint.text = "Selecione uma base vazia e confira as moedas disponíveis."
	_update_hud()

func _request_upgrade() -> void:
	if not simulation.upgrade(_selected_pad):
		_hint.text = "Upgrade indisponível: confira moedas, limite da fase e obra atual."
	_update_hud()

func _restart() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		restart_requested.emit()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED] and simulation != null and not simulation._terminal():
		simulation.paused = true
		get_tree().paused = true
		_update_hud()

func _exit_tree() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0

func _panel(parent: Node, top: float, bottom: float, preset: int) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(preset)
	panel.offset_top = top
	panel.offset_bottom = bottom
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.075, 0.09, 0.97)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	return column

func _label(parent: Node, text: String, size: int = 28, color: Color = Color.WHITE) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.modulate = color
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable, width: float = 150.0) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 96)
	button.add_theme_font_size_override("font_size", 26)
	button.pressed.connect(func() -> void: _sound("ui", AudioServiceNode.BUS_UI); callback.call())
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("294a4c")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	button.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("426a63")
	button.add_theme_stylebox_override("hover", hover)
	parent.add_child(button)
	return button

func _build_hud() -> void:
	_canvas = CanvasLayer.new()
	_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_canvas)
	var overlay: BattleOverlayV2 = BattleOverlayV2.new()
	overlay.battle = self
	_canvas.add_child(overlay)
	var top: VBoxContainer = _panel(_canvas, 0, 160, Control.PRESET_TOP_WIDE)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 30)
	top.add_child(header)
	_top_stats = _label(header, "", 30, Color("ecd49a"))
	_top_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_wave_label = _button(header, "Onda", _show_forecast, 200)
	_wave_label.tooltip_text = "Inspecionar as duas próximas ondas"
	_pause = _button(header, "Pausar", _toggle_pause)
	_speed = _button(header, "Velocidade: 1×", _toggle_speed, 220)
	_button(header, "Reiniciar", _restart)
	_button(header, "?", _show_help, 72)
	_button(header, "Menu", func() -> void: get_tree().paused = false; exit_requested.emit())
	_next_wave = _label(top, "", 23, Color("b0c6c5"))
	_next_wave.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next_wave.max_lines_visible = 2
	_boss_panel = PanelContainer.new()
	_boss_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_boss_panel.offset_left = 28
	_boss_panel.offset_right = 588
	_boss_panel.offset_top = 170
	_boss_panel.offset_bottom = 254
	var boss_style: StyleBoxFlat = StyleBoxFlat.new()
	boss_style.bg_color = Color("172b31")
	boss_style.border_color = Color("bfa66b")
	boss_style.set_border_width_all(2)
	boss_style.set_corner_radius_all(7)
	boss_style.set_content_margin_all(8)
	_boss_panel.add_theme_stylebox_override("panel", boss_style)
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_boss_panel)
	var boss_column: VBoxContainer = VBoxContainer.new()
	_boss_panel.add_child(boss_column)
	_boss_label = _label(boss_column, "", 22, Color("ecd49a"))
	_boss_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boss_label.max_lines_visible = 2
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_health = ProgressBar.new()
	_boss_health.custom_minimum_size.y = 18
	_boss_health.show_percentage = false
	var health_fill: StyleBoxFlat = StyleBoxFlat.new()
	health_fill.bg_color = Color("ce8c66")
	health_fill.set_corner_radius_all(4)
	_boss_health.add_theme_stylebox_override("fill", health_fill)
	boss_column.add_child(_boss_health)
	_boss_panel.visible = false
	var bottom: VBoxContainer = _panel(_canvas, -260, 0, Control.PRESET_BOTTOM_WIDE)
	_context = _label(bottom, "Selecione uma base de pedra para construir.", 28, Color("ecd49a"))
	_context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_context.max_lines_visible = 2
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	bottom.add_child(actions)
	for type_id: String in stage.allowed_towers:
		var key: String = type_id
		var definition: Dictionary = simulation.catalog.towers[key]
		_purchase_buttons[key] = _button(actions, "%s · %d\n%.1f m · %s" % [str(definition.name), int(definition.levels[0].cost), float(definition.levels[0].range), "Terra/ar" if str(definition.layer) == "both" else ("Ar" if str(definition.layer) == "air" else ("Suporte" if str(definition.layer) == "ally" else "Terra"))], func() -> void: _purchase(key), 210)
	_upgrade = _button(actions, "Melhorar", _request_upgrade, 210)
	for branch: String in ["A", "B"]:
		var key: String = branch
		_branch_buttons[key] = _button(actions, "Ramo " + key, func() -> void: _request_branch(key), 240)
	_priority = _button(actions, "Alvo: Primeiro", _cycle_priority, 230)
	_cancel = _button(actions, "Cancelar obra", func() -> void: simulation.cancel_work(_selected_pad), 210)
	_sell = _button(actions, "Vender", func() -> void: simulation.sell(_selected_pad), 180)
	var gap: Control = Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(gap)
	_start = _button(actions, "Iniciar defesa", _start_or_early, 270)
	_hint = _label(bottom, "Construa sua defesa e inicie a primeira onda. As próximas chegam automaticamente.", 23, Color("b0c6c5"))
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.max_lines_visible = 2
	_result = PanelContainer.new()
	_result.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_result.offset_left = -510
	_result.offset_right = 510
	_result.offset_top = -330
	_result.offset_bottom = 330
	var result_style: StyleBoxFlat = StyleBoxFlat.new()
	result_style.bg_color = Color("132b31")
	result_style.border_color = Color("bfa66b")
	result_style.set_border_width_all(3)
	result_style.content_margin_left = 44
	result_style.content_margin_top = 32
	result_style.content_margin_right = 44
	result_style.content_margin_bottom = 32
	_result.add_theme_stylebox_override("panel", result_style)
	_canvas.add_child(_result)
	var result_column: VBoxContainer = VBoxContainer.new()
	result_column.add_theme_constant_override("separation", 20)
	_result.add_child(result_column)
	_result_title = _label(result_column, "", 54, Color("ecd49a"))
	_result_body = _label(result_column, "", 25)
	_result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var buttons: HBoxContainer = HBoxContainer.new()
	result_column.add_child(buttons)
	_button(buttons, "Tentar novamente", _restart, 270)
	_button(buttons, "Voltar ao mapa", func() -> void: exit_requested.emit(), 270)
	_result.visible = false

func _start_or_early() -> void:
	if _warming_up: return
	if simulation.state == BattleSimV2.State.PREPARATION:
		if simulation.start_first_wave() and tutorial_enabled and int(stage.index) == 1:
			tutorial_enabled = false
			_hint.text = "Defesa iniciada. As próximas ondas chegam automaticamente; toque em Onda para consultar a previsão."
			tutorial_finished.emit()
	else:
		simulation.call_wave_early()
	_update_hud()

func _update_hud() -> void:
	_speed.text = "Velocidade: %d×" % int(Engine.time_scale)
	if _top_stats == null:
		return
	_top_stats.text = "%s   |   Vidas %d   |   Moedas %d" % [str(stage.name), simulation.lives, simulation.coins]
	_wave_label.text = "Onda %d / %d" % [simulation.wave_index, simulation.waves.size()]
	_pause.text = "Continuar" if simulation.paused else "Pausar"
	var boss: SimEnemyV2 = null
	for enemy: SimEnemyV2 in simulation.enemies.values():
		if enemy.boss: boss = enemy; break
	_boss_panel.visible = boss != null and not simulation._terminal()
	if boss != null:
		var ability: String = ""
		var title: String = str({"rally": "Brado", "shield": "Barreira", "summon": "Reforços", "aura": "Aura", "posture_physical": "Postura física", "posture_magic": "Postura mágica"}.get(boss.pending_ability, "Habilidade"))
		if boss.ability_until > simulation.ticks: ability = " · Preparando %s %.1fs" % [title, float(boss.ability_until - simulation.ticks) / 60]
		elif boss.rally_until > simulation.ticks: ability = " · Brado ativo %.1fs" % (float(boss.rally_until - simulation.ticks) / 60) if boss.pending_ability == "rally" else " · %s %.1fs" % [title, float(boss.rally_until - simulation.ticks) / 60]
		_boss_label.text = "%s · %d/%d%s" % [simulation.catalog.enemies[boss.type_id].name, ceili(boss.health), int(boss.maximum_health), ability]
		_boss_health.max_value = boss.maximum_health
		_boss_health.value = boss.health
	var preview: String = _describe_wave(simulation.wave_index)
	_next_wave.text = "Próxima: " + preview if not preview.is_empty() else "Última onda: defenda o núcleo."
	_start.disabled = simulation.paused or simulation.state not in [BattleSimV2.State.PREPARATION, BattleSimV2.State.INTERMISSION]
	if simulation.state == BattleSimV2.State.INTERMISSION:
		_start.text = "Chamar agora · %ds" % int(ceil(float(simulation.interval_until - simulation.ticks) / BattleSimV2.TICK_RATE))
	elif simulation.state == BattleSimV2.State.PREPARATION:
		_start.text = "Iniciar ensaio" if str(stage.id) == "arsenal_lab" else "Iniciar defesa"
	else:
		_start.text = "Ondas automáticas"
	var tower: SimTowerV2 = simulation.tower_on_pad(_selected_pad)
	var allowed: bool = _selected_pad >= 0 and not simulation.paused and not simulation._terminal()
	for key: String in _purchase_buttons:
		var button: Button = _purchase_buttons[key]
		button.visible = tower == null
		button.disabled = not allowed or simulation.coins < int(simulation.catalog.towers[key].levels[0].cost)
	var ready: bool = tower != null and tower.state == SimTowerV2.State.READY
	var choosing_branch: bool = ready and tower.level == 3 and simulation.catalog.towers[tower.type_id].has("branches")
	_upgrade.visible = ready and not choosing_branch
	_sell.visible = ready
	_priority.visible = ready and tower.type_id != "banner"
	_priority.disabled = not allowed
	for key: String in _branch_buttons:
		var button: Button = _branch_buttons[key]
		button.visible = choosing_branch
		button.disabled = not allowed
		if choosing_branch:
			var next: Dictionary = simulation.next_upgrade(tower, key)
			var branch: Dictionary = simulation.catalog.towers[tower.type_id].branches[key]
			button.text = "%s · %d" % [str(branch.name), int(next.cost)]
			button.tooltip_text = str(branch.description)
			button.disabled = not allowed or simulation.coins < int(next.cost)
	if choosing_branch:
		var branches: Dictionary = simulation.catalog.towers[tower.type_id].branches
		_hint.text = "A · %s: %s  |  B · %s: %s" % [branches.A.name, branches.A.description, branches.B.name, branches.B.description]
	_cancel.visible = tower != null and tower.state != SimTowerV2.State.READY
	_upgrade.disabled = not allowed
	_sell.disabled = not allowed
	_cancel.disabled = not allowed
	if tower:
		var definition: Dictionary = simulation.catalog.towers[tower.type_id]
		_context.text = "%s · Nível %d · Dano útil %d · Eliminações %d" % [str(definition.name), tower.level, int(tower.damage_done), tower.kills]
		if tower.type_id == "banner":
			var values: Dictionary = simulation.stats(tower)
			_context.text = "%s · Nível %d · Cadência +%d%% · Alcance aliado +%d%%" % [str(definition.name), tower.level, int(round(float(values.get("haste", values.get("pulse_haste", 0))) * 100)), int(round(float(values.get("reach_bonus", 0)) * 100))]
		_sell.text = "Vender · %d" % int(floor(tower.investment * 0.6))
		if tower.control_delay > 0.0: _context.text += " · Atraso causado %.1fs" % tower.control_delay
		if tower.supported_attacks > 0: _context.text += " · %d ataques sob aura" % tower.supported_attacks
		if not tower.branch.is_empty(): _context.text += " · " + str(definition.branches[tower.branch].name)
		var priorities: Dictionary = {"first": "Primeiro", "last": "Último", "strongest": "Mais forte", "weakest": "Mais fraco"}
		_priority.text = "Alvo: " + str(priorities[tower.priority])
		var next: Dictionary = simulation.next_upgrade(tower)
		if not next.is_empty():
			_upgrade.text = "Melhorar · %d" % int(next.cost)
			_upgrade.disabled = not allowed or simulation.coins < int(next.cost)
		else:
			_upgrade.text = "Nível máximo"
			_upgrade.disabled = true
	elif _selected_pad >= 0:
		_context.text = "Base %d · Escolha a torre. Comprar exige confirmação no botão." % (_selected_pad + 1)
	else:
		_context.text = "Selecione uma base de pedra para construir."
	_update_tutorial_hint()

func _show_result(victory: bool) -> void:
	_result.visible = true
	_result_title.text = "ENSAIO CONCLUÍDO" if str(stage.id) == "arsenal_lab" else ("VITÓRIA!" if victory else "DEFESA ROMPIDA")
	var stars: int = 0
	if victory:
		stars = 1 + int(simulation.lives >= ceili(simulation.initial_lives * 0.5)) + int(simulation.lives == simulation.initial_lives)
	_result_body.text = "%s\n%d estrelas · %d vidas · %d eliminações\nOnda %d/%d · %d:%02d em tempo de jogo\nMoedas ganhas %d · Investimento líquido %d" % ["O caminho está seguro." if victory else "Revise cobertura e upgrades antes da próxima tentativa.", stars, simulation.lives, simulation.kills, simulation.wave_index, simulation.waves.size(), simulation.ticks / (60 * 60), (simulation.ticks / 60) % 60, simulation.earned, simulation.spent]
	if victory and str(stage.id) == "stage_04":
		_result_body.text += "\nVale Verde protegido! Próximo destino: Garganta Rubra."
	if victory and str(stage.id) == "stage_12":
		_result_body.text += "\nOs três caminhos estão protegidos. Campanha concluída!"
	if victory and str(stage.id) == "stage_08":
		_result_body.text += "\nGarganta Rubra protegida! Próximo destino: Pântano Sombrio."
	if str(stage.id) != "arsenal_lab":
		var leaked: Array[String] = []
		for key: String in simulation.leaked_types:
			leaked.append("%d %s" % [int(simulation.leaked_types[key]),str(simulation.catalog.enemies[key].name)])
		if not leaked.is_empty(): _result_body.text += "\nVazaram: " + ", ".join(leaked)
		for tip: String in _result_advice(victory): _result_body.text += "\n• " + tip
	if str(stage.id) == "arsenal_lab":
		_result_body.text = "Alvos eliminados %d · Alvos que passaram %d\nDano útil %.0f · Atraso causado %.1f s\nInvestimento líquido %d moedas\nTroque a formação e compare as especializações nos mesmos cenários." % [simulation.kills, simulation.leaks, simulation.useful_damage, simulation.control_delay, simulation.spent]
	_last_result = simulation.summary()
	_last_result["stars"] = stars
	_last_result["stage"] = str(stage.id)
	_last_result["difficulty"] = difficulty
	battle_completed.emit(_last_result)

func _recycle_actor(actor: RiggedActor3D) -> void:
	var key: String = str(actor.get_meta("type_id", "grunt"))
	if not _enemy_pool.has(key):
		_enemy_pool[key] = []
	(_enemy_pool[key] as Array).append(actor)

func _build_air_route() -> void:
	if simulation.routes.size() < 2: return
	var air: Curve3D = simulation.routes[1]
	var material: StandardMaterial3D = SceneCraft3D.material(Color("b79a5f"))
	for index in range(int(air.get_baked_length() / 1.5)):
		var a: Vector3 = air.sample_baked(index * 1.5)
		var b: Vector3 = air.sample_baked(index * 1.5 + 0.6)
		a.y = 0.16
		b.y = 0.16
		SceneCraft3D.beam(self, a, b, 0.07, material)

func apply_graphics_profile(profile: String) -> void:
	var viewport: Viewport = get_viewport()
	viewport.scaling_3d_scale = 0.7 if profile == "economy" else (1.0 if profile == "quality" else 0.85)
	viewport.msaa_3d = Viewport.MSAA_DISABLED if profile == "economy" else (Viewport.MSAA_4X if profile == "quality" else Viewport.MSAA_2X)
	diorama.sunlight.shadow_enabled = profile != "economy"

func _request_branch(branch: String) -> void:
	if simulation.upgrade(_selected_pad, branch):
		_hint.text = "Especialização em construção. O ramo fica definido ao concluir a obra."
	_update_hud()
func _cycle_priority() -> void:
	var tower: SimTowerV2 = simulation.tower_on_pad(_selected_pad)
	if tower == null or simulation.paused or simulation._terminal(): return
	var choices: Array[String] = ["first", "last", "strongest", "weakest"]
	tower.priority = choices[(choices.find(tower.priority) + 1) % choices.size()]
	_update_hud()

func _sync_enemy_areas() -> void:
	var required: Dictionary = {}
	if not simulation._terminal():
		for enemy: SimEnemyV2 in simulation.enemies.values():
			var aura: bool = not enemy.support.is_empty() and str(enemy.support.kind) == "speed_aura"
			if enemy.ability.is_empty() and not aura: continue
			var kind: String = "aura" if aura else ("warning" if enemy.ability_until > simulation.ticks else (enemy.pending_ability if enemy.rally_until > simulation.ticks else ""))
			if kind.is_empty(): continue
			required[enemy.id] = true
			if _enemy_areas.has(enemy.id) and str((_enemy_areas[enemy.id] as Node3D).get_meta("pool_key")) != kind:
				_retire_area(_enemy_areas[enemy.id] as Node3D)
				_enemy_areas.erase(enemy.id)
			if not _enemy_areas.has(enemy.id): _enemy_areas[enemy.id] = _acquire_area(kind, float(enemy.support.radius) if aura else float(enemy.ability.radius))
			(_enemy_areas[enemy.id] as Node3D).position = enemy.position + Vector3(0, 0.15, 0)
	for id: int in _enemy_areas.keys():
		if not required.has(id):
			_retire_area(_enemy_areas[id] as Node3D)
			_enemy_areas.erase(id)

func _update_tutorial_hint() -> void:
	if not tutorial_enabled or int(stage.index) != 1 or simulation.state != BattleSimV2.State.PREPARATION: return
	if simulation.towers.is_empty():
		_hint.text = "1/3 · Toque numa base de pedra para começar sua defesa." if _selected_pad < 0 else "2/3 · Escolha uma torre nos botões. Confira preço, alcance e tipos de alvo antes de comprar."
	else:
		var ready: bool = false
		for tower: SimTowerV2 in simulation.towers.values():
			if tower.state == SimTowerV2.State.READY: ready = true
		_hint.text = "3/3 · Toque em Iniciar defesa. Depois, as ondas chegam automaticamente." if ready else "3/3 · Aguarde a barra da obra. A torre atacará quando estiver pronta; depois toque em Iniciar defesa."
func _show_help() -> void:
	_show_info("Como defender o caminho", "• Inimigos que chegam à bandeira retiram vidas. Guarde a saída.\n• Toque numa base e confirme a torre. Confira alcance e alvos no botão.\n• Construção e melhoria levam tempo; a torre fica sem atacar durante a obra.\n• A primeira onda é manual. As demais chegam sozinhas; chamar antes rende até 5 moedas.\n• Selecione torres para melhorar, especializar, vender ou mudar a ordem dos alvos.\n• Arqueira e Cristal atingem ar; Canhão e Alquimista atingem só o chão.\n• Armadura pede magia, sangramento e cobertura. Chefes avisam antes das habilidades.\n• Pausa congela a batalha. 2× acelera o jogo; use o Guia no mapa para conhecer cada função.")

func _show_forecast() -> void:
	var lines: Array[String] = ["Depois da primeira onda, a sequência é automática. Fechar esta previsão restaura a pausa anterior."]
	var kinds: Dictionary = {}
	for index in range(simulation.wave_index,mini(simulation.wave_index + 2,simulation.waves.size())):
		lines.append("Onda %d\n%s" % [index + 1,_describe_wave(index)])
		for group: Dictionary in simulation.waves[index].groups: kinds[str(group.enemy)] = true
	for key: String in kinds:
		var enemy: Dictionary = simulation.catalog.enemies[key]
		lines.append("%s: %s" % [str(enemy.name),str(enemy.get("description",""))])
	_show_info("Próximas ondas", "\n\n".join(lines))

func _show_info(title: String, description: String) -> void:
	if is_instance_valid(_help_layer): return
	_pause_before_help = simulation.paused
	simulation.paused = true
	get_tree().paused = true
	_help_layer = CanvasLayer.new()
	_help_layer.layer = 30
	_help_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_help_layer)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_help_layer.add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -650
	panel.offset_right = 650
	panel.offset_top = -390
	panel.offset_bottom = 390
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("10272d")
	style.set_content_margin_all(36)
	panel.add_theme_stylebox_override("panel", style)
	_help_layer.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	panel.add_child(column)
	_label(column, title, 42, Color("ecd49a"))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var body: Label = _label(scroll, description, 27)
	body.name = "InfoBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_button(column, "Voltar à defesa", _dismiss_help, 300)
	_update_hud()
func _dismiss_help() -> void:
	if not is_instance_valid(_help_layer): return
	_help_layer.queue_free()
	_help_layer = null
	simulation.paused = _pause_before_help
	get_tree().paused = _pause_before_help
	_update_hud()

func _sound(cue: String, bus: StringName = AudioServiceNode.BUS_SFX) -> void:
	var audio: AudioServiceNode = get_node_or_null("/root/AudioService") as AudioServiceNode
	if audio != null: audio.play_event(cue, bus)

func _create_enemy_actor(type_id: String, phase: float) -> RiggedActor3D:
	var actor: RiggedActor3D
	if type_id == "boss_ruin": actor = RuinGuardianActorV2.new()
	elif type_id == "boss_colossus": actor = ColossusActorV2.new()
	elif type_id.begins_with("flyer"): actor = FlyingActorV2.new()
	elif type_id in ["swarm", "burrower"]: actor = CrawlerActorV2.new()
	else: actor = RiggedActor3D.new()
	var definition: Dictionary = simulation.catalog.enemies[type_id]
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	actor.set_meta("type_id", type_id)
	actor.model_path = "res://art/models/%s.glb" % str(definition.get("model", "goblin"))
	actor.set_meta("equipment", definition.get("equipment", []))
	actor.initial_phase = phase
	add_child(actor)
	actor.scale = Vector3.ONE * float(definition.scale)
	return actor

func _prepare_enemy_models() -> void:
	_warming_up = true
	var kinds: Dictionary = {}
	for wave: Dictionary in stage.waves:
		for group: Dictionary in wave.groups: kinds[str(group.enemy)] = true
	for key: String in kinds.keys():
		var definition: Dictionary = simulation.catalog.enemies[key]
		var ability: Dictionary = definition.get("ability", {})
		if ability.has("summon_enemy"): kinds[str(ability.summon_enemy)] = true
	var primed: Array[RiggedActor3D] = []
	var rendered: bool = DisplayServer.get_name() != "headless"
	var curtain: CanvasLayer
	if rendered:
		curtain = CanvasLayer.new()
		curtain.layer = 100
		add_child(curtain)
		var background: ColorRect = ColorRect.new()
		background.color = Color("10272d")
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		curtain.add_child(background)
		var text: Label = Label.new()
		text.text = "Preparando o campo…"
		text.add_theme_font_size_override("font_size", 34)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.add_child(text)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	for key: String in kinds:
		var actor: RiggedActor3D = _create_enemy_actor(key, 0)
		var index: int = primed.size()
		actor.position = Vector3((index % 5 - 2) * 3, 0.1, (index / 5 - 1) * 3)
		actor.reset_physics_interpolation()
		actor.visible = rendered
		primed.append(actor)
	if rendered:
		for frame in range(3): await get_tree().process_frame
	for actor: RiggedActor3D in primed:
		actor.visible = false
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		_recycle_actor(actor)
	if is_instance_valid(curtain): curtain.queue_free()
	_warming_up = false

func _describe_wave(index: int) -> String:
	if index < 0 or index >= simulation.waves.size(): return ""
	var preview: Array[String] = []
	var labels: Array = stage.get("route_labels",[])
	for group: Dictionary in simulation.waves[index].groups:
		var key: String = str(group.enemy)
		var route_id: int = int(group.get("route",0))
		var route_hint: String = " · " + str(labels[route_id]) if route_id < labels.size() else ""
		var layer_hint: String = " (ar · trilha dourada)" if str(simulation.catalog.enemies[key].layer) == "air" else ""
		preview.append("%d %s%s%s" % [int(group.count),str(simulation.catalog.enemies[key].name),layer_hint,route_hint])
	return " + ".join(preview)

func _result_advice(victory: bool) -> Array[String]:
	var advice: Array[String] = []
	if int(simulation.leaked_layers.get("air",0)) > 0:
		advice.append("Cubra a trilha aérea com Farol Celeste, Arqueira ou Cristal Gélido.")
	if int(simulation.leaked_types.get("resistant",0)) > 0:
		advice.append("Sentinelas reduzem magia: combine Canhão e sangramento para atravessar sua defesa.")
	elif int(simulation.leaked_types.get("armored",0)) + int(simulation.leaked_types.get("armored_elite",0)) + int(simulation.leaked_types.get("shieldbearer",0)) > 0:
		advice.append("Contra proteção física, combine dano mágico, sangramento e foco de alvo.")
	if advice.size() < 2 and int(simulation.leaked_types.get("runner",0)) + int(simulation.leaked_types.get("runner_veteran",0)) > 0:
		advice.append("Contenha corredores com Cristal Gélido e cobertura na saída." if int(stage.index)>=2 else "Melhore a cadência das Arqueiras e cubra a saída contra corredores.")
	if advice.size() < 2 and simulation.leaks > 0 and simulation.coins >= 100:
		advice.append("Restaram %d moedas. Planeje melhorias nos intervalos para evitar obras no momento crítico." % simulation.coins)
	if advice.size() < 2 and not victory and simulation.spent == 0:
		advice.append("Construa antes de iniciar: a primeira onda espera pela sua preparação.")
	if advice.is_empty():
		advice.append("Experimente uma formação diferente ou um desafio opcional." if victory else "Reveja alcance e prioridade das torres nos pontos onde a defesa perdeu cobertura.")
	return advice.slice(0,2)

func handle_back_request() -> void:
	if _warming_up: return
	var frame: int = Engine.get_process_frames()
	if frame == _last_back_frame: return
	_last_back_frame = frame
	if is_instance_valid(_help_layer): _dismiss_help()
	elif simulation._terminal(): exit_requested.emit()
	elif _selected_pad >= 0: _select_pad(-1)
	else: _toggle_pause()
