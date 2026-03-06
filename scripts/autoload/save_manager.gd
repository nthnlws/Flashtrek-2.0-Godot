# SaveManager.gd
extends Node

var current_save_slot: int = -1

const SAVE_FOLDER: String = "user://saves/"
const SAVE_FILE_TEMPLATE: String = "save_slot_%d.res"


const SETTINGS_PATH: String = "user://settings.tres"
var current_settings: SettingsResource

func _ready() -> void:
	_load_menu_settings()
	_apply_menu_settings()

	SignalBus.entering_galaxy_warp.connect(func(): save_galaxy(current_save_slot, LevelManager.galaxy_data))


func _apply_menu_settings() -> void:
	# Apply Video
	DisplayServer.window_set_vsync_mode(current_settings.vsync_setting)
	
	# Apply Audio
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.MASTER, current_settings.master_volume)
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.MUSIC, current_settings.music_volume)
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.EFFECTS, current_settings.effects_volume)
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.MENUS, current_settings.menus_volume)


func _load_menu_settings() -> void:
	if ResourceLoader.exists(SETTINGS_PATH):
		current_settings = load(SETTINGS_PATH) as SettingsResource
	
	if not current_settings:
		current_settings = SettingsResource.new()

func save_settings() -> void:
	ResourceSaver.save(current_settings, SETTINGS_PATH)


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
	var data_to_save: GalaxyData = data.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var error: Error = ResourceSaver.save(data_to_save, path)
	
	if error != OK:
		push_error("Failed to save game to slot %d. Error code: %s" % [slot, error])
		return false
		
	var rep_path: String = SAVE_FOLDER + ("save_slot_%d_rep.res" % slot)
	var rep_error: Error = ResourceSaver.save(MissionManager.Reputation, rep_path)
	if rep_error != OK:
		push_error("Failed to save player reputation to slot %d. Error code: %s" % [slot, rep_error])
		
	#print("Game successfully saved to slot %d" % slot)
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
		var rep_path: String = SAVE_FOLDER + ("save_slot_%d_rep.res" % slot)
		if FileAccess.file_exists(rep_path):
			var rep_data: Resource = ResourceLoader.load(rep_path)
			if rep_data is PlayerReputation:
				MissionManager.Reputation = rep_data as PlayerReputation
				MissionManager.Reputation.player_faction_changed.emit(MissionManager.Reputation.current_player_faction)

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
	var rep_path: String = SAVE_FOLDER + ("save_slot_%d_rep.res" % slot)
	if FileAccess.file_exists(rep_path):
		DirAccess.remove_absolute(rep_path)
