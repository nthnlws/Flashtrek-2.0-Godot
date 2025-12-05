# SaveManager.gd
extends Node

var current_save_slot:int = -1

const SAVE_FOLDER: String = "user://saves/"
const SAVE_FILE_TEMPLATE: String = "save_slot_%d.tres" # Can change to .res for smaller space

# Ensure the save directory exists
func _verify_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_FOLDER):
		DirAccess.make_dir_absolute(SAVE_FOLDER)


func get_save_path(slot: int) -> String:
	return SAVE_FOLDER + (SAVE_FILE_TEMPLATE % slot)


# SAVE FUNCTION
func save_galaxy(slot: int, data: GalaxyData) -> bool:
	if slot < 1 or slot > 3:
		push_error("Invalid save slot: %d. Must be 1-3." % slot)
		return false
		
	_verify_save_directory()
	
	var path: String = get_save_path(slot)
	var error: Error = ResourceSaver.save(data, path)
	
	if error != OK:
		push_error("Failed to save game to slot %d. Error code: %s" % [slot, error])
		return false
		
	print("Game successfully saved to slot %d" % slot)
	return true


func load_galaxy(slot: int) -> GalaxyData:
	if slot < 1 or slot > 3:
		push_error("Invalid save slot: %d" % slot)
		return null
		
	var path: String = get_save_path(slot)
	
	if not FileAccess.file_exists(path):
		push_warning("No save file found for slot %d" % slot)
		return null
		
	var data: Resource = ResourceLoader.load(path)
	
	if data is GalaxyData:
		var galaxy: GalaxyData = data as GalaxyData
		# CRITICAL: Rebuild the lookup map that wasn't saved
		galaxy.post_load_setup()
		print("Game successfully loaded from slot %d" % slot)
		return galaxy
	else:
		push_error("Failed to cast resource to GalaxyData.")
		return null


# CHECK IF SLOT EXISTS (For UI)
func save_slot_exists(slot: int) -> bool:
	var path: String = get_save_path(slot)
	return FileAccess.file_exists(path)

# DELETE SLOT
func delete_save(slot: int) -> void:
	var path: String = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
