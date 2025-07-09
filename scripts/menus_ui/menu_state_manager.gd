extends CanvasLayer

# Enum for menu states
enum MenuState { NONE, PAUSE_MENU, GALAXY_MAP, SHIP_SELECTION }

# Variable to keep track of the current menu state
var current_state: MenuState = MenuState.NONE

@onready var loading_screen: Control = %LoadingScreen


func _ready() -> void:
	SignalBus.playerDied.connect(_handle_player_death)
	SignalBus.pause_menu_clicked.connect(toggle_menu.bindv([$PauseMenu, MenuState.PAUSE_MENU])) #Connect HUD menu button to toggle=
	SignalBus.Quad4_clicked.connect(toggle_menu.bindv([$ShipSelectionMenu, MenuState.SHIP_SELECTION]))

# Input handling
func _input(event: InputEvent) -> void:
	if Utility.mainScene.in_galaxy_warp == false:
		if Input.is_action_just_pressed("escape"):
			handle_escape_press()
		elif Input.is_action_just_pressed("letter_m"):
			handle_m_press()
	
	
	
# Handle Escape key press
func handle_escape_press() -> void:
	match current_state:
		MenuState.NONE:
			# No menus are open, open the pause menu
			if Utility.mainScene.in_galaxy_warp == false:
				toggle_menu($PauseMenu, MenuState.PAUSE_MENU)
		MenuState.PAUSE_MENU:
			# Pause menu is open, close it
			toggle_menu($PauseMenu, MenuState.NONE)
		MenuState.GALAXY_MAP:
			# Galaxy map is open, close it
			toggle_menu($GalaxyMap, MenuState.NONE)
		MenuState.SHIP_SELECTION:
			# Starbse comms are open, close it
			toggle_menu($ShipSelectionMenu, MenuState.NONE)

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
		if menu.visible:
			toggle_menu(menu, MenuState.NONE)
		
# Toggle the menu visibility and update the state
func toggle_menu(menu: Control, new_state: MenuState) -> void:
	if menu == $ShipSelectionMenu:
		var starbase: Node2D = Utility.mainScene.starbase[0]
		if !starbase.check_distance_to_planets():
			menu.visible = true
			menu.mouse_filter = Control.MOUSE_FILTER_STOP
			current_state = new_state
	if menu.visible == false:
		# Show the menu
		menu.visible = true
		menu.mouse_filter = Control.MOUSE_FILTER_STOP
		current_state = new_state
	else:
		# Hide the menu
		menu.visible = false
		menu.mouse_filter = Control.MOUSE_FILTER_PASS
		current_state = MenuState.NONE
