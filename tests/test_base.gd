## TestBase
## Lightweight test base class for headless test execution.
## Each test script extends this and implements run_tests().
class_name TestBase
extends RefCounted

var _test_name: String = "UnnamedTest"
var _passed: int = 0
var _failed: int = 0
var _errors: PackedStringArray = []


func _init(test_name: String = "") -> void:
	if not test_name.is_empty():
		_test_name = test_name


## Override this in subclasses to define tests.
func run_tests() -> void:
	push_warning("TestBase.run_tests() not overridden in %s" % _test_name)


## Returns the test name.
func get_test_name() -> String:
	return _test_name


## Returns number of passed assertions.
func get_passed() -> int:
	return _passed


## Returns number of failed assertions.
func get_failed() -> int:
	return _failed


## Returns array of error messages from failed assertions.
func get_errors() -> PackedStringArray:
	return _errors


## Assert that two values are equal.
func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		var msg: String = message if not message.is_empty() else (
			"Expected '%s' but got '%s'" % [str(expected), str(actual)]
		)
		_errors.append("[%s] FAIL: %s" % [_test_name, msg])


## Assert that two values are not equal.
func assert_neq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		_passed += 1
	else:
		_failed += 1
		var msg: String = message if not message.is_empty() else (
			"Expected not '%s' but got '%s'" % [str(expected), str(actual)]
		)
		_errors.append("[%s] FAIL: %s" % [_test_name, msg])


## Assert that a condition is true.
func assert_true(condition: bool, message: String = "") -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		var msg: String = message if not message.is_empty() else "Expected true but got false"
		_errors.append("[%s] FAIL: %s" % [_test_name, msg])


## Assert that a condition is false.
func assert_false(condition: bool, message: String = "") -> void:
	if not condition:
		_passed += 1
	else:
		_failed += 1
		var msg: String = message if not message.is_empty() else "Expected false but got true"
		_errors.append("[%s] FAIL: %s" % [_test_name, msg])


## Assert that actual is greater than expected.
func assert_gt(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual > expected:
		_passed += 1
	else:
		_failed += 1
		var msg: String = message if not message.is_empty() else (
			"Expected '%s' > '%s'" % [str(actual), str(expected)]
		)
		_errors.append("[%s] FAIL: %s" % [_test_name, msg])


## Assert that actual is greater than or equal to expected.
func assert_gte(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual >= expected:
		_passed += 1
	else:
		_failed += 1
		var msg: String = message if not message.is_empty() else (
			"Expected '%s' >= '%s'" % [str(actual), str(expected)]
		)
		_errors.append("[%s] FAIL: %s" % [_test_name, msg])


## Assert that an array/string is empty.
func assert_empty(value: Variant, message: String = "") -> void:
	var is_empty_val: bool = false
	if value is String or value is StringName:
		is_empty_val = (value as String).is_empty()
	elif value is Array or value is PackedStringArray:
		is_empty_val = value.is_empty()
	elif value is Dictionary:
		is_empty_val = value.is_empty()
	else:
		is_empty_val = (value == null)

	if is_empty_val:
		_passed += 1
	else:
		_failed += 1
		var msg: String = message if not message.is_empty() else (
			"Expected empty but got '%s'" % str(value)
		)
		_errors.append("[%s] FAIL: %s" % [_test_name, msg])


## Assert that an array/string is not empty.
func assert_not_empty(value: Variant, message: String = "") -> void:
	var is_empty_val: bool = true
	if value is String or value is StringName:
		is_empty_val = (value as String).is_empty()
	elif value is Array or value is PackedStringArray:
		is_empty_val = value.is_empty()
	elif value is Dictionary:
		is_empty_val = value.is_empty()
	else:
		is_empty_val = (value == null)

	if not is_empty_val:
		_passed += 1
	else:
		_failed += 1
		var msg: String = message if not message.is_empty() else "Expected non-empty value"
		_errors.append("[%s] FAIL: %s" % [_test_name, msg])
