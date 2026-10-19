## Test runner — discovers and executes all test_*.gd scripts in res://tests/.
## Usage: godot --headless --path . -s res://tests/run_all.gd
extends SceneTree


func _init() -> void:
	print("")
	print("==============================================")
	print(" Iron Path — Test Runner")
	print("==============================================")
	print("")

	var test_scripts: PackedStringArray = _discover_tests()
	var total_passed: int = 0
	var total_failed: int = 0
	var all_errors: PackedStringArray = []

	for script_path in test_scripts:
		var result: Dictionary = _run_test_script(script_path)
		total_passed += result.passed
		total_failed += result.failed
		all_errors.append_array(result.errors)

	print("")
	print("==============================================")
	print(" Results: %d passed, %d failed" % [total_passed, total_failed])
	print("==============================================")

	if not all_errors.is_empty():
		print("")
		print("Failures:")
		for err in all_errors:
			print("  ✗ %s" % err)

	print("")

	if total_failed > 0:
		quit(1)
	else:
		quit(0)


## Discovers test scripts in the tests directory.
func _discover_tests() -> PackedStringArray:
	var tests: PackedStringArray = []
	var dir := DirAccess.open("res://tests/")
	if dir == null:
		push_error("Cannot open res://tests/ directory")
		return tests

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if (
			file_name.begins_with("test_")
			and file_name.ends_with(".gd")
			and file_name != "test_base.gd"
		):
			tests.append("res://tests/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	tests.sort()
	print("Discovered %d test script(s):" % tests.size())
	for t in tests:
		print("  • %s" % t)
	print("")

	return tests


## Runs a single test script and returns results.
func _run_test_script(script_path: String) -> Dictionary:
	var result: Dictionary = {"passed": 0, "failed": 0, "errors": PackedStringArray()}

	var script: GDScript = load(script_path) as GDScript
	if script == null:
		print("  ✗ SKIP: Cannot load %s" % script_path)
		result.failed += 1
		result.errors.append("Cannot load %s" % script_path)
		return result

	var instance: Variant = script.new()
	if instance == null or not (instance is TestBase):
		print("  ✗ SKIP: %s does not extend TestBase" % script_path)
		result.failed += 1
		result.errors.append("%s does not extend TestBase" % script_path)
		return result

	var test: TestBase = instance as TestBase
	print("Running: %s (%s)" % [test.get_test_name(), script_path])

	test.run_tests()

	result.passed = test.get_passed()
	result.failed = test.get_failed()
	result.errors = test.get_errors()

	var status: String = "✓ PASS" if test.get_failed() == 0 else "✗ FAIL"
	print("  %s — %d passed, %d failed" % [status, test.get_passed(), test.get_failed()])

	return result
