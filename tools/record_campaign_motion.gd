extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var battle: BattleViewV2 = BattleViewV2.new()
	battle.stage_path = "res://data/campaign/stage_12.json"
	battle.stage = StageSessionV2.read_stage(battle.stage_path)
	battle.stage.allowed_towers = ["cannon","bleed","frost","banner","anti_air"]
	root.add_child(battle)
	current_scene = battle
	while battle._warming_up: await process_frame
	var grunt: SimEnemyV2 = battle.simulation.spawn_enemy("grunt",0,12)
	battle.simulation.spawn_enemy("armored",0,16)
	battle.simulation.spawn_enemy("resistant",0,20)
	battle.simulation.spawn_enemy("swarm",0,24)
	battle.simulation.spawn_enemy("brute",0,28)
	battle.simulation.spawn_enemy("boss_ruin",0,35)
	battle.simulation.spawn_enemy("flyer",1,10)
	battle.simulation.spawn_enemy("burrower",2,2)
	battle._hint.text = "Revisão visual por fixture · caminhada e curvas em 1×; não é uma partida de campanha."
	for frame in range(900):
		if frame == 240:
			for enemy: SimEnemyV2 in battle.simulation.enemies.values():
				if enemy.layer == "ground": battle.simulation.apply_status(enemy.id,"slow",.5,3,-1)
			battle._hint.text = "Revisão visual · lentidão: passada acompanha a velocidade sem mudar a rota."
		if frame == 480:
			Engine.time_scale = 2
			battle._hint.text = "Revisão visual · velocidade 2×: movimento e animação avançam juntos."
		if frame == 720:
			Engine.time_scale = 1
			battle._toggle_pause()
		if frame == 780:
			battle._toggle_pause()
			battle._hint.text = "Revisão visual · pausa encerrada; retorno sem salto de posição."
		if frame == 840: battle.simulation.damage(grunt.id,1000,"pure")
		await process_frame
	Engine.time_scale = 1
	paused = false
	battle.queue_free()
	await process_frame
	quit()
