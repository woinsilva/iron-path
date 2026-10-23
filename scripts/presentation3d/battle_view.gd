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
var _lives_label: Label
var _coins_label: Label
var _actions: PanelContainer
var _tower_title: Label
var _tower_stats: Dictionary = {}
var _tap_start: Vector2 = Vector2(-1000, -1000)
## When the tower card last opened (ms); its buttons ignore presses for a moment after it appears.
var _card_opened_at: int = 0
var _card_bar: PanelContainer
var _hud_blockers: Array[Control] = []
var _placing: String = ""
var _ghost: Node3D
var _ghost_ring: MeshInstance3D
var _ghost_valid: bool = false
var _ghost_overlay: StandardMaterial3D
var _bases: Dictionary = {}
## Largest height difference under a tower's footprint (m) that a stone plinth may make up.
const MAX_FOOTING_DROP: float = 1.1
## A defeated enemy lies for CORPSE_SECONDS; during the last CORPSE_SINK seconds it sinks into the ground.
const CORPSE_SECONDS: float = 1.9
const CORPSE_SINK: float = 0.7
## One shared emitter for every dust puff (arrivals, footsteps, falls) keeps the cost flat.
var _dust: Node3D
var _dust_pools: Dictionary = {}
var _step_clock: float = 0.0

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if stage.is_empty():
		stage = JSON.parse_string(FileAccess.get_file_as_string(stage_path).trim_prefix("\ufeff")) as Dictionary
	diorama = Diorama3D.new()
	diorama.route_points = stage.get("route_points", [])
	diorama.additional_route_points = stage.get("extra_route_points", [])
	diorama.biome = str(stage.get("biome", "vale"))
	diorama.scenery = str(stage.get("scenery", ""))
	diorama.relief = float(stage.get("relief", 0.0))
	diorama.photo = bool(stage.get("photo", false))
	diorama.descent = stage.get("descent", [])
	diorama.flats = stage.get("flats", [])
	diorama.mounds = stage.get("mounds", [])
	diorama.descent_drop = float(stage.get("descent_drop", 2.6))
	# Underground routes, counted among the ground roads (the air route sits at simulation id 1).
	for route_id: int in stage.get("burrow_routes", []):
		diorama.burrow_routes.append(route_id - (1 if stage.has("air_route_points") else 0))
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
	if stage.has("river"):
		diorama.river_x = float(stage.river[0])
		diorama.river_width = float(stage.river[1])
	add_child(diorama)
	var landmarks: StageLandmarksV2 = StageLandmarksV2.new()
	# Hand-dressed maps build their own set pieces (MapSceneryV2); the older generic ones stay off there.
	var generic: bool = not stage.has("scenery")
	landmarks.forge_enabled = int(stage.index) == 8 and generic
	landmarks.fortress_enabled = int(stage.index) == 7 and generic
	landmarks.quarry_enabled = int(stage.index) == 6 and generic
	landmarks.guard_gate_enabled = int(stage.index) == 4 and generic
	landmarks.orchard_enabled = int(stage.index) == 2 and generic
	landmarks.show_mill = int(stage.index) == 1
	landmarks.entrance = diorama.route.sample_baked(0)
	landmarks.endpoint = diorama.route.sample_baked(diorama.route.get_baked_length())
	add_child(landmarks)
	for piece: Node in landmarks.get_children():
		if piece is Node3D: (piece as Node3D).position.y += diorama.terrain_height((piece as Node3D).position)
	if diorama.photo_style(): MapSceneryV2.weather(landmarks)
	simulation = StageSessionV2.create(stage, difficulty)
	if not stage.has("blocked_zones"):
		simulation.blocked_zones.append(Rect2(diorama.river_x - diorama.river_width * 0.5 - 0.7, -16, diorama.river_width + 1.4, 32))
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

## Build spots are free now: the stage's authored pads only seed tests and tools, so nothing is drawn for them.
func _build_pads() -> void:
	_pads.clear()

func _physics_process(delta: float) -> void:
	if _warming_up: return
	simulation.advance(delta)
	_handle_events(simulation.consume_events())
	for id: int in _sites:
		var worked: SimTowerV2 = simulation.towers.get(id)
		if worked != null and worked.state != SimTowerV2.State.READY: (_sites[id] as TowerEvolutionV2).set_progress(float(worked.work_elapsed) / worked.work_ticks)
	_sync_enemies(delta)
	_sync_towers(delta)
	_sync_projectiles()
	_sync_fields()
	_sync_enemy_areas()
	for index in range(_corpses.size() - 1, -1, -1):
		var entry: Dictionary = _corpses[index]
		entry.remaining = float(entry.remaining) - delta
		if float(entry.remaining) < CORPSE_SINK: (entry.actor as RiggedActor3D).position.y -= delta * 1.1
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
				if state != null and state.layer != "air" and not state.underground(): _dust_burst(actor.position, 14, 1.6)
			"killed", "leaked":
				if enemy_views.has(int(event.id)):
					var actor: RiggedActor3D = enemy_views[int(event.id)]
					if str(event.kind) == "killed":
						actor.die()
						# Falls (death clip), lies still a moment, then sinks into the ground before recycling.
						_corpses.append({"actor": actor, "remaining": CORPSE_SECONDS})
						if actor.position.y < 1.5: _dust_burst(actor.position, 8, 0.6)
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
					if not bool(event.get("cancelled", false)): _celebrate_upgrade(tower_views[int(event.id)] as Node3D, upgraded.level)
					else: (tower_views[int(event.id)] as Node3D).scale = Vector3.ONE * TowerUpgradeDecorV2.level_scale(upgraded.level)
					if simulation.tower_on_pad(_selected_pad) == upgraded: _update_ring()
				if _sites.has(int(event.id)):
					(_sites[int(event.id)] as TowerEvolutionV2).finish()
			"upgrade_started":
				(tower_views[int(event.id)] as Node3D).call("cancel_attack")
				(_sites[int(event.id)] as TowerEvolutionV2).begin()
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
	var display: Node3D = _tower_display(tower.type_id)
	var ground: Vector2 = diorama.footprint_heights(tower.position, 1.0)
	display.position = tower.position + Vector3(0, 0.1 + ground.y, 0)
	add_child(display)
	display.visible = false
	tower_views[id] = display
	var base: Node3D = Node3D.new()
	base.position = display.position
	add_child(base)
	# On a slope the base becomes a stone plinth reaching down to the lowest ground under it.
	var drop: float = ground.y - ground.x
	if drop > 0.05: SceneCraft3D.cylinder(base, 1.04, drop + 0.3, Vector3(0, -(drop + 0.3) / 2.0 + 0.02, 0), SceneCraft3D.material(Color("8f8a76")), 20)
	SceneCraft3D.cylinder(base, 1.0, 0.16, Vector3(0, 0.08, 0), SceneCraft3D.material(Color("aca58a")), 20)
	for prop: Node in get_tree().get_nodes_in_group(MapSceneryV2.SCENERY_GROUP):
		if prop is Node3D and (prop as Node3D).visible and BattleSimV2.distance_xz((prop as Node3D).global_position, tower.position) < 1.7:
			(prop as Node3D).visible = false
			prop.set_meta("hidden_by", id)
	SceneCraft3D.cylinder(base, 0.84, 0.05, Vector3(0, 0.18, 0), SceneCraft3D.material(Color("757f68")), 20)
	_bases[id] = base
	var site: TowerEvolutionV2 = TowerEvolutionV2.new()
	site.position = display.position
	add_child(site)
	_sites[id] = site

