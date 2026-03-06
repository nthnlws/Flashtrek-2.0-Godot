extends CanvasLayer

# Enum for menu states
enum MenuState { NONE, PAUSE_MENU, GALAXY_MAP, SHIP_SELECTION, SHIP_UPGRADE }
@onready var settings_menu: SettingsMenu = $SettingsMenu

# Variable to keep track of the current menu state
var current_state: MenuState = MenuState.NONE:
	set(new_state):
		current_state = new_state
		if new_state == MenuState.NONE:
			#print('state None, show aimer')
			$Crosshair.visible = true
		else:
			#print("menu state, hide aimer")
			$Crosshair.visible = false

@onready var loading_screen: Control = %LoadingScreen


func _ready() -> void:
	SignalBus.playerDied.connect(_handle_player_death)
	SignalBus.pause_menu_clicked.connect(_handle_pause_menu_clicked) #Connect HUD menu button to toggle=
	SignalBus.BottomRight_clicked.connect(toggle_ship_selection)
	SignalBus.Center_clicked.connect(toggle_upgrade_menu)
	SignalBus.entering_galaxy_warp.connect(func(): current_state = MenuState.NONE)


# Input handling
func _input(event: InputEvent) -> void:
	if Utility.current_gamestate != Utility.GAMESTATE.WARPING:
		if Input.is_action_just_pressed("escape"):
			handle_escape_press()
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("letter_m"):
			handle_m_press()
			get_viewport().set_input_as_handled()

func _handle_pause_menu_clicked() -> void:
	match current_state:
		MenuState.NONE:
			toggle_menu(settings_menu, MenuState.PAUSE_MENU)
		MenuState.PAUSE_MENU:
			toggle_menu(settings_menu, MenuState.NONE)

# Handle Escape key press
func handle_escape_press() -> void:
	match current_state:
		MenuState.NONE:
			# No menus are open, open the pause menu
			if Utility.current_gamestate != Utility.GAMESTATE.WARPING:
				toggle_menu(settings_menu, MenuState.PAUSE_MENU)
		MenuState.PAUSE_MENU:
			# Pause menu is open, close it
			toggle_menu(settings_menu, MenuState.NONE)
		MenuState.GALAXY_MAP:
			# Galaxy map is open, close it
			toggle_menu($GalaxyMap, MenuState.NONE)
		MenuState.SHIP_SELECTION:
			# Starbase comms are open, close it
			toggle_menu($ShipSelectionMenu, MenuState.NONE)
		MenuState.SHIP_UPGRADE:
			# Ship upgrade menu is open, close it
			toggle_menu($ShipUpgradeMenu, MenuState.NONE)


# Handle M key press (for the Galaxy Map)
func handle_m_press() -> void:
	match current_state:
		MenuState.NONE:
			# No menus are open, open the Galaxy Map
			toggle_menu($GalaxyMap, MenuState.GALAXY_MAP)
		MenuState.GALAXY_MAP:
			# Galaxy map is open, close it
			toggle_menu($GalaxyMap, MenuState.NONE)
		_:
			return # Do nothing for all other menu states


func _handle_player_death() -> void:
	var menus: Array[Node] = get_children()
	for menu in menus:
		if menu.visible and menu != $Crosshair:
			toggle_menu(menu, MenuState.NONE)


func toggle_ship_selection():
	var starbase: Node2D = LevelManager.starbases[0]
	if starbase.player_in_range == true:
		$ShipSelectionMenu.visible = true
		$ShipSelectionMenu.mouse_filter = Control.MOUSE_FILTER_STOP
		$ShipSelectionMenu.start_ambience()
		current_state = MenuState.SHIP_SELECTION


func toggle_upgrade_menu():
	$ShipUpgradeMenu.visible = true
	$ShipUpgradeMenu.mouse_filter = Control.MOUSE_FILTER_STOP
	current_state = MenuState.SHIP_UPGRADE


# Toggle the menu visibility and update the state
func toggle_menu(menu: Control, new_state: MenuState) -> void:
	if new_state == MenuState.NONE:
		# Explicit close
		menu.visible = false
		menu.mouse_filter = Control.MOUSE_FILTER_PASS
		current_state = MenuState.NONE
	else:
		# Explicit open
		menu.visible = true
		menu.mouse_filter = Control.MOUSE_FILTER_STOP
		current_state = new_state


func _handle_ship_menu_closed() -> void:
	current_state = MenuState.NONE


func _handle_settings_closed() -> void:
	settings_menu.visible = false
	current_state = MenuState.NONE
