## Base class for data Resources owned directly by a SystemData. Only one
## SystemData is ever active at a time, so - unlike PlanetComponentData -
## no back-reference to the owning SystemData is needed; the ComponentManager
## tracks the single active SystemData itself.
@abstract
class_name SystemComponentData
extends BaseComponentData

## Every concrete system-scoped component implements this so SystemData.add_component() can
## construct and configure any registered component type through one
## uniform interface. `mission` may be null / unused for component types
## that don't read anything from a mission (e.g. ScrapComponentData).
@abstract func setup_from_mission(mission: MissionData, context: SystemData) -> void
