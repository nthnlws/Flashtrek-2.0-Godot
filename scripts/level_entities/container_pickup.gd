extends Area2D
class_name ContainerPickup

@export var container_data:ContainerData
@onready var sprite: AnimatedSprite2D = $SpriteFrames


func _ready() -> void:
	if !container_data:
		container_data = ContainerData.new()
	
	print(Utility.FACTION.keys()[container_data.faction])
	match container_data.faction:
		Utility.FACTION.FEDERATION:
			sprite.set_animation("federation")
		Utility.FACTION.ROMULAN:
			sprite.set_animation("romulan")
		Utility.FACTION.KLINGON:
			sprite.set_animation("klingon")
		_:
			sprite.set_animation("federation")
	sprite.play()
