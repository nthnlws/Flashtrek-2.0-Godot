extends Node

const UNIT = 100

export(PackedScene) var health
export(PackedScene) var bouncing
export(PackedScene) var laser

var health_available: bool = true
var bouncing_available: bool = true
var laser_available: bool = true


func _ready() -> void:
	EventBus.connect("powerup_collected", self, "_on_powerup_collected")


func get_available_powerups() -> PoolStringArray:
	var available_powerups: PoolStringArray = []

	if health_available:
		available_powerups.append("health")
	if bouncing_available:
		available_powerups.append("bouncing")
	if laser_available:
		available_powerups.append("laser")

	return available_powerups


func add_powerup(id: String) -> void:
	var x: float = rand_range(-8.0, 8.0) * UNIT
	var y: float = rand_range(-4.0, 4.0) * UNIT

	var powerup  # uninitialised variable to be the instance of the powerup to add

	match id:
		"health":
			powerup = health.instance()
		"bouncing":
			powerup = bouncing.instance()
		"laser":
			powerup = laser.instance()

	update_powerup_availability(id, false)

	powerup.position = Vector2(x, y)
	add_child(powerup)


func update_powerup_availability(id: String, value: bool) -> void:
	match id:
		"health":
			health_available = value
		"bouncing":
			bouncing_available = value
		"laser":
			laser_available = value


func _on_Timer_timeout() -> void:
	var powerups: PoolStringArray = get_available_powerups()

	if powerups.size() > 0:
		var n: int = randi() % powerups.size()
		add_powerup(powerups[n])


func _on_powerup_collected(id: String) -> void:
	update_powerup_availability(id, true)
