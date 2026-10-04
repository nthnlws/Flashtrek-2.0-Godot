## Lazily loads every ComponentDefinition in DEFINITIONS_DIR.
class_name ComponentRegistry
extends RefCounted

const DEFINITIONS_DIR: String = "res://assets/data/components/"

static var _by_id: Dictionary[StringName, ComponentDefinition] = {}


static func _ensure_loaded() -> void:
	if not _by_id.is_empty():
		return

	# list_directory() resolves export remaps, unlike DirAccess.
	for file_name: String in ResourceLoader.list_directory(DEFINITIONS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var definition: ComponentDefinition = load(DEFINITIONS_DIR + file_name) as ComponentDefinition
		if definition == null:
			printerr("ComponentRegistry: %s is not a ComponentDefinition" % file_name)
			continue
		if _by_id.has(definition.component_id):
			printerr("ComponentRegistry: duplicate component_id '%s' in %s" % [definition.component_id, file_name])
			continue
		_by_id[definition.component_id] = definition


static func get_definition(component_id: StringName) -> ComponentDefinition:
	_ensure_loaded()
	return _by_id.get(component_id)


static func get_all() -> Array[ComponentDefinition]:
	_ensure_loaded()
	var result: Array[ComponentDefinition] = []
	result.assign(_by_id.values())
	result.sort_custom(func(a: ComponentDefinition, b: ComponentDefinition) -> bool: return a.display_name < b.display_name)
	return result


## Null for mission types without a component (e.g. deliveries).
static func get_for_mission_type(mission_type: int) -> ComponentDefinition:
	_ensure_loaded()
	for definition: ComponentDefinition in _by_id.values():
		if definition.mission_type == mission_type:
			return definition
	return null


static func get_scene(component_id: StringName) -> PackedScene:
	var definition: ComponentDefinition = get_definition(component_id)
	return definition.scene if definition else null