func _tower_display(type_id: String) -> Node3D:
	if type_id == "archer":
		var archer: ArcherDisplay3D = ArcherDisplay3D.new()
		archer.simulation_controlled = true
		return archer
	if type_id == "cannon": return CannonDisplay3D.new()
	if type_id == "bleed": return BallistaDisplayV2.new()
	if type_id == "banner": return BannerDisplayV2.new()
	var magic: MagicDisplayV2 = MagicDisplayV2.new()
	magic.family = type_id
	return magic

func _remove_tower(id: int) -> void:
	if tower_views.has(id):
		var display: Node3D = tower_views[id]
		display.queue_free()
		tower_views.erase(id)
	if _sites.has(id):
		(_sites[id] as Node3D).queue_free()
		_sites.erase(id)
	if _bases.has(id):
		(_bases[id] as Node3D).queue_free()
		_bases.erase(id)
	for prop: Node in get_tree().get_nodes_in_group(MapSceneryV2.SCENERY_GROUP):
		if int(prop.get_meta("hidden_by", -1)) == id:
			(prop as Node3D).visible = true
			prop.remove_meta("hidden_by")
	if simulation.tower_on_pad(_selected_pad) == null: _select_pad(-1)

func _sync_enemies(delta: float) -> void:
	# Walking enemies kick up a little dust a few times per second (a third of them on each pulse).
	_step_clock += delta
	var footsteps: bool = fmod(_step_clock, 0.1) < delta
	for id: int in enemy_views:
		var actor: RiggedActor3D = enemy_views[id]
		var state: SimEnemyV2 = simulation.enemies.get(id) as SimEnemyV2
		if state == null:
			continue
		var old: Vector3 = actor.position
		var drawn: Vector3 = simulation.display_position(state)
		actor.position = drawn + Vector3(0, diorama.walk_surface_height(drawn), 0)
		if state.layer == "air": actor.position.y = maxf(drawn.y, float(simulation.catalog.enemies[state.type_id].flight_height)) + 0.1
		actor.health_ratio = state.health / state.maximum_health
		if actor is CrawlerActorV2:
			(actor as CrawlerActorV2).set_summoned(state.summoner_id >= 0)
			(actor as CrawlerActorV2).set_underground(state.underground())
		if actor is RuinGuardianActorV2: (actor as RuinGuardianActorV2).set_posture(state.pending_ability, state.ability_until > simulation.ticks or state.rally_until > simulation.ticks)
		if actor is ColossusActorV2: (actor as ColossusActorV2).set_ability_state(state.ability_until > simulation.ticks)
		actor.animate_motion((actor.position - old) / maxf(delta, 0.001), delta)
		if footsteps and state.layer != "air" and not state.underground() and actor.position.distance_to(old) > 0.001 and (id % 3) == (int(_step_clock * 30.0) % 3):
			_dust_burst(actor.position, 1, 0.35)
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
		# A tower under construction or upgrade cannot fire, so it stops tracking enemies too.
		if tower.state != SimTowerV2.State.READY: continue
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
	if event.is_action_pressed("ui_cancel"):
		if not _placing.is_empty(): _end_placement()
		elif _selected_pad >= 0: _select_pad(-1)
		else: _toggle_pause()
		return
	# Touch drives everything; desktop clicks arrive as emulated touches (project setting).
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag): return
	var point: Vector2 = event.position
	if _over_hud(point): return
	var ground: Variant = _ground_point(point)
	if ground == null: return
	if not _placing.is_empty():
		_move_ghost(ground as Vector3)
		if event is InputEventScreenTouch and not event.pressed: _confirm_placement()
		return
	# Select on release of a tap, so the card that opens is not hit by the same press/release (mouse or finger).
	if event is InputEventScreenTouch:
		if event.pressed: _tap_start = point
		elif _tap_start.distance_to(point) < 24.0: _select_pad(_tower_pad_near(ground as Vector3))

