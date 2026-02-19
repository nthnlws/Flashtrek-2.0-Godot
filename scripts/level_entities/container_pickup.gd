extends Area2D
class_name ContainerPickup

@export var container_data:ContainerData
@onready var sprite: AnimatedSprite2D = $SpriteFrames


func _ready() -> void:
	if !container_data:
		container_data = ContainerData.new()
		printerr("No container data assigned to container")
	
	# Set sprite
	if container_data.faction == Utility.FACTION.FEDERATION:
		sprite.set_animation("federation")
	elif container_data.faction == Utility.FACTION.ROMULAN:
		sprite.set_animation("romulan")
	elif container_data.faction == Utility.FACTION.KLINGON:
		sprite.set_animation("klingon")
	sprite.play()
	
	# Set position
	self.global_position = container_data.spawn_position
