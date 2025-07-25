extends Node

@onready var fed_music: AudioStreamPlayer = %"Fed - Mesa"
@onready var klingon_music: AudioStreamPlayer = %"Klingon - Subterranean"
@onready var rom_music: AudioStreamPlayer = %"Romulan - Rising Dawn"

var fed_volume: float = -15.0
var rom_volume: float = -20.0
var klingon_volume: float = -15.0


func _ready() -> void:
	SignalBus.galaxy_warp_finished.connect(start_music.unbind(1))
	SignalBus.entering_galaxy_warp.connect(fade_music_out)
	SignalBus.playerDied.connect(fade_music_out)
	SignalBus.playerRespawned.connect(start_music)
	
	start_music()


func start_music() -> void:
	match Navigation.current_system_faction:
		Utility.FACTION.FEDERATION:
			fed_music.volume_db = fed_volume
			fed_music.play()
		Utility.FACTION.KLINGON:
			klingon_music.volume_db = klingon_volume
			klingon_music.play()
		Utility.FACTION.ROMULAN:
			rom_music.volume_db = rom_volume
			rom_music.play()
		_:
			fed_music.volume_db = fed_volume
			fed_music.play()

func fade_music_out() -> void:
	if fed_music.is_playing():
		var tween: Tween = create_tween()
		tween.tween_property(fed_music, "volume_db", -50, Utility.fadeLength * 2)
		await tween.finished
		stop_music()
		return
		
	elif klingon_music.is_playing():
		var tween: Tween = create_tween()
		tween.tween_property(klingon_music, "volume_db", -50, Utility.fadeLength * 2)
		await tween.finished
		stop_music()
		return
		
	elif rom_music.is_playing():
		var tween: Tween = create_tween()
		tween.tween_property(rom_music, "volume_db", -50, 5.0)
		await tween.finished
		stop_music()
		

func stop_music() -> void:
	if fed_music.is_playing():
		fed_music.stop()
	elif klingon_music.is_playing():
		klingon_music.stop()
	elif rom_music.is_playing():
		rom_music.stop()