## Drag that starts on a tower card keeps feeding the ghost even while the finger is still over the HUD.
func _input(event: InputEvent) -> void:
	if _placing.is_empty() or _warming_up: return
	if event is InputEventScreenDrag:
		var ground: Variant = _ground_point(event.position)
		if ground != null and not _over_hud(event.position): _move_ghost(ground as Vector3)
	elif event is InputEventScreenTouch and not event.pressed and is_instance_valid(_ghost) and _ghost.visible and not _over_hud(event.position):
		_confirm_placement()
		get_viewport().set_input_as_handled()

func _ground_point(point: Vector2) -> Variant:
	var camera: Camera3D = diorama.camera
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(point), camera.project_ray_normal(point))
	# On rolling terrain, slide along the view ray until it meets the surface (a few steps converge).
	for _step in range(4):
		if hit == null: return null
		var height: float = diorama.terrain_height(hit as Vector3)
		hit = Plane(Vector3.UP, height).intersects_ray(camera.project_ray_origin(point), camera.project_ray_normal(point))
	return hit

func _over_hud(point: Vector2) -> bool:
	for blocker: Control in _hud_blockers:
		if is_instance_valid(blocker) and blocker.is_visible_in_tree() and blocker.get_global_rect().has_point(point): return true
	return false

func _tower_pad_near(point: Vector3) -> int:
	var selected: int = -1
	var closest: float = 1.3
	for tower: SimTowerV2 in simulation.towers.values():
		if tower.state == SimTowerV2.State.BUILDING: continue
		var distance: float = BattleSimV2.distance_xz(tower.position, point)
		if distance < closest:
			closest = distance
			selected = tower.pad
	return selected

