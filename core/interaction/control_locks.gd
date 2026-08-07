class_name ControlLocks
extends RefCounted

signal changed(locked: bool)

var _reasons: Dictionary = {}

func lock(reason: StringName) -> void:
	if reason.is_empty():
		return
	_reasons[reason] = true
	changed.emit(is_locked())

func unlock(reason: StringName) -> void:
	_reasons.erase(reason)
	changed.emit(is_locked())

func clear() -> void:
	_reasons.clear()
	changed.emit(false)

func is_locked() -> bool:
	return not _reasons.is_empty()

func has(reason: StringName) -> bool:
	return _reasons.has(reason)
