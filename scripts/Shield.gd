class_name Shield extends Sprite2D

@onready var shield_collision = $Area2D/CollisionShape2D
@onready var player = get_tree().current_scene.get_node("Game/Player")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func fadeout(): #Fades shield to 0 Alpha
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 0, 0.5)	
	await tween.finished
	shield_collision.set_deferred("disabled", true)

func fadein(): #Fades shield in to 255 Alpha
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 1, 0.5)	
	await tween.finished
	shield_collision.set_deferred("disabled", false)
