extends Node

@onready var fed_music: AudioStreamPlayer = $FedMusic
@onready var klingon_music: AudioStreamPlayer = $KlingonMusic
@onready var romulan_music: AudioStreamPlayer = $RomulanMusic
@onready var main_menu_music: AudioStreamPlayer = $MainMenuMusic

@export var click_sounds: Array[AudioStreamOggVorbis]
@export var button_select: AudioStreamOggVorbis

var current_music_player: AudioStreamPlayer


func _ready() -> void:
	SignalBus.UIselectSound.connect(play_UI_select_sound)
	SignalBus.UIclickSound.connect(play_UI_click_sound)
	SignalBus.entering_galaxy_warp.connect(fade_music_out)
	SignalBus.playerDied.connect(fade_music_out)


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
	add_child(player)
	await player.finished
	player.queue_free()


func play_music(is_main_menu:bool = false, faction: Utility.FACTION = Utility.FACTION.FEDERATION) -> void:
	# Stop any existing music
	if current_music_player:
		current_music_player.stop()
		print("%s stopped" % current_music_player.name)
	
	if is_main_menu:
		main_menu_music.play()
		current_music_player = main_menu_music
		print('main menu playing')
		return
	
	if faction == Utility.FACTION.FEDERATION:
		fed_music.play()
		current_music_player = fed_music
		print('fed playing')
	elif faction == Utility.FACTION.KLINGON:
		klingon_music.play()
		current_music_player = klingon_music
		print('klingon playing')
	elif faction == Utility.FACTION.ROMULAN:
		romulan_music.play()
		current_music_player = romulan_music
		print('romulan playing')


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


func update_bus_volume(bus_idx: int, value: float) -> void:
	# Convert linear slider to Decibels
	var db_val: float = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_idx, db_val)
