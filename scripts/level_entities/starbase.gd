extends Node2D
class_name Starbase

@onready var sprite: Sprite2D = $Sprite2D
@onready var comm_distance: float = $Area2D/CollisionShape2D.shape.radius

var player_in_range:bool = false
const STARBASE_FEDERATION = preload("uid://p0cyamor3c2t")
const STARBASE_KLINGON = preload("uid://dvdnin0yidfsm")
const STARBASE_ROMULAN = preload("uid://b0yxn416jdx8a")


func _ready() -> void:
	z_index = Utility.Z["Starbase"]
	
	SignalBus.system_changed.connect(update_faction)


func update_faction(new_system: SystemData) -> void:
	var new_faction: Utility.FACTION = new_system.faction
	if new_faction == Utility.FACTION.FEDERATION:
		sprite.texture = STARBASE_FEDERATION
		sprite.scale = Vector2(0.7, 0.7)
	if new_faction == Utility.FACTION.KLINGON:
		sprite.texture = STARBASE_KLINGON
		sprite.scale = Vector2(1.27, 1.27)
	if new_faction == Utility.FACTION.ROMULAN:
		sprite.texture = STARBASE_ROMULAN
		sprite.scale = Vector2(0.63, 0.63)


func _physics_process(delta: float) -> void:
	rotate(deg_to_rad(1.5)*delta)
	sprite.rotation = snappedf(sprite.rotation, deg_to_rad(1.0))


func check_distance_to_planets() -> bool:
	var player_position: Vector2 = LevelManager.player.global_position

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
