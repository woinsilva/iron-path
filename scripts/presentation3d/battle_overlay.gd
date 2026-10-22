class_name BattleOverlayV2 extends Node2D

var battle: Node3D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(battle) or battle.simulation == null:
		return
	var camera: Camera3D = battle.diorama.camera
	for id: int in battle.enemy_views:
		var actor: RiggedActor3D = battle.enemy_views[id]
		if actor.dead or not actor.visible:
			continue
		var target: SimEnemyV2 = battle.simulation.enemies.get(id) as SimEnemyV2
		if target != null and target.underground(): continue
		var point: Vector2 = camera.unproject_position(actor.health_anchor.get_global_transform_interpolated().origin)
		draw_rect(Rect2(point - Vector2(31, 4), Vector2(62, 9)), Color("14221e"))
		draw_rect(Rect2(point - Vector2(29, 2), Vector2(58 * clampf(actor.health_ratio, 0.0, 1.0), 5)), Color("96c765"))
		if target != null:
			if target.maximum_shield > 0:
				draw_rect(Rect2(point - Vector2(29, 10), Vector2(58, 3)), Color("40576a"))
				draw_rect(Rect2(point - Vector2(29, 10), Vector2(58 * target.shield / target.maximum_shield, 3)), Color("77c7e3"))
				draw_polyline(PackedVector2Array([point + Vector2(-36, -12), point + Vector2(-32, -12), point + Vector2(-32, -8), point + Vector2(-34, -5), point + Vector2(-36, -8), point + Vector2(-36, -12)]), Color("c0e8ed"), 1.5, true)
			var icons: Array[String] = []
			for effect: Dictionary in target.statuses:
				if str(effect.kind) not in icons: icons.append(str(effect.kind))
			for index in range(icons.size()):
				var spot: Vector2 = point + Vector2(-23 + index * 14, -13)
				var kind: String = icons[index]
				var color: Color = Color("76cfed") if kind == "slow" else (Color("cb7566") if kind == "bleed" else (Color("d6b365") if kind == "corrosion" else Color("92c968")))
				draw_circle(spot, 6, Color("14221e"))
				if kind == "slow":
					for angle: float in [0, PI / 3, PI * 2 / 3]:
						var direction: Vector2 = Vector2(cos(angle), sin(angle)) * 4
						draw_line(spot - direction, spot + direction, color, 1.5, true)
				elif kind == "corrosion":
					draw_rect(Rect2(spot - Vector2(3, 3), Vector2(6, 6)), color, false, 1.5)
				else:
					var points: PackedVector2Array = PackedVector2Array([spot + Vector2(0, -4), spot + Vector2(4, 2), spot + Vector2(0, 5), spot + Vector2(-4, 2)]) if kind == "bleed" else PackedVector2Array([spot + Vector2(0, -4), spot + Vector2(4, 4), spot + Vector2(-4, 4)])
					draw_colored_polygon(points, color)
	for tower: SimTowerV2 in battle.simulation.towers.values():
		if tower.state == SimTowerV2.State.READY:
			continue
		var point: Vector2 = camera.unproject_position(tower.position + Vector3(0, 1.2, 0))
		var ratio: float = float(tower.work_elapsed) / maxi(1, tower.work_ticks)
		draw_rect(Rect2(point - Vector2(42, 4), Vector2(84, 12)), Color("14221e"))
		draw_rect(Rect2(point - Vector2(40, 2), Vector2(80 * ratio, 8)), Color("e7b957"))

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(battle) and event.is_action_pressed("ui_cancel") and not event.is_echo():
		battle.handle_back_request()
		get_viewport().set_input_as_handled()
