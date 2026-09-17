## Abstract base for view Nodes representing a SystemData-scoped component.
## Extend this (not BaseComponent) for anything spawned from
## SystemData.components.
@abstract
class_name SystemComponent
extends BaseComponent

func initialize(data: BaseComponentData) -> void:
	initialize_system_component(data as SystemComponentData)

## Strictly-typed entry point - implement this instead of initialize().
@abstract func initialize_system_component(data: SystemComponentData) -> void
