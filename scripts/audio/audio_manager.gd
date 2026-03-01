extends Node
class_name AudioManager

@export var click_sounds: Array[AudioStreamOggVorbis]
@export var button_select: AudioStreamOggVorbis
@export var federation_music: AudioStreamOggVorbis
@export var klingon_music: AudioStreamOggVorbis
@export var romulan_music: AudioStreamOggVorbis

var current_music_player: AudioStreamPlayer


func _ready() -> void:
	SignalBus.UIselectSound.connect(play_UI_select_sound)
	SignalBus.UIclickSound.connect(play_UI_click_sound)
	SignalBus.galaxy_warp_finished.connect(start_music.unbind(1))
	SignalBus.entering_galaxy_warp.connect(fade_music_out)
	SignalBus.playerDied.connect(fade_music_out)
	SignalBus.playerRespawned.connect(start_music)
	
	start_music()


func play_UI_select_sound() -> void:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	var audio: AudioStreamOggVorbis = button_select
	player.bus = AudioServer.get_bus_name(Utility.AUDIO_BUS.MENUS)
	player.stream = audio
	player.autoplay = true
	player.mix_target = AudioStreamPlayer.MIX_TARGET_CENTER
	player.volume_db = -7.0
	add_child(player)


func play_UI_click_sound() -> void: 
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	var audio: AudioStreamOggVorbis = click_sounds.pick_random()
	player.bus = AudioServer.get_bus_name(Utility.AUDIO_BUS.MENUS)
	player.stream = audio
	player.autoplay = true
	player.mix_target = AudioStreamPlayer.MIX_TARGET_CENTER
	if audio.resource_name == "computerbeep_01":
		player.volume_db = -5.0
	elif audio.resource_name == "computerbeep_02": 
		player.volume_db = -13.5
	elif audio.resource_name == "computerbeep_03": 
		player.volume_db = -20.0
	add_child(player)


var fed_volume: float = -20.0
var rom_volume: float = -24.0
var klingon_volume: float = -20.0
func start_music() -> void:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = AudioServer.get_bus_name(Utility.AUDIO_BUS.MENUS)
	if LevelManager.current_system_data:
		match LevelManager.current_system_data.faction:
			Utility.FACTION.FEDERATION:
				player.volume_db = fed_volume
				player.stream = federation_music
			Utility.FACTION.KLINGON:
				player.volume_db = klingon_volume
				player.stream = klingon_music
			Utility.FACTION.ROMULAN:
				player.volume_db = rom_volume
				player.stream = romulan_music
			_:
				federation_music.volume_db = federation_music
				player.stream = federation_music
				printerr("No faction match for playing music in current system")
		add_child(player)
		current_music_player = player
		player.play()


func fade_music_out() -> void:
	if current_music_player.is_playing():
		var tween: Tween = create_tween()
		tween.tween_property(current_music_player, "volume_db", -50, Utility.fadeLength * 2)
		await tween.finished
		stop_music()
		return


func stop_music() -> void:
	if current_music_player.is_playing():
		current_music_player.stop()
