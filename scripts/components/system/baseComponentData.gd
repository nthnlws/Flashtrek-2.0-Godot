@abstract
class_name BaseComponentData
extends Resource


## Handled by ComponentManager: despawns the view, removes this data from its
## owner and emits SignalBus.component_resolved.
signal component_completed(success: bool)

## Key into ComponentRegistry.
@export var component_id: StringName = &"base"

## Flag to track if the component has met its win/end state (or was otherwise finalized).
@export var is_finished: bool = false

@export var succeeded: bool = false

@export var failure_reason: String = ""

## Owning MissionData.mission_id. Empty for ambient and debug components.
@export var mission_id: String = ""


## Only the first call has any effect.
func mark_completed(success: bool = true) -> void:
	if is_finished:
		return
	is_finished = true
	succeeded = success
	component_completed.emit(success)


func mark_failed(reason: String = "") -> void:
	if is_finished:
		return
	failure_reason = reason
	mark_completed(false)
