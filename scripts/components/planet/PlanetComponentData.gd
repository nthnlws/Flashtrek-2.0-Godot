## Base class for data Resources owned by a specific PlanetData. Multiple
## planets can be active in the current system simultaneously (and each can
## carry more than one component of the same type), so each instance carries
## a reference back to the planet it belongs to - set by
## PlanetData.add_component() or by whichever factory creates it (e.g.
## SystemGenerator.generate_planet_data() for the default communication component).
@abstract
class_name PlanetComponentData
extends BaseComponentData

@export var owning_planet: PlanetData

## Every concrete planet-scoped component implements this instead of a
## bespoke setup_data() signature, so PlanetData.add_component() can
## construct and configure any registered component type through one
## uniform interface. `mission` may be null / unused for component types
## that don't read anything from a mission (e.g. CommunicationComponentData).
@abstract func setup_from_mission(mission: MissionData, context: PlanetData) -> void
