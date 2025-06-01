# FleetCollision_resource
extends Resource
class_name FleetData

@export var ships: Array[ShipData]

func get_ship(name: String) -> ShipData:
	for ship in ships:
		if ship.ship_name == name:
			return ship
	return null
