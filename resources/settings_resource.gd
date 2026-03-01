extends Resource
class_name SettingsResource

@export_group("Video")
@export var vsync_setting: DisplayServer.VSyncMode = DisplayServer.VSYNC_ENABLED

@export_group("Audio")
@export var master_volume: float = 0.8
@export var music_volume: float = 0.8
@export var effects_volume: float = 0.8
@export var menus_volume: float = 0.5

@export_group("Game")
@export var ui_scale: float = 0.7