## Tower card pressed: a ghost of that tower follows the finger, green where it may stand and red on the road.
func _begin_placement(type_id: String) -> void:
	if simulation.paused or simulation._terminal(): return
	if _placing == type_id:
		_end_placement()
		return
	_end_placement()
	_select_pad(-1)
	_placing = type_id
	_ghost = _tower_display(type_id)
	_ghost.visible = false
	add_child(_ghost)
	_ghost_overlay = StandardMaterial3D.new()
	_ghost_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for mesh: Node in _ghost.find_children("*", "GeometryInstance3D", true, false):
		(mesh as GeometryInstance3D).material_overlay = _ghost_overlay
		(mesh as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost_ring = SceneCraft3D.mesh(_ghost, _ring_mesh(float(simulation.catalog.towers[type_id].levels[0].range), 0.06), Vector3(0, 0.06, 0), _ring_material(Color.WHITE))
	_hint.text = "Arraste até um lugar livre e solte. Vermelho: na rua, na água ou colado em outra torre."
	_update_hud()

func _move_ghost(point: Vector3) -> void:
	if not is_instance_valid(_ghost): return
	_ghost.visible = true
	_ghost.position = Vector3(point.x, 0.1 + diorama.footprint_heights(point, 1.0).y, point.z)
	var affordable: bool = simulation.coins >= int(simulation.catalog.towers[_placing].levels[0].cost)
	var ground: Vector2 = diorama.footprint_heights(point, 1.0)
	# Very steep ground would need a tall pillar under the tower; the ghost turns red there too.
	_ghost_valid = affordable and simulation.can_build_at(point) and ground.y - ground.x <= MAX_FOOTING_DROP
	var tint: Color = Color(0.35, 1.0, 0.45, 0.42) if _ghost_valid else Color(1.0, 0.18, 0.15, 0.55)
	_ghost_overlay.albedo_color = tint
	(_ghost_ring.material_override as StandardMaterial3D).albedo_color = Color(tint, 1.0)

func _confirm_placement() -> void:
	if not is_instance_valid(_ghost) or not _ghost.visible: return
	if not _ghost_valid:
		var footing: Vector2 = diorama.footprint_heights(_ghost.position, 1.0)
		if simulation.coins < int(simulation.catalog.towers[_placing].levels[0].cost): _hint.text = "Moedas insuficientes para esta torre."
		elif footing.y - footing.x > MAX_FOOTING_DROP: _hint.text = "Terreno inclinado demais aqui: escolha um ponto mais plano."
		else: _hint.text = "Aqui não dá: escolha um ponto fora da rua e da água, com espaço entre as torres."
		# Releasing on a red spot drops the ghost; the player picks the card again to retry.
		_end_placement()
		_update_hud()
		return
	var pad: int = simulation.build_at(_ghost.position, _placing)
	if pad < 0:
		_end_placement()
		_update_hud()
		return
	_hint.text = "Construção iniciada. A torre atacará ao terminar a obra."
	_end_placement()
	# The new tower is not selected: its card only opens when the player taps it once it stands.
	_select_pad(-1)

func _end_placement() -> void:
	_placing = ""
	if is_instance_valid(_ghost): _ghost.queue_free()
	_ghost = null
	if is_instance_valid(_card_bar): _update_hud()

func _select_pad(index: int) -> void:
	if index >= 0 and index != _selected_pad: _card_opened_at = Time.get_ticks_msec()
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
	_range_ring = SceneCraft3D.mesh(self, _ring_mesh(radius, 0.055), simulation.pads[_selected_pad] + Vector3(0, 0.15 + diorama.terrain_height(simulation.pads[_selected_pad]), 0), _ring_material(Color("8bd0c4")))
	_range_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Gold ring: the reach the next upgrade buys, so the player sees the gain before paying for it.
	if tower == null or tower.state != SimTowerV2.State.READY or tower.level == 3: return
	var next: Dictionary = simulation.next_upgrade(tower)
	if next.is_empty() or not next.has("range"): return
	var reach: float = radius * float(next.range) / maxf(0.01, float(simulation.stats(tower).range))
	if reach <= radius + 0.01: return
	var preview: MeshInstance3D = SceneCraft3D.mesh(_range_ring, _ring_mesh(reach, 0.035), Vector3(0, 0.01, 0), _ring_material(Color("f2d07a")))
	preview.name = "NextRangeRing"
	preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Upgrade feedback: the tower springs up from a squash, with a dust ring and, at L6, a golden flash.
func _celebrate_upgrade(display: Node3D, level: int) -> void:
	var pop: Tween = display.create_tween()
	var size: float = TowerUpgradeDecorV2.level_scale(level)
	display.scale = Vector3(1.15, 0.7, 1.15) * size
	pop.tween_property(display, "scale", Vector3(0.92, 1.12, 0.92) * size, 0.12).set_trans(Tween.TRANS_QUAD)
	pop.tween_property(display, "scale", Vector3.ONE * size, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var dust: MeshInstance3D = SceneCraft3D.mesh(self, _ring_mesh(0.6, 0.18), display.position + Vector3(0, 0.12, 0), _ring_material(Color(0.93, 0.86, 0.7, 0.85) if level < 6 else Color("ffd36a")))
	(dust.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var spread: Tween = dust.create_tween().set_parallel()
	spread.tween_property(dust, "scale", Vector3.ONE * (3.2 if level < 6 else 4.5), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	spread.tween_property(dust.material_override, "albedo_color:a", 0.0, 0.55)
	spread.chain().tween_callback(dust.queue_free)
	if level < 2: return
	_sound("ui")
	# Evolution: the new parts grow into place under a column of light and a burst of golden sparks.
	var decor: Node3D = display.get_node_or_null("LevelDecor") as Node3D
	if decor != null:
		decor.scale = Vector3.ONE * 0.05
		var grow: Tween = decor.create_tween()
		grow.tween_property(decor, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var beam: CylinderMesh = CylinderMesh.new()
	beam.top_radius = 0.75
	beam.bottom_radius = 0.95
	beam.height = 7.0
	beam.radial_segments = 20
	beam.cap_top = false
	beam.cap_bottom = false
	var light: StandardMaterial3D = StandardMaterial3D.new()
	light.albedo_color = Color(1.0, 0.86, 0.45, 0.7) if level < 6 else Color(0.85, 0.65, 1.0, 0.8)
	light.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	light.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	light.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	light.cull_mode = BaseMaterial3D.CULL_DISABLED
	var column: MeshInstance3D = SceneCraft3D.mesh(self, beam, display.position + Vector3(0, 3.5, 0), light)
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	column.scale = Vector3(0.3, 1, 0.3)
	var shine: Tween = column.create_tween().set_parallel()
	shine.tween_property(column, "scale", Vector3(1.4, 1, 1.4), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	shine.tween_property(light, "albedo_color:a", 0.0, 0.75).set_ease(Tween.EASE_IN)
	shine.chain().tween_callback(column.queue_free)
	var spark: SphereMesh = SphereMesh.new()
	spark.radius = 0.06
	spark.height = 0.12
	spark.radial_segments = 6
	spark.rings = 3
	var gold: StandardMaterial3D = SceneCraft3D.material(Color("ffe08a") if level < 6 else Color("d9b8ff"))
	gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark.material = gold
	var burst: CPUParticles3D = CPUParticles3D.new()
	burst.mesh = spark
	burst.amount = 26 if level < 6 else 44
	burst.lifetime = 1.1
	burst.one_shot = true
	burst.explosiveness = 0.9
	burst.direction = Vector3.UP
	burst.spread = 55
	burst.gravity = Vector3(0, -5, 0)
	burst.initial_velocity_min = 2.5
	burst.initial_velocity_max = 4.5
	burst.position = display.position + Vector3(0, 1.5, 0)
	add_child(burst)
	burst.emitting = true
	var cleanup: Tween = burst.create_tween()
	cleanup.tween_interval(1.4)
	cleanup.tween_callback(burst.queue_free)

## Puffs of earth-coloured dust at a point: arrivals through the gates, falls and footsteps.
func _dust_burst(point: Vector3, count: int, strength: float) -> void:
	if _dust == null:
		_dust = Node3D.new()
		_dust.name = "DustPuffs"
		add_child(_dust)
		_dust.add_to_group(BiomeDressingV2.DETAIL_GROUP)
	if not _dust.visible: return
	# Small round-robin pools of one-shot emitters, one pool per puff size.
	var pool: Array = _dust_pools.get(count, [])
	if pool.is_empty():
		_dust_pools[count] = pool
		var puff: SphereMesh = SphereMesh.new()
		puff.radius = 0.24
		puff.height = 0.48
		puff.radial_segments = 6
		puff.rings = 3
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.74, 0.66, 0.52, 0.7)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		puff.material = material
		var fade: Gradient = Gradient.new()
		fade.set_color(0, Color(1, 1, 1, 0.8))
		fade.set_color(1, Color(1, 1, 1, 0))
		var grow: Curve = Curve.new()
		grow.add_point(Vector2(0, 0.6))
		grow.add_point(Vector2(1, 1.6))
		for index in range(24 if count <= 2 else 10):
			var emitter: CPUParticles3D = CPUParticles3D.new()
			emitter.mesh = puff
			emitter.amount = count
			emitter.lifetime = 0.9
			emitter.one_shot = true
			emitter.explosiveness = 1.0
			emitter.emitting = false
			emitter.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			emitter.emission_sphere_radius = 0.25
			emitter.direction = Vector3.UP
			emitter.spread = 75
			emitter.gravity = Vector3(0, 0.4, 0)
			emitter.damping_min = 2.5
			emitter.damping_max = 3.5
			emitter.color_ramp = fade
			emitter.scale_amount_curve = grow
			_dust.add_child(emitter)
			pool.append(emitter)
		_dust_pools[str(count) + "_next"] = 0
	var next: int = int(_dust_pools.get(str(count) + "_next", 0))
	var chosen: CPUParticles3D = pool[next % pool.size()]
	_dust_pools[str(count) + "_next"] = next + 1
	chosen.initial_velocity_min = strength * 0.8
	chosen.initial_velocity_max = strength * 1.6
	chosen.global_position = point + Vector3(0, 0.15, 0)
	chosen.restart()

func _ring_mesh(radius: float, half_width: float) -> ArrayMesh:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(96):
		var a: float = TAU * index / 96.0
		var b: float = TAU * (index + 1) / 96.0
		var inner_a: Vector3 = Vector3(cos(a), 0, sin(a)) * (radius - half_width)
		var inner_b: Vector3 = Vector3(cos(b), 0, sin(b)) * (radius - half_width)
		var outer_a: Vector3 = Vector3(cos(a), 0, sin(a)) * (radius + half_width)
		var outer_b: Vector3 = Vector3(cos(b), 0, sin(b)) * (radius + half_width)
		for vertex: Vector3 in [inner_a, inner_b, outer_a, outer_a, inner_b, outer_b]:
			surface.add_vertex(vertex)
	return surface.commit()

func _ring_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = SceneCraft3D.material(color)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _toggle_pause() -> void:
	if simulation._terminal():
		return
	simulation.paused = not simulation.paused
	get_tree().paused = simulation.paused
	_update_hud()

func _toggle_speed() -> void:
	# 1× → 2× → 4× → 1×. The simulation stays tick-based, so results match at every speed.
	Engine.time_scale = 2.0 if Engine.time_scale == 1.0 else (4.0 if Engine.time_scale == 2.0 else 1.0)
	_update_hud()

func _purchase(type_id: String) -> void:
	if _selected_pad >= 0 and simulation.build(_selected_pad, type_id):
		_hint.text = "Construção iniciada. A torre atacará ao terminar a obra."
	else:
		_hint.text = "Arraste a carta até um lugar livre e confira as moedas disponíveis."
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
	var style: StyleBoxFlat = MenuKitV2.box(Color(0.03, 0.09, 0.1, 0.9), Color(MenuKitV2.GOLD, 0.35), 0, 0, 14)
	style.content_margin_left = 28
	style.content_margin_right = 28
	# Rounded and edged only on the side that faces the battlefield.
	var faces_down: bool = preset == Control.PRESET_TOP_WIDE
	style.border_width_bottom = 3 if faces_down else 0
	style.border_width_top = 0 if faces_down else 3
	style.corner_radius_bottom_left = 26 if faces_down else 0
	style.corner_radius_bottom_right = 26 if faces_down else 0
	style.corner_radius_top_left = 0 if faces_down else 26
	style.corner_radius_top_right = 0 if faces_down else 26
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	panel.theme = MenuKitV2.theme()
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
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(button)
	MenuKitV2.feedback(button)
	return button

## Full-screen battle: the map fills the screen and the HUD floats in the corners, like mobile tower defense.
func _build_hud() -> void:
	_canvas = CanvasLayer.new()
	_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_canvas)
	var overlay: BattleOverlayV2 = BattleOverlayV2.new()
	overlay.battle = self
	_canvas.add_child(overlay)
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = MenuKitV2.theme()
	_canvas.add_child(root)
	var frame: MarginContainer = MenuKitV2.safe_margin(root, 22)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var board: Control = Control.new()
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(board)
	# Top-left: resources, wave pill and the next-wave preview.
	var status: VBoxContainer = VBoxContainer.new()
	status.add_theme_constant_override("separation", 8)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(status)
	var chips: HBoxContainer = HBoxContainer.new()
	chips.add_theme_constant_override("separation", 10)
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_child(chips)
	_lives_label = _chip(chips, "heart", Color("ff6b6b"))
	_coins_label = _chip(chips, "coin", Color("f2c54e"))
	_wave_label = _button(chips, "Onda", _show_forecast, 200)
	_wave_label.custom_minimum_size = Vector2(200, 72)
	_wave_label.tooltip_text = "Inspecionar as duas próximas ondas"
	_top_stats = _hud_label(status, "", 22, Color("e8eee6"))
	_next_wave = _hud_label(status, "", 21, Color("cfe0dc"))
	_next_wave.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next_wave.max_lines_visible = 2
	_next_wave.custom_minimum_size = Vector2(620, 0)
	_hud_blockers.append(chips)
	# Top-right: round controls.
	var controls: HBoxContainer = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	board.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	controls.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_speed = _round(controls, "fast", "Velocidade", _toggle_speed)
	_speed.icon = null
	_speed.add_theme_font_size_override("font_size", 32)
	_pause = _round(controls, "pause", "Pausar", _toggle_pause)
	_round(controls, "restart", "Reiniciar", _restart)
	_round(controls, "help", "Como jogar", _show_help)
	_round(controls, "home", "Voltar ao mapa", func() -> void: get_tree().paused = false; exit_requested.emit())
	_hud_blockers.append(controls)
	# Boss bar, top centre.
	_boss_panel = PanelContainer.new()
	_boss_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_panel.offset_left = -300
	_boss_panel.offset_right = 300
	_boss_panel.offset_top = 112
	_boss_panel.offset_bottom = 196
	_boss_panel.add_theme_stylebox_override("panel", MenuKitV2.box(Color(0.08, 0.05, 0.05, 0.85), Color("e7a982"), 18, 2, 8))
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(_boss_panel)
	var boss_column: VBoxContainer = VBoxContainer.new()
	_boss_panel.add_child(boss_column)
	_boss_label = _hud_label(boss_column, "", 22, Color("ffe1c8"))
	_boss_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boss_label.max_lines_visible = 2
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_health = ProgressBar.new()
	_boss_health.custom_minimum_size.y = 18
	_boss_health.show_percentage = false
	_boss_health.add_theme_stylebox_override("fill", MenuKitV2.box(Color("e0704f"), Color(0, 0, 0, 0), 6, 0, 0))
	_boss_health.add_theme_stylebox_override("background", MenuKitV2.box(Color(0, 0, 0, 0.5), Color(0, 0, 0, 0), 6, 0, 0))
	boss_column.add_child(_boss_health)
	_boss_panel.visible = false
	# Bottom: status lines over a compact strip of tower cards, start button on the right.
	var bottom: VBoxContainer = VBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_context = _hud_label(bottom, "", 24, Color("f6e3ad"))
	_context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_context.max_lines_visible = 2
	_hint = _hud_label(bottom, "Arraste uma torre da barra para o mapa. Depois inicie a primeira onda; as próximas chegam sozinhas.", 21, Color("dbe6e2"))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.max_lines_visible = 2
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(row)
	_card_bar = PanelContainer.new()
	_card_bar.add_theme_stylebox_override("panel", MenuKitV2.box(Color(0.03, 0.08, 0.09, 0.78), Color(MenuKitV2.GOLD, 0.45), 22, 2, 8))
	row.add_child(_card_bar)
	_hud_blockers.append(_card_bar)
	var cards: HBoxContainer = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 8)
	_card_bar.add_child(cards)
	for type_id: String in stage.allowed_towers:
		_purchase_buttons[type_id] = _card(cards, type_id)
	_start = _button(row, "Iniciar defesa", _start_or_early, 240)
	_start.custom_minimum_size = Vector2(240, 120)
	_start.size_flags_vertical = Control.SIZE_SHRINK_END
	MenuKitV2.primary(_start)
	_hud_blockers.append(_start)
	# Floating actions next to the selected tower.
	_actions = PanelContainer.new()
	_actions.add_theme_stylebox_override("panel", MenuKitV2.box(Color(0.03, 0.08, 0.09, 0.9), Color(MenuKitV2.GOLD, 0.6), 20, 2, 8))
	_actions.visible = false
	root.add_child(_actions)
	_hud_blockers.append(_actions)
	# One card for the selected tower: name and level, its numbers, what the next level buys, and the actions.
	var card: VBoxContainer = VBoxContainer.new()
	card.add_theme_constant_override("separation", 6)
	_actions.add_child(card)
	_tower_title = Label.new()
	_tower_title.add_theme_font_size_override("font_size", 28)
	_tower_title.add_theme_color_override("font_color", MenuKitV2.GOLD)
	card.add_child(_tower_title)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 2)
	card.add_child(grid)
	for key: String in ["damage", "rate", "range", "layer"]:
		var name_label: Label = Label.new()
		name_label.text = {"damage": "Dano", "rate": "Cadência", "range": "Alcance", "layer": "Alvos"}[key]
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color(0.75, 0.84, 0.82))
		grid.add_child(name_label)
		var value: Label = Label.new()
		value.add_theme_font_size_override("font_size", 22)
		value.custom_minimum_size.x = 150
		grid.add_child(value)
		_tower_stats[key] = value
	for key: String in ["special", "next", "record"]:
		var line: Label = Label.new()
		line.add_theme_font_size_override("font_size", 19)
		line.add_theme_color_override("font_color", Color("ffd36a") if key == "next" else Color(0.82, 0.88, 0.86))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size.x = 560
		card.add_child(line)
		_tower_stats[key] = line
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	card.add_child(actions)
	_upgrade = _button(actions, "Melhorar", _request_upgrade, 190)
	for branch: String in ["A", "B"]:
		var key: String = branch
		_branch_buttons[key] = _button(actions, "Ramo " + key, func() -> void: _request_branch(key), 210)
	_priority = _button(actions, "Alvo: Primeiro", _cycle_priority, 200)
	_cancel = _button(actions, "Cancelar obra", func() -> void: simulation.cancel_work(_selected_pad), 190)
	_sell = _button(actions, "Vender", func() -> void: simulation.sell(_selected_pad), 160)
	for button: Button in [_upgrade, _branch_buttons.A, _branch_buttons.B, _priority, _cancel, _sell]:
		button.add_theme_font_size_override("font_size", 22)
		button.custom_minimum_size.y = 84
	MenuKitV2.primary(_upgrade)
	_sell.add_theme_color_override("font_color", Color("ffb3a1"))
	# A press that lands while the card is still appearing belongs to the tap that opened it, not to a button.
	for button: Button in [_upgrade, _branch_buttons.A, _branch_buttons.B, _priority, _cancel, _sell]:
		button.gui_input.connect(func(event: InputEvent) -> void:
			if (event is InputEventMouseButton or event is InputEventScreenTouch) and Time.get_ticks_msec() - _card_opened_at < 300:
				button.accept_event()
		)
	# Result card.
	_result = PanelContainer.new()
	_result.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_result.offset_left = -510
	_result.offset_right = 510
	_result.offset_top = -330
	_result.offset_bottom = 330
	var result_style: StyleBoxFlat = MenuKitV2.box(Color(0.04, 0.11, 0.13, 0.96), MenuKitV2.GOLD, 28, 3, 32)
	result_style.border_width_top = 8
	result_style.content_margin_left = 44
	result_style.content_margin_right = 44
	result_style.shadow_color = Color(0, 0, 0, 0.5)
	result_style.shadow_size = 24
	_result.add_theme_stylebox_override("panel", result_style)
	root.add_child(_result)
	var result_column: VBoxContainer = VBoxContainer.new()
	result_column.add_theme_constant_override("separation", 20)
	_result.add_child(result_column)
	_result_title = MenuKitV2.label(result_column, "", 60, MenuKitV2.GOLD, true)
	_result_body = _label(result_column, "", 25)
	_result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	result_column.add_child(buttons)
	MenuKitV2.primary(_button(buttons, "Tentar novamente", _restart, 270))
	_button(buttons, "Voltar ao mapa", func() -> void: exit_requested.emit(), 270)
	_result.visible = false

func _hud_label(parent: Node, text: String, size: int, color: Color) -> Label:
	var label: Label = _label(parent, text, size, Color.WHITE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 7)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.06, 0.9))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _chip(parent: Node, icon_name: String, tint: Color) -> Label:
	var chip: PanelContainer = PanelContainer.new()
	chip.add_theme_stylebox_override("panel", MenuKitV2.box(Color(0.03, 0.08, 0.09, 0.8), Color(tint, 0.6), 36, 2, 10))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(chip)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	chip.add_child(row)
	var icon: TextureRect = TextureRect.new()
	icon.texture = MenuKitV2.icon(icon_name)
	icon.modulate = tint
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size = Vector2(40, 40)
	row.add_child(icon)
	var value: Label = MenuKitV2.label(row, "0", 34, Color("fff6dc"), true)
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	value.custom_minimum_size = Vector2(70, 0)
	return value

