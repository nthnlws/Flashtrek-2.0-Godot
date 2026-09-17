extends Panel
class_name ComponentDebugPanel

const COMPONENT_ROW = preload("uid://csirae4a2j33d")
@onready var margin_container: MarginContainer = $MarginContainer
@onready var content_container: VBoxContainer = $MarginContainer/Content
@onready var v_box_container: VBoxContainer = $MarginContainer/Content/VBoxContainer
@onready var add_type_dropdown: OptionButton = $MarginContainer/Content/AddRow/ComponentTypeDropdown

## Addable component types that live directly on the system (not a specific
## planet). "mission_type" is the MissionData.MISSION_TYPE used to safely
## generate a throwaway mission for setup_data() to read from (faction,
## cargo, enemy count, etc.) - null when the component's setup_data() doesn't
## read anything from a mission at all (e.g. Scrap).
const SYSTEM_ADD_OPTIONS: Array[Dictionary] = [
	{"label": "Kill Faction (System)", "component_type": Utility.SystemComponentType.KILL_FACTION, "mission_type": MissionData.MISSION_TYPE.KILL_FACTION},
	{"label": "Escort / Protect (System)", "component_type": Utility.SystemComponentType.ESCORT, "mission_type": MissionData.MISSION_TYPE.ESCORT},
	{"label": "Container (System)", "component_type": Utility.SystemComponentType.CONTAINER, "mission_type": MissionData.MISSION_TYPE.CONTAINER},
	{"label": "Scrap Field (System)", "component_type": Utility.SystemComponentType.SCRAP, "mission_type": null},
]

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


## Removes a component as if it had finished naturally: marks the data
## Resource completed, which emits BaseComponentData.component_completed -
## the signal the owning ComponentManager listens for to despawn the view
## Node and erase the data from its persistent owner (SystemData/PlanetData).
## ComponentManager then emits SignalBus.component_removed, which this panel
## is listening for (_on_components_changed), so the row list refreshes
## itself - no need to call sync_components() here too.
func _on_remove_component_pressed(data: BaseComponentData) -> void:
	data.mark_completed()


## Rebuilds the "Add Component" dropdown: the fixed system-scoped options,
## plus one Analyze entry per planet in the current system (the only
## currently-implemented planet-scoped, user-addable component type -
## Communication is auto-added per planet already and Deliver isn't
## implemented yet, so neither is offered here).
func _rebuild_add_options(system_data: SystemData) -> void:
	_add_options.clear()
	add_type_dropdown.clear()

	for option: Dictionary in SYSTEM_ADD_OPTIONS:
		_add_options.append(option)
		add_type_dropdown.add_item(option.label)

	for planet: PlanetData in system_data.planet_data:
		var option: Dictionary = {
			"label": "Analyze (%s)" % planet.name,
			"component_type": Utility.PlanetComponentType.ANALYZE,
			"mission_type": MissionData.MISSION_TYPE.ANALYZE,
			"planet": planet,
		}
		_add_options.append(option)
		add_type_dropdown.add_item(option.label)


## Adds the component type currently selected in the dropdown to the active
## system (or, for planet-scoped types, the chosen planet), then spawns it
## immediately via the ComponentManager - the same inject_component() path a
## real mission acceptance uses. Since this isn't a real mission, nothing is
## tracked in MissionManager; but anything setup_data() reads off a
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

	var mission: MissionData = null
	if option.get("mission_type") != null:
		mission = MissionGenerator.generate_mission(current_system, LevelManager.galaxy_data, false, option.mission_type)

	var new_data: BaseComponentData
	if option.has("planet"):
		var planet_data: PlanetData = option.planet
		planet_data.add_component(option.component_type, mission)
		new_data = planet_data.components.back()
	else:
		current_system.add_component(option.component_type, mission)
		new_data = current_system.components.back()

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
