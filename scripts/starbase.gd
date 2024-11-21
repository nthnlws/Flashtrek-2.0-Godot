extends Node2D

@onready var sprite = $Sprite2D
@onready var comm_distance = $Area2D/CollisionShape2D.shape.radius


func _init():
	Utility.mainScene.starbase.append(self)
	
func _ready():
	SignalBus.Quad3_clicked.connect(toggle_comms)
	
	rotation_degrees = 40
	
func _physics_process(delta):
	rotate(deg_to_rad(1.5)*delta)

func toggle_comms():# Only toggles on if within required distance
	if check_distance_to_planets(): # and Utility.mainScene.player[0].warping_active == false:
		# Open starbase menu here
		#starbase_menu.visible = true
		pass

func check_distance_to_planets() -> bool:
	var player_position = Utility.mainScene.player[0].global_position

	var starbase_position = self.global_position
	var distance = player_position.distance_to(starbase_position)
	
	# Check if the distance is within the threshold
	if distance <= comm_distance:
		return true

	# No planet is within the specified distance
	return false
