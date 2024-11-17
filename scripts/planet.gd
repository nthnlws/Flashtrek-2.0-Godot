extends Node2D

@onready var sprite = $PlanetTexture
var planetFaction:int = Utility.FACTION.FEDERATION

var CanCommunicate:bool = false
var player

#func _process(delta):
	#print(player)
	
	
func _ready():
	SignalBus.Quad3_clicked.connect(open_hailing_frequency)
	
	#$AnimatedSprite2D.play()
	rotation = round(deg_to_rad(randi_range(0, 360)))
	rotation_degrees = 40

	
	var random_index = "%03d" % randi_range(1, 221)
	var sprite_path = "res://assets/textures/planets/planet_%s.png" % random_index
	sprite.texture = load(sprite_path)
	
	Utility.mainScene.planets.append(self)
	
func _physics_process(delta):
	rotate(deg_to_rad(1.5)*delta)

func open_hailing_frequency():
	if !player: return
	print("comms: ", self.name)

func _on_comm_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		CanCommunicate = true


func _on_comm_area_body_exited(body):
	if body.is_in_group("player"):
		player = null
		CanCommunicate = false
