@abstract
extends Node2D
class_name BaseComponent

## Concrete components should not extend BaseComponent directly - extend
## SystemComponent or PlanetComponent instead, which cast `data` to their
## scoped data type and forward it to a strictly-typed hook.
@abstract func initialize(data: BaseComponentData) -> void

## Call when this component's objective is achieved. Marks the backing data
## Resource finished, which emits BaseComponentData.component_completed -
## the signal the owning ComponentManager listens for to despawn this Node
## and remove the data from its persistent owner.
func complete(data: BaseComponentData) -> void:
	data.mark_completed()
