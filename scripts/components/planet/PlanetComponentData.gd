## Base class for data Resources owned by a specific PlanetData. Multiple
## planets can be active in the current system simultaneously (and each can
## carry more than one component of the same type), so each instance carries
## a reference back to the planet it belongs to - set by
## PlanetData.add_component() or by whichever factory creates it (e.g.
## SystemData.generate_planet_data() for the default communication component).
@abstract
class_name PlanetComponentData
extends BaseComponentData

@export var owning_planet: PlanetData
