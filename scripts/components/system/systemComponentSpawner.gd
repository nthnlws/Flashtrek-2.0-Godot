extends Node


var attached_components: Array[SystemComponent] = []


func cleanup_system_components() -> void:
	if !attached_components.is_empty():
		for component: SystemComponent in attached_components:
			if component.has_method("cleanup_component"):
				component.cleanup_component()
		clear_components()


func clear_components() -> void:
	for component: SystemComponent in attached_components:
		component.queue_free()
	attached_components.clear()


func sync_components(system_data: SystemData) -> void:
	if !system_data.active_components.is_empty():
		#print("Syncing system components for system: %s" % system_data.system_name)
		#print("Active components: %s" % str(system_data.active_components))
		for component: SystemData.SystemComponentTypes in system_data.active_components:
			var new_component: SystemComponent = system_data.component_map.get(component).instantiate()
			add_child(new_component)
			new_component.initialize_component(system_data)
	#else: print("No active components for system: %s" % system_data.system_name)