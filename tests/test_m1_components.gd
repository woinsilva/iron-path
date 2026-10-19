class_name TestM1Components extends TestBase

func run_tests() -> void:
	test_health_component()
	test_build_manager()

func test_health_component() -> void:
	var health = preload("res://scripts/components/health_component.gd").new()
	health.max_health = 100.0
	health.armor = 10.0
	health._ready()
	
	# Test physical damage (full armor)
	health.take_damage(20.0, 0)
	assert_eq(health.current_health, 90.0, "Physical damage should subtract full armor")
	
	# Test magical damage (half armor = 5)
	health.take_damage(20.0, 1)
	assert_eq(health.current_health, 75.0, "Magical damage should subtract half armor")
	
	# Test pure damage (ignores armor)
	health.take_damage(20.0, 2)
	assert_eq(health.current_health, 55.0, "Pure damage should ignore armor")
	
	health.free()

func test_build_manager() -> void:
	var pad = preload("res://scripts/battle/build_pad.gd").new()
	var build_mgr = preload("res://scripts/battle/build_manager.gd").new()
	
	# Test not enough coins
	assert_false(build_mgr.can_build(pad, 100, 50), "Should not allow build with insufficient coins")
	
	# Test enough coins
	assert_true(build_mgr.can_build(pad, 50, 50), "Should allow build with exact coins")
	assert_true(build_mgr.can_build(pad, 50, 100), "Should allow build with sufficient coins")
	
	pad.is_occupied = true
	assert_false(build_mgr.can_build(pad, 50, 100), "Should not allow build on occupied pad")
	
	pad.free()
	build_mgr.free()
