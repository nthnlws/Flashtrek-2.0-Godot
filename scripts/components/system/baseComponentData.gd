@abstract
class_name BaseComponentData
extends Resource


## Emitted when this component achieves its objective. The owning
## ComponentManager listens for this (connected once, when the component is
## spawned) to despawn the associated view Node and remove this data
## Resource from its persistent owner (SystemData.components or
## PlanetData.components).
signal component_completed

## A unique identifier used by the Manager's Dictionary to map to a PackedScene.
@export var component_id: StringName = &"base"

## Flag to track if the component has met its win/end state (or was otherwise finalized).
@export var is_finished: bool = false

## Marks the component as finished and notifies the owning ComponentManager.
## Safe to call multiple times - only the first call has any effect.
func mark_completed() -> void:
	if is_finished:
		return
	is_finished = true
	component_completed.emit()
