## Abstract base for view Nodes representing a PlanetData-scoped component.
## Extend this (not BaseComponent) for anything spawned from
## PlanetData.components.
@abstract
class_name PlanetComponent
extends BaseComponent

## The planet this component belongs to. Set automatically from the data's
## `owning_planet` before initialize_planet_component() runs.
var owning_planet_data: PlanetData

func initialize(data: BaseComponentData) -> void:
	var planet_data: PlanetComponentData = data as PlanetComponentData
	owning_planet_data = planet_data.owning_planet
	initialize_planet_component(planet_data)

## Strictly-typed entry point - implement this instead of initialize().
@abstract func initialize_planet_component(data: PlanetComponentData) -> void
