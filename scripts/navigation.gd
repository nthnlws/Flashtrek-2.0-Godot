extends Node

var player
var currentSystem: String = "Solarus"
var current_system_faction: Utility.FACTION = 0

# Vars for galaxy map navigation
var leaveDataStored: bool = false # Check to see if player pos has already been check
var targetSystem: String = "" # Currently selected system on galaxy map
var playerEntryInfo: Dictionary

func _process(delta: float) -> void:
	if get_tree().current_scene.name == "Game":
		if Utility.mainScene.in_galaxy_warp:
			if leaveDataStored == false:
				if player_outside_system_check(player.global_position):
					print("Left system at: " + str(player.global_position))
					playerEntryInfo = store_player_system_exit_info()
					print(playerEntryInfo)
		

func player_outside_system_check(coords: Vector2):
	if coords.x > 20000 or coords.x < -20000 or coords.y > 20000 or coords.y < -20000:
		leaveDataStored = true
		return true
	else: return false
	
	
func store_player_system_exit_info():
	var leave_coords: Vector2 = player.global_position
	var leave_rotation: float = player.global_rotation
	
	var leave_info = {
		"exit_pos": leave_coords,
		"leave_rotation": leave_rotation
	}
	var exit = set_player_system_entry_position(leave_info)
	return exit

func set_player_system_entry_position(leave_info):
	var exit_coords = leave_info["exit_pos"]
	var entry_coords = leave_info["exit_pos"]
	var exit_rotation = leave_info["leave_rotation"]
	
	# Flip the exit side to place the player on the opposite side
	if abs(exit_coords.x) >= 20000:
		# Player exited East/West, so flip the x-coordinate
		entry_coords.x *= -1
		# Cap the y-coordinate to 10,000
		entry_coords.y = clamp(exit_coords.y, -10000, 10000)
	elif abs(exit_coords.y) >= 20000:
		# Player exited North/South, so flip the y-coordinate
		entry_coords.y *= -1
		# Cap the x-coordinate to 10,000
		entry_coords.x = clamp(exit_coords.x, -10000, 10000)
	
	var entry_info = {
		"entry_pos": entry_coords,
		"entry_rotation": exit_rotation
	}
	return entry_info
