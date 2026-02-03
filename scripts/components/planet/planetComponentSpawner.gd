extends Node2D


var attached_components: Array[PlanetComponent] = []


func sync_components(planet_data: PlanetData) -> void:
	if !planet_data.active_components.is_empty():
		for component:PlanetData.PlanetComponentTypes in planet_data.active_components:
			var new_component: PlanetComponent = planet_data.component_map.get(component).instantiate()
			add_child(new_component)
			new_component.initialize_component(planet_data)
			attached_components.append(new_component)