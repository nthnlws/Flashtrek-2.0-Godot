extends Panel
class_name ComponentDebugPanel

const COMPONENT_ROW = preload("uid://csirae4a2j33d")
@onready var margin_container: MarginContainer = $MarginContainer
@onready var content_container: VBoxContainer = $MarginContainer/Content
@onready var v_box_container: VBoxContainer = $MarginContainer/Content/VBoxContainer
@onready var add_type_dropdown: OptionButton = $MarginContainer/Content/AddRow/ComponentTypeDropdown

## Parallel to add_type_dropdown's items - rebuilt every sync_components()
## call since the set of planets (and therefore addable planet-scoped
## options) can change between systems.
var _add_options: Array[Dictionary] = []


func _ready() -> void:
	SignalBus.system_changed.connect(sync_components)
	# A component can finish (or be added) mid-system without any
	# system_changed event firing, so the row list needs telling directly too.
	SignalBus.component_removed.connect(_on_components_changed)
	SignalBus.component_injected.connect(_on_components_changed)
	sync_components(LevelManager.current_system_data)


func _on_components_changed(_data: BaseComponentData) -> void:
	sync_components(LevelManager.current_system_data)

# Debug test for animation
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("F9"):
			self.visible = !self.visible


func sync_components(system_data: SystemData) -> void:
	if !system_data: return
	# 1. Clear existing debug rows
	var old_children: Array[Node] = get_tree().get_nodes_in_group("component_debug_row")
	for old_row: Node in old_children:
		old_row.queue_free()

	# 2. System Components
	for data: BaseComponentData in system_data.components:
		var scene_name: String = String(data.component_id).capitalize()
		_add_row(scene_name, ComponentLabelRow.Icon.Node, data)

	# 3. Planet Components
	for planet: PlanetData in system_data.planet_data:
		for data: BaseComponentData in planet.components:
			var component_name: String = String(data.component_id).capitalize()
			var display_text: String = "%s: %s" % [planet.name, component_name]
			_add_row(display_text, ComponentLabelRow.Icon.Node2D, data)

	_rebuild_add_options(system_data)
	update_panel_dimensions()


func _add_row(label_text: String, icon: ComponentLabelRow.Icon, data: BaseComponentData) -> void:
	var new_line: ComponentLabelRow = COMPONENT_ROW.instantiate() as ComponentLabelRow
	new_line.set_component(label_text, icon)
	new_line.remove_requested.connect(_on_remove_component_pressed.bind(data))
	v_box_container.add_child(new_line)


## Resolves as a failure; rows refresh via SignalBus.component_removed.
## Fails the active mission if the component belongs to it.
func _on_remove_component_pressed(data: BaseComponentData) -> void:
	data.mark_failed("Removed via debug panel")


## One option per debug-addable system definition, and per planet for each
## debug-addable planet definition.
func _rebuild_add_options(system_data: SystemData) -> void:
	_add_options.clear()
	add_type_dropdown.clear()

	for definition: ComponentDefinition in ComponentRegistry.get_all():
		if not definition.debug_addable:
			continue

		if definition.scope == ComponentDefinition.Scope.SYSTEM:
			_add_option("%s (System)" % definition.display_name, definition)
		else:
			for planet: PlanetData in system_data.planet_data:
				_add_option("%s (%s)" % [definition.display_name, planet.name], definition, planet)


func _add_option(label: String, definition: ComponentDefinition, planet: PlanetData = null) -> void:
	var option: Dictionary = {"label": label, "definition": definition}
	if planet:
		option["planet"] = planet
	_add_options.append(option)
	add_type_dropdown.add_item(label)


## Adds the component type currently selected in the dropdown to the active
## system (or, for planet-scoped types, the chosen planet), then spawns it
## immediately via the ComponentManager - the same inject_component() path a
## real mission acceptance uses. Since this isn't a real mission, nothing is
## tracked in MissionManager; but anything setup_from_mission() reads off a
## MissionData (faction, cargo, enemy count, etc.) is still populated safely
## via MissionGenerator.generate_mission() rather than left null/default, so
## debug-added components behave identically to mission-added ones.
func _on_add_component_pressed() -> void:
	if _add_options.is_empty():
		return

	var index: int = add_type_dropdown.selected
	if index < 0 or index >= _add_options.size():
		return

	var option: Dictionary = _add_options[index]
	var current_system: SystemData = LevelManager.current_system_data
	if not current_system:
		return

	var definition: ComponentDefinition = option.definition
	var mission: MissionData = null
	if definition.mission_type >= 0:
		mission = MissionGenerator.generate_mission(current_system, LevelManager.galaxy_data, false, definition.mission_type as MissionData.MISSION_TYPE)
		mission.target_system = current_system
		if option.has("planet"):
			mission.target_planet_name = (option.planet as PlanetData).name

	var new_data: BaseComponentData
	if option.has("planet"):
		var planet_data: PlanetData = option.planet
		new_data = planet_data.add_component(definition.component_id, mission)
	else:
		new_data = current_system.add_component(definition.component_id, mission)

	if new_data and LevelManager.rootLevel and LevelManager.rootLevel.component_manager:
		LevelManager.rootLevel.component_manager.inject_component(new_data)

	sync_components(current_system)


func update_panel_dimensions() -> void:
	# Let Godot finish laying out the rows that were just added/removed
	# before asking for the container's real minimum size - reading it in
	# the same frame the rows changed can under-report their height, since
	# Container nodes resolve their combined minimum size on a deferred sort.
	await get_tree().process_frame

	var margin_horizontal: float = margin_container.get_theme_constant("margin_left") + margin_container.get_theme_constant("margin_right")
	var margin_vertical: float = margin_container.get_theme_constant("margin_top") + margin_container.get_theme_constant("margin_bottom")

	# Ask Content (the VBoxContainer holding the Add row + the component row
	# list) for its actual required size instead of guessing at row heights -
	# this stays correct regardless of theme, font, or row-count changes.
	custom_minimum_size = content_container.get_combined_minimum_size() + Vector2(margin_horizontal, margin_vertical)

	# This Panel is manually positioned (not inside a Container), so setting
	# custom_minimum_size alone doesn't resize it - reset_size() forces it to
	# grow/shrink to that minimum immediately. Without this the MarginContainer
	# (anchored to fill the Panel) keeps overflowing past the Panel's bounds.
	reset_size()
