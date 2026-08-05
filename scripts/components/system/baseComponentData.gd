class_name BaseComponentData
extends Resource

## Emitted when this data reaches its end state
signal component_completed

## A unique identifier used by the Manager's Dictionary to map to a PackedScene.
@export var component_id: StringName = &"base"

## Flag to track if the component has met its win/end state.
@export var is_finished: bool = false

## Mark the component as finished and notify listeners.
func complete() -> void:
	if not is_finished:
		is_finished = true
		component_completed.emit()