func _round(parent: Node, icon_name: String, tooltip: String, action: Callable) -> Button:
	var button: Button = MenuKitV2.icon_button(parent, icon_name, tooltip, 92)
	button.pressed.connect(func() -> void: _sound("ui", AudioServiceNode.BUS_UI); action.call())
	return button

## Tower card: portrait, price, reach and target layer. Press (or press and drag) to place it on the map.
func _card(parent: Node, type_id: String) -> Button:
	var definition: Dictionary = simulation.catalog.towers[type_id]
	var first: Dictionary = definition.levels[0]
	var card: Button = Button.new()
	card.name = "Card_" + type_id
	card.toggle_mode = true
	card.custom_minimum_size = Vector2(150, 176)
	card.icon = load("res://art/ui/tower_%s.jpg" % type_id) as Texture2D
	card.expand_icon = true
	card.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_theme_constant_override("icon_max_width", 96)
	card.add_theme_font_size_override("font_size", 19)
	card.text = "%d\n%.1f m · %s" % [int(first.cost), float(first.range), "Terra/ar" if str(definition.layer) == "both" else ("Ar" if str(definition.layer) == "air" else ("Suporte" if str(definition.layer) == "ally" else "Terra"))]
	card.tooltip_text = "%s · %s" % [str(definition.name), str(definition.description)]
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(card)
	MenuKitV2.feedback(card)
	card.button_down.connect(func() -> void:
		_sound("ui", AudioServiceNode.BUS_UI)
		if _selected_pad >= 0 and simulation.tower_on_pad(_selected_pad) == null: _purchase(type_id)
		else: _begin_placement(type_id)
	)
	return card

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
	_speed.text = "%d×" % int(Engine.time_scale)
	if _top_stats == null:
		return
	_top_stats.text = str(stage.name)
	_lives_label.text = str(simulation.lives)
	_coins_label.text = str(simulation.coins)
	_wave_label.text = "Onda %d / %d" % [simulation.wave_index, simulation.waves.size()]
	_pause.icon = MenuKitV2.icon("play" if simulation.paused else "pause")
	_pause.tooltip_text = "Continuar" if simulation.paused else "Pausar"
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
		button.disabled = simulation.paused or simulation._terminal() or simulation.coins < int(simulation.catalog.towers[key].levels[0].cost)
		button.set_pressed_no_signal(_placing == key)
	_actions.visible = tower != null and not simulation._terminal()
	if _actions.visible: _place_actions(tower)
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
		_fill_tower_card(tower, choosing_branch)
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
		# The tower card already shows these numbers; keep the bottom line free for hints.
		_context.text = ""
	elif _selected_pad >= 0:
		_context.text = "Espaço livre · Toque numa carta para construir aqui."
	elif not _placing.is_empty():
		_context.text = "%s · %d moedas" % [str(simulation.catalog.towers[_placing].name), int(simulation.catalog.towers[_placing].levels[0].cost)]
	else:
		_context.text = ""
	_update_tutorial_hint()

