extends Node

@onready var music: AudioStreamPlayer = %Mesa



func _ready() -> void:
	SignalBus.entering_galaxy_warp.connect(fade_music_out)
	
	call_deferred("start_music")
	
	
	

func start_music():
	match Navigation.current_system_faction:
		Utility.FACTION.FEDERATION:
			print("Fed Music")
			music.play()
		Utility.FACTION.KLINGON:
			print("Klingon Music")
			music.play()
		Utility.FACTION.ROMULAN:
			print("Romulan Music")
			music.play()
		_:
			print("Default system music")
			music.play()
func fade_music_out():
	music.stop()
