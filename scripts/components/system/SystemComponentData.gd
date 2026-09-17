## Base class for data Resources owned directly by a SystemData. Only one
## SystemData is ever active at a time, so - unlike PlanetComponentData -
## no back-reference to the owning SystemData is needed; the ComponentManager
## tracks the single active SystemData itself.
@abstract
class_name SystemComponentData
extends BaseComponentData
