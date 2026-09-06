extends CanvasLayer

# Enum for menu states
@onready var settings_menu: SettingsMenu = $SettingsMenu

# Variable to keep track of the current menu state
var current_state: Utility.MENUSTATE = Utility.MENUSTATE.NONE:
	set(new_state):
		current_state = new_state
		Utility.current_menu = new_state
		if new_state == Utility.MENUSTATE.NONE:
			#print('state None, show aimer')
			$Crosshair.visible = true
		else:
			#print("menu state, hide aimer")
			$Crosshair.visible = false

@onready var loading_screen: Control = %LoadingScreen


func _ready() -> void:
	SignalBus.playerDied.connect(_handle_player_death)
	SignalBus.pause_menu_clicked.connect(_handle_pause_menu_clicked) #Connect HUD menu button to toggle=
	SignalBus.CommsButton_clicked.connect(toggle_ship_selection)
	SignalBus.ShipButton_clicked.connect(toggle_upgrade_menu)
	SignalBus.entering_galaxy_warp.connect(func(): current_state = Utility.MENUSTATE.NONE)
	SignalBus.NavButton_clicked.connect(activate_galaxy_map)


# Input handling
func _unhandled_input(event: InputEvent) -> void:
	if Utility.current_gamestate != Utility.GAMESTATE.WARPING:
		if Input.is_action_just_pressed("escape"):
			handle_escape_press()
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("letter_m"):
			handle_m_press()
			get_viewport().set_input_as_handled()

func _handle_pause_menu_clicked() -> void:
	match current_state:
		Utility.MENUSTATE.NONE:
			toggle_menu(settings_menu, Utility.MENUSTATE.SETTINGS)
		Utility.MENUSTATE.SETTINGS:
			toggle_menu(settings_menu, Utility.MENUSTATE.NONE)

# Handle Escape key press
func handle_escape_press() -> void:
	match current_state:
		Utility.MENUSTATE.NONE:
			# No menus are open, open the settings menu
			if Utility.current_gamestate != Utility.GAMESTATE.WARPING:
				toggle_menu(settings_menu, Utility.MENUSTATE.SETTINGS)
		Utility.MENUSTATE.SETTINGS:
			# Setting menu is open, close it
			toggle_menu(settings_menu, Utility.MENUSTATE.NONE)
		Utility.MENUSTATE.GALAXY:
			# Galaxy map is open, close it
			toggle_menu($GalaxyMap, Utility.MENUSTATE.NONE)
		Utility.MENUSTATE.STARBASE:
			# Starbase comms are open, close it
			toggle_menu($StarbaseMenu, Utility.MENUSTATE.NONE)
		Utility.MENUSTATE.SHIPINFO:
			# Ship status menu is open, close it
			toggle_menu($ShipStatusMenu, Utility.MENUSTATE.NONE)


# Handle M key press (for the Galaxy Map)
func handle_m_press() -> void:
	match current_state:
		Utility.MENUSTATE.NONE:
			# No menus are open, open the Galaxy Map
			toggle_menu($GalaxyMap, Utility.MENUSTATE.GALAXY)
		Utility.MENUSTATE.GALAXY:
			# Galaxy map is open, close it
			toggle_menu($GalaxyMap, Utility.MENUSTATE.NONE)
		_:
			return # Do nothing for all other menu states


func activate_galaxy_map() -> void:
	match current_state:
		Utility.MENUSTATE.NONE:
			# No menus are open, open the Galaxy Map
			toggle_menu($GalaxyMap, Utility.MENUSTATE.GALAXY)
		_:
			return # Do nothing for all other menu states


func _handle_player_death() -> void:
	var menus: Array[Node] = get_children()
	for menu in menus:
		if menu.visible and menu != $Crosshair:
			toggle_menu(menu, Utility.MENUSTATE.NONE)


func toggle_ship_selection():
	var starbase_menu = $StarbaseMenu
	var starbase: Node2D = LevelManager.starbases[0]
	if starbase.player_in_range == true:
		starbase_menu.visible = true
		starbase_menu.mouse_filter = Control.MOUSE_FILTER_STOP
		starbase_menu.start_ambience()
		current_state = Utility.MENUSTATE.STARBASE


func toggle_upgrade_menu():
	$ShipStatusMenu.visible = true
	$ShipStatusMenu.mouse_filter = Control.MOUSE_FILTER_STOP
	current_state = Utility.MENUSTATE.SHIPINFO


# Toggle the menu visibility and update the state
func toggle_menu(menu: Control, new_state: Utility.MENUSTATE) -> void:
	current_state = new_state
	if new_state == Utility.MENUSTATE.NONE:
		# Explicit close
		menu.visible = false
		menu.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		# Explicit open
		menu.visible = true
		menu.mouse_filter = Control.MOUSE_FILTER_STOP

func _handle_ship_menu_closed() -> void:
	current_state = Utility.MENUSTATE.NONE


func _handle_settings_closed() -> void:
	settings_menu.visible = false
	current_state = Utility.MENUSTATE.NONE
