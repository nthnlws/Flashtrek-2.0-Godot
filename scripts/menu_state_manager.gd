extends CanvasLayer

# Enum for menu states
enum MenuState { NONE, PAUSE_MENU, GAME_OVER, GALAXY_MAP }

# Variable to keep track of the current menu state
var current_state: MenuState = MenuState.NONE


func _ready() -> void:
	SignalBus.pause_menu_clicked.connect(toggle_menu.bindv([$PauseMenu, MenuState.PAUSE_MENU])) #Connect HUD menu button to toggle=


# Input handling
func _input(event):
	if Input.is_action_just_pressed("escape"):
		handle_escape_press()
	elif Input.is_action_just_pressed("letter_m"):
		handle_m_press()

# Handle Escape key press
func handle_escape_press():
	match current_state:
		MenuState.NONE:
			# No menus are open, open the pause menu
			toggle_menu($PauseMenu, MenuState.PAUSE_MENU)
		MenuState.PAUSE_MENU:
			# Pause menu is open, close it
			toggle_menu($PauseMenu, MenuState.NONE)
		MenuState.GALAXY_MAP:
			# Galaxy map is open, close it
			toggle_menu($GalaxyMap, MenuState.NONE)
		MenuState.GAME_OVER:
			toggle_menu($GameOverScreen, MenuState.NONE)

# Handle M key press (for the Galaxy Map)
func handle_m_press():
	match current_state:
		MenuState.NONE:
			# No menus are open, open the Galaxy Map
			toggle_menu($GalaxyMap, MenuState.GALAXY_MAP)
		MenuState.GALAXY_MAP:
			# Galaxy map is open, close it
			toggle_menu($GalaxyMap, MenuState.NONE)


# Toggle the menu visibility and update the state
func toggle_menu(menu: Control, new_state: MenuState):
	print("toggled")
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
