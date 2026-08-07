class_name ItemActionResult
extends RefCounted

var success := false
var consume_count := 0
var next_state: Dictionary = {}
var message := ""
var world_node: Node2D
var prepared_node: Node2D

static func failed(feedback := "") -> ItemActionResult:
	var result := ItemActionResult.new()
	result.message = feedback
	return result

static func completed(consumed := 0, state: Dictionary = {}) -> ItemActionResult:
	var result := ItemActionResult.new()
	result.success = true
	result.consume_count = consumed
	result.next_state = state.duplicate(true)
	return result
