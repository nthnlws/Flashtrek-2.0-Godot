extends TextureRect
class_name RoundedButton

@export var enabled: bool = true
@onready var text_button: TextButton = $TextButton

var active_tweens: Array[Tween]
var animation_duration: float = 0.5

func set_text(new_text: String) -> void:
	text_button.text = new_text


func tween_out() -> void:
	if !enabled: return
	for tween: Tween in active_tweens:
		tween.kill()
	active_tweens.clear()
	
	var tween1: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween1.tween_property(
		self, 
		"scale", 
		Vector2(1.15, 1.0), 
		animation_duration
	)
	
	var tween2: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween2.tween_property(
		text_button, 
		"position", 
		Vector2(24.9, 0.0), 
		animation_duration
	)
	
	var tween3: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween3.tween_property(
		text_button, 
		"scale", 
		Vector2( 1.0 / 1.15, 1.0 ), 
		animation_duration
	)
	
	active_tweens.append(tween1)
	active_tweens.append(tween2)
	active_tweens.append(tween3)


func tween_in() -> void:
	if !enabled: return
	for tween: Tween in active_tweens:
		tween.kill()
	active_tweens.clear()
	
	var tween1: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween1.tween_property(
		self, 
		"scale", 
		Vector2(1.0, 1.0), 
		animation_duration
	)
	
	var tween2: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween2.tween_property(
		text_button, 
		"position", 
		Vector2( 0.0, 0.0 ), 
		animation_duration
	)
	
	var tween3: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween3.tween_property(
		text_button, 
		"scale", 
		Vector2( 1.0, 1.0 ), 
		animation_duration
	)
	
	active_tweens.append(tween1)
	active_tweens.append(tween2)
	active_tweens.append(tween3)
