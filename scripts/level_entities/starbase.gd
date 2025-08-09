extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var comm_distance: float = $Area2D/CollisionShape2D.shape.radius

var player_in_range:bool = false

func _ready() -> void:
	SignalBus.level_entity_added.emit(self, "Starbase")
	
	
	z_index = Utility.Z["Starbase"]
	
	
func _physics_process(delta: float) -> void:
	rotate(deg_to_rad(1.5)*delta)


func check_distance_to_planets() -> bool:
	var player_position: Vector2 = LevelData.player.global_position

	var starbase_position: Vector2 = self.global_position
	var distance: float = player_position.distance_to(starbase_position)
	
	# Check if the distance is within the threshold
	if distance <= comm_distance:
		return true

	# No planet is within the specified distance
	return false


func _on_starbase_area_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.toggleQ4HUD.emit("on")
		player_in_range = true

func _on_starbase_area_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.toggleQ4HUD.emit("off")
		player_in_range = false
