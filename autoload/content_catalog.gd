extends Node

var items: Dictionary = {}
var enemies: Dictionary = {}
var effects: Dictionary = {}
var shops: Dictionary = {}
var dialogues: Dictionary = {}

func _ready() -> void:
	rebuild()

func rebuild() -> PackedStringArray:
	items.clear()
	enemies.clear()
	effects.clear()
	shops.clear()
	dialogues.clear()
	var errors := PackedStringArray()
	_scan_directory("res://data/items", errors)
	_scan_directory("res://data/enemies", errors)
	_scan_directory("res://data/effects", errors)
	_scan_directory("res://data/shops", errors)
	_scan_directory("res://data/dialogue", errors)
	for error in errors:
		push_error(error)
	return errors

func _scan_directory(path: String, errors: PackedStringArray) -> void:
	var entries := ResourceLoader.list_directory(path)
	entries.sort()
	for entry in entries:
		var resource_path := path.path_join(entry.trim_suffix("/"))
		if entry.ends_with("/"):
			_scan_directory(resource_path, errors)
		elif entry.ends_with(".tres"):
			_register_resource(load(resource_path), resource_path, errors)

func _register_resource(resource: Resource, path: String, errors: PackedStringArray) -> void:
	if resource is ItemDefinition:
		_register(items, resource.item_id, resource, path, errors)
		for validation_error in resource.validate():
			errors.append("%s: %s" % [path, validation_error])
	elif resource is EnemyDefinition:
		_register(enemies, resource.enemy_id, resource, path, errors)
	elif resource is EffectDefinition:
		_register(effects, resource.effect_id, resource, path, errors)
	elif resource is ShopDefinition:
		_register(shops, resource.shop_id, resource, path, errors)
	elif resource is DialogueSequence:
		_register(dialogues, resource.sequence_id, resource, path, errors)
	else:
		errors.append("%s: unsupported content resource" % path)

func _register(catalog: Dictionary, id: StringName, resource: Resource, path: String, errors: PackedStringArray) -> void:
	if id.is_empty():
		errors.append("%s: blank stable ID" % path)
	elif catalog.has(id):
		errors.append("%s: duplicate stable ID '%s'" % [path, id])
	else:
		catalog[id] = resource

func get_item(item_id: StringName) -> ItemDefinition:
	return items.get(item_id) as ItemDefinition

func get_enemy(enemy_id: StringName) -> EnemyDefinition:
	return enemies.get(enemy_id) as EnemyDefinition

func get_effect(effect_id: StringName) -> EffectDefinition:
	return effects.get(effect_id) as EffectDefinition

func get_shop(shop_id: StringName) -> ShopDefinition:
	return shops.get(shop_id) as ShopDefinition

func get_dialogue(sequence_id: StringName) -> DialogueSequence:
	return dialogues.get(sequence_id) as DialogueSequence
