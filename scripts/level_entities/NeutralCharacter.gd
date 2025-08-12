extends CharacterBody2D
class_name NeutralCharacter

@export var ship_type:Utility.SHIP_TYPES = Utility.SHIP_TYPES.Merchantman
var faction: Utility.FACTION = Utility.FACTION.NEUTRAL

@onready var sprite: Sprite2D = $Sprite2D  # Reference to the sprite node
@onready var hitbox: CollisionPolygon2D = $hitbox_area/CollisionPolygon2D  # Reference to the CollisionShape2D node
@onready var collision_shape: CollisionPolygon2D = $WorldCollisionShape
@onready var shield: Node = $Shield
@onready var animation: AnimatedSprite2D = $hull_explosion

# Variables for handling dynamic behavior
var move_speed: int = 60
var rotation_rate: float = 1.5
var shield_on: bool = true
var hp_max: int = 100:
	set(value): # Ensures that current HP = max_HP when changed
		hp_max = value
		hp_current = value
var angle_diff: float

#Enemy health variables
var hp_current: float = 100.0

var alive: bool = true
var endPoint: Vector2
var returnToStarbaseBool: bool = false
var moveTarget: String

var AI_enabled:bool = true
var starbase: Node2D  # Path to starbase, only set if AI_enabled is true


func _ready() -> void:
	_create_unique_atlas()
	shield.shieldStatusChanged.connect(func(shieldStatus:bool): shield_on = shieldStatus)

	_sync_data_to_resource(ship_type)
	_sync_stats_to_resource(ship_type)
	
	# Initialize AI-related data
	if AI_enabled:
		starbase = LevelData.starbase[0]
	
	# Set initial movement state target
	call_deferred("selectRandomPlanet")
	z_index = Utility.Z["NeutralShips"]


func _create_unique_atlas() -> void:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/textures/ships/ship_sprites.png")
	atlas_texture.filter_clip = true
	sprite.texture = atlas_texture


func _sync_data_to_resource(ship:Utility.SHIP_TYPES):
	var ship_data:Dictionary = Utility.SHIP_DATA.values()[ship]
	
	sprite.texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
	faction = ship_data.FACTION
	shield.scale = Vector2(ship_data.SHIELD_SCALE_X, ship_data.SHIELD_SCALE_Y)
	
	var rawColl = ship_data.COLLISION_POLY
	var parsed_array = JSON.parse_string(rawColl)
	var PV2Array = PackedVector2Array()
	for pair in parsed_array:
		PV2Array.append(Vector2(pair[0], pair[1]))
	PV2Array = center_polygon(PV2Array)
	collision_shape.polygon = PV2Array
	hitbox.polygon = PV2Array


func _sync_stats_to_resource(ship:Utility.SHIP_TYPES):
	var ship_stats:Dictionary = Utility.ENEMY_SHIP_STATS.values()[ship]
	
	move_speed = ship_stats.SPEED
	rotation_rate = ship_stats.ROTATION_SPEED
	hp_max = ship_stats.MAX_HP
	shield.sp_max = ship_stats.MAX_SHIELD


func center_polygon(points: Array) -> PackedVector2Array:
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y

	# Find bounds
	for p in points:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var center_x = (min_x + max_x) / 2.0
	var center_y = (min_y + max_y) / 2.0

	var adjusted_points = []
	for p in points:
		var centered = Vector2(p.x - center_x, p.y - center_y)
		var shifted = centered + Vector2(1, -4)
		adjusted_points.append(shifted)

	return PackedVector2Array(adjusted_points)


func _set_ship_scale(new_scale: Vector2) -> void:
	shield.scale *= new_scale
	sprite.scale *= new_scale
	$hitbox_area.scale *= new_scale


func _physics_process(delta: float) -> void:
	#TODO Sync Player and Enemy speed stats to be compatible
	if not AI_enabled or not visible or not GameSettings.enemyMovement or alive == false:
		return
	
	# Movement state setter
	setMovementState(delta)
	
	move_and_slide()


func setMovementState(delta:float) -> void:
	if global_position.distance_to(starbase.global_position) < 1500 and moveTarget == "Starbase":
		returnToStarbaseBool = false
		selectRandomPlanet()
		moveTarget = "Planet"
	elif returnToStarbaseBool == false: # Movement toward picked planet
		planetMovement(delta)
		moveTarget = "Planet"
	elif returnToStarbaseBool == true: # Move toward starbase
		starbaseMovement(delta)
		moveTarget = "Starbase"
	else: print("No matching movement status")


func selectRandomPlanet() -> void:
	endPoint = LevelData.planets.pick_random().global_position


func starbaseMovement(delta:float) -> void:
	if starbase:
		var starbaseLocation: Vector2 = starbase.global_position
		var direction = global_position.direction_to(starbase.position) # Sets movement direction to starbase
		moveToTarget("Starbase", starbaseLocation, delta)


func planetMovement(delta:float) -> void: 
	moveToTarget("Planet", endPoint, delta)
	
	
	if self.global_position.distance_to(endPoint) < 5:
		returnToStarbaseBool = true


func moveToTarget(targetName:String, targetPos:Vector2, delta: float) -> void:
	velocity = (targetPos - self.global_position).normalized()*move_speed
	var angle_diff = calc_angle(targetPos, delta)
	look_at_target(targetPos, angle_diff, delta)
	move_and_slide()


func calc_angle(targetPos:Vector2, delta:float) -> float:
	var angle: float = (targetPos - self.global_position).angle() + deg_to_rad(90)
	var rotation_speed: float = rotation_rate * delta
	var angle_diff = wrapf(angle - self.global_rotation, -PI, PI)
	
	return angle_diff


func look_at_target(targetPos:Vector2,angle_diff:float, delta:float) -> void:
	var angle: float = (targetPos - self.global_position).angle() + deg_to_rad(90)
	var rotation_speed: float = rotation_rate * delta
	rotation = lerp_angle(self.global_rotation, angle, min(rotation_speed / abs(angle_diff), 1))


func explode() -> void:
	alive = false
	shield.turnShieldOff()
	sprite.visible = false
	
	LevelData.neutralShips.erase(self)
	SignalBus.neutralShipDied.emit(self)
	var system_data:Dictionary = LevelData.all_systems_data[Navigation.currentSystem]
	var neutrals_list:Dictionary = system_data["neutrals"]
	if neutrals_list.has(self.name):
		neutrals_list.erase(self.name)
		if neutrals_list.is_empty():
			system_data["neutrals_defeated"] = true
	else: push_error("%s not found in dict" % self.name)
	
	collision_shape.set_deferred("disabled", true)
	hitbox.set_deferred("disabled", true)
	%ship_explosion.play()
	
	animation.visible = true
	animation.play("explode")
	await animation.animation_finished
	
	queue_free()


func take_damage(damage:float, hit_pos: Vector2) -> void:
	hp_current -= damage
	
	Utility.createDamageIndicator(damage, Utility.damage_red, hit_pos)
	
	if hp_current <= 0 and alive:
		explode()
