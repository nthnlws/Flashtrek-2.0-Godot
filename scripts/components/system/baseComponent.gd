@abstract
extends Node2D
class_name BaseComponent

## Concrete components should not extend BaseComponent directly - extend
## SystemComponent or PlanetComponent instead, which cast `data` to their
## scoped data type and forward it to a strictly-typed hook.
@abstract func initialize(data: BaseComponentData) -> void

## Resolves the component. ComponentManager despawns this node and
## MissionManager settles the owning mission - don't call MissionManager directly.
func complete(data: BaseComponentData) -> void:
	data.mark_completed(true)


func fail(data: BaseComponentData, reason: String = "") -> void:
	data.mark_failed(reason)
