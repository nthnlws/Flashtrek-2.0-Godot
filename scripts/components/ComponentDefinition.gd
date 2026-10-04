## Registers a component type. Save as a .tres in
## ComponentRegistry.DEFINITIONS_DIR to make it available.
class_name ComponentDefinition
extends Resource

enum Scope { SYSTEM, PLANET }

## Must match the data script's component_id.
@export var component_id: StringName
@export var display_name: String
@export var data_script: Script
@export var scene: PackedScene
@export var scope: Scope = Scope.SYSTEM
## MissionData.MISSION_TYPE that spawns this component, or -1.
@export var mission_type: int = -1
## Listed in the F9 debug panel.
@export var debug_addable: bool = true


func create_data() -> BaseComponentData:
	return data_script.new() as BaseComponentData
