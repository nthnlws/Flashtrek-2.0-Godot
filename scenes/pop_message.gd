extends Control

@onready var pop_message: RichTextLabel = $pop_message
@onready var timer: Timer = $Timer

var showing: bool = false
var pop_up_time: float = 3.0

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = pop_up_time
	SignalBus.changePopMessage.connect(_update_text)
	
	pop_message.bbcode_text = Utility.damage_red + "No error message[/color]"
	self.position = Vector2(0, -130)

	
		
func _update_text(error_message):
	pop_message.bbcode_text = Utility.damage_red + error_message + "[/color]"
	
	open_pop_menu()
	if $Timer.is_stopped() == false: # If timer is already running, restarts timer fresh
		$Timer.stop()
		$Timer.start()
		await $Timer.timeout
	if $Timer.is_stopped() == true: # Starts timer if it is not already
		$Timer.start()
		await $Timer.timeout
	close_pop_menu()

var current_tweens = []
func close_pop_menu(): # Expand or collapse mission menu
	# Stop all running tweens
	for tween in current_tweens:
		if tween.is_running():
			tween.stop()
			
	var tween_pos = create_tween()
	tween_pos.tween_property(self, "position", Vector2(0, -130), 1.0)
	current_tweens.append(tween_pos)
	showing = false

func open_pop_menu():
	var tween_pos = create_tween()
	tween_pos.tween_property(self, "position", Vector2(0, 0), 1.0)
	current_tweens.append(tween_pos)
	showing = true
