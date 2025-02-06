extends Node

@onready var music: AudioStreamPlayer = %Mesa


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.entering_galaxy_warp.connect(fade_music_out)
	
	call_deferred("start_music")
	
	
	

func start_music():
	match Utility.mainScene.get_node("Level").get_faction_for_system(20):
		"Federation":
			print("Fed Music")
			music.play()
		"Klingon":
			print("Klingon Music")
			music.play()
		"Romulan":
			print("Romulan Music")
			music.play()
		_:
			print("Default system music")
			music.play()
func fade_music_out():
	music.stop()