static func _number(value: float) -> String:
	var text: String = ("%.2f" % value).rstrip("0").rstrip(".")
	return text.replace(".", ",")

## Fills the selected tower's card: current numbers, what its attacks do and what the next level buys.
func _fill_tower_card(tower: SimTowerV2, choosing_branch: bool) -> void:
	var definition: Dictionary = simulation.catalog.towers[tower.type_id]
	var values: Dictionary = simulation.stats(tower)
	var title: String = "%s · Nível %d" % [str(definition.name), tower.level]
	if not tower.branch.is_empty(): title += " · " + str(definition.branches[tower.branch].name)
	if tower.state == SimTowerV2.State.BUILDING: title += " · em construção"
	elif tower.state == SimTowerV2.State.UPGRADING: title += " · melhorando para nível %d" % tower.pending_level
	_tower_title.text = title
	var support: bool = tower.type_id == "banner"
	var kind: String = str({"physical": "físico", "magical": "mágico", "pure": "puro"}.get(str(definition.damage_type), ""))
	(_tower_stats.damage as Label).text = "—" if support else "%s %s" % [_number(float(values.damage)), kind]
	(_tower_stats.rate as Label).text = "—" if support else "%s por s" % _number(float(values.rate))
	(_tower_stats.range as Label).text = "%s m" % _number(simulation.effective_range(tower))
	(_tower_stats.layer as Label).text = str({"both": "Terra e ar", "ground": "Só terra", "air": "Só ar", "ally": "Torres aliadas"}.get(str(definition.layer), ""))
	var notes: Array[String] = []
	var splash: float = float(values.get("splash", definition.get("splash", 0)))
	if splash > 0: notes.append("Área %s m" % _number(splash))
	for effect: Dictionary in values.get("effects", []):
		match str(effect.kind):
			"slow": notes.append("Lentidão %d%% por %ss" % [int(round(float(effect.power) * 100)), _number(float(effect.duration))])
			"venom": notes.append("Veneno %s por s durante %ss" % [_number(float(effect.power)), _number(float(effect.duration))])
			"bleed": notes.append("Sangramento %s por s durante %ss" % [_number(float(effect.power)), _number(float(effect.duration))])
	if values.has("field"): notes.append("Campo gelado de %s m" % _number(float(values.field.radius)))
	if values.has("chain_count"): notes.append("Salta para %d alvos" % int(values.chain_count))
	if values.has("pierce_count"): notes.append("Atravessa %d inimigos" % int(values.pierce_count))
	if values.has("spread_count"): notes.append("Veneno se espalha para %d" % int(values.spread_count))
	if values.has("crit_every"): notes.append("Crítico ×%s a cada %d tiros" % [_number(float(values.crit_multiplier)), int(values.crit_every)])
	if values.has("focus_step"): notes.append("Dano cresce no mesmo alvo até ×%s" % _number(float(values.focus_cap)))
	if support:
		var haste: float = float(values.get("haste", values.get("pulse_haste", 0)))
		if haste > 0: notes.append("Aliados atacam %d%% mais rápido" % int(round(haste * 100)))
		if float(values.get("reach_bonus", 0)) > 0: notes.append("Alcance aliado +%d%%" % int(round(float(values.reach_bonus) * 100)))
	(_tower_stats.special as Label).text = " · ".join(notes)
	(_tower_stats.special as Label).visible = not notes.is_empty()
	var next: Dictionary = simulation.next_upgrade(tower)
	var preview: String = ""
	if not next.is_empty() and not choosing_branch and tower.state == SimTowerV2.State.READY:
		var gains: Array[String] = []
		if float(next.get("damage", 0)) > float(values.damage): gains.append("dano %s → %s" % [_number(float(values.damage)), _number(float(next.damage))])
		if float(next.get("rate", 0)) > float(values.rate): gains.append("cadência %s → %s" % [_number(float(values.rate)), _number(float(next.rate))])
		if float(next.get("range", 0)) > float(values.range): gains.append("alcance %s → %s m" % [_number(float(values.range)), _number(float(next.range))])
		if float(next.get("haste", 0)) > float(values.get("haste", 0)): gains.append("bônus %d%% → %d%%" % [int(round(float(values.get("haste", 0)) * 100)), int(round(float(next.haste) * 100))])
		if not gains.is_empty(): preview = "Próximo nível: " + ", ".join(gains)
	elif choosing_branch:
		preview = "Escolha uma especialização abaixo."
	(_tower_stats.next as Label).text = preview
	(_tower_stats.next as Label).visible = not preview.is_empty()
	var record: String = "Dano causado %d · Eliminações %d" % [int(tower.damage_done), tower.kills]
	if support: record = "%d ataques aliados fortalecidos" % tower.supported_attacks
	if tower.control_delay > 0.0: record += " · Atraso causado %ss" % _number(tower.control_delay)
	(_tower_stats.record as Label).text = record

## Keeps the tower's card just above it on screen, clamped inside the viewport.
func _place_actions(tower: SimTowerV2) -> void:
	var screen: Vector2 = diorama.camera.unproject_position(tower.position + Vector3(0, 3.2, 0))
	var size: Vector2 = _actions.get_combined_minimum_size()
	var view: Vector2 = get_viewport().get_visible_rect().size
	_actions.size = size
	var top: float = screen.y - size.y - 10
	# No room above the tower: open the card below its base instead of sliding it over the tower.
	if top < 120: top = diorama.camera.unproject_position(tower.position).y + 40
	_actions.position = Vector2(clampf(screen.x - size.x / 2, 16, view.x - size.x - 16), clampf(top, 120, view.y - size.y - 250))

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
	for detail: Node in get_tree().get_nodes_in_group(BiomeDressingV2.DETAIL_GROUP):
		if is_ancestor_of(detail): (detail as Node3D).visible = profile != "economy"

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
			(_enemy_areas[enemy.id] as Node3D).position = simulation.display_position(enemy) + Vector3(0, 0.15, 0)
	for id: int in _enemy_areas.keys():
		if not required.has(id):
			_retire_area(_enemy_areas[id] as Node3D)
			_enemy_areas.erase(id)

func _update_tutorial_hint() -> void:
	if not tutorial_enabled or int(stage.index) != 1 or simulation.state != BattleSimV2.State.PREPARATION: return
	if simulation.towers.is_empty():
		_hint.text = "1/3 · Arraste uma torre da barra de baixo até um lugar livre perto da estrada." if _selected_pad < 0 and _placing.is_empty() else "2/3 · Solte a torre num ponto verde. Confira preço, alcance e tipos de alvo na carta."
	else:
		var ready: bool = false
		for tower: SimTowerV2 in simulation.towers.values():
			if tower.state == SimTowerV2.State.READY: ready = true
		_hint.text = "3/3 · Toque em Iniciar defesa. Depois, as ondas chegam automaticamente." if ready else "3/3 · Aguarde a barra da obra. A torre atacará quando estiver pronta; depois toque em Iniciar defesa."
func _show_help() -> void:
	_show_info("Como defender o caminho", "• Inimigos que chegam à bandeira retiram vidas. Guarde a saída.\n• Arraste uma carta até o mapa: verde pode construir, vermelho não (rua, água ou outra torre).\n• Construção e melhoria levam tempo; a torre fica sem atacar durante a obra.\n• A primeira onda é manual. As demais chegam sozinhas; chamar antes rende até 5 moedas.\n• Selecione torres para melhorar, especializar, vender ou mudar a ordem dos alvos.\n• Arqueira e Cristal atingem ar; Canhão e Alquimista atingem só o chão.\n• Armadura pede magia, sangramento e cobertura. Chefes avisam antes das habilidades.\n• Pausa congela a batalha. 2× e 4× aceleram o jogo; use o Guia no mapa para conhecer cada função.")

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
