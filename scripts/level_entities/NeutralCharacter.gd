extends CharacterBody2D
class_name NeutralCharacter

@export var ship_type:Utility.SHIP_TYPES = Utility.SHIP_TYPES.Merchantman
var faction: Utility.FACTION = Utility.FACTION.NEUTRAL
@export var reputation_value: float = 100.0

@onready var sprite: Sprite2D = $Sprite2D  # Reference to the sprite node
@onready var hitbox: CollisionPolygon2D = $hitbox_area/CollisionPolygon2D  # Reference to the CollisionShape2D node
@onready var collision_shape: CollisionPolygon2D = $WorldCollisionShape
@onready var shield: Shield = $Shield
@onready var animation: AnimatedSprite2D = $hull_explosion
@onready var cloak_animation: AnimationPlayer = $Sprite2D/CloakAnimation
@onready var health_component: HealthComponent = $HealthComponent

# Variables for handling dynamic behavior
var move_speed: int = 60
var rotation_rate: float = 1.5

var endPoint: Vector2
var returnToStarbaseBool: bool = false
var moveTarget: MOVE_STATE
enum MOVE_STATE { Starbase, Planet, Coordinates, Enemy }

var AI_enabled:bool = true
var starbase: Node2D  # Path to starbase, only set if AI_enabled is true
var ship_index: int # Used for tying ship to Data resource files

var fleeing: bool = false
var flee_timer: float = 0.0
const FLEE_DURATION: float = 7.2
const FLEE_SPEED_MULTIPLIER: float = 1.5


func _ready() -> void:
	_create_unique_texture_atlas()
	_sync_data_to_resource(ship_type)
	call_deferred("selectRandomPlanet")
	z_index = Utility.Z["NeutralShips"]
	
	starbase = LevelManager.starbases.front()


func _create_unique_texture_atlas() -> void:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/textures/ships/ship_sprites.png")
	atlas_texture.filter_clip = true
	sprite.texture = atlas_texture


func _sync_data_to_resource(ship:Utility.SHIP_TYPES) -> void:
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
	
	move_speed = ship_data.SPEED
	rotation_rate = ship_data.ROTATION_SPEED
	health_component.HP_max = ship_data.MAX_HP
	health_component.SP_max = ship_data.MAX_SHIELD


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

	var adjusted_points:Array = []
	for p in points:
		var centered:Vector2 = Vector2(p.x - center_x, p.y - center_y)
		var shifted:Vector2 = centered + Vector2(1, -4)
		adjusted_points.append(shifted)

	return PackedVector2Array(adjusted_points)


func _set_ship_scale(new_scale: Vector2) -> void:
	shield.scale *= new_scale
	sprite.scale *= new_scale
	$hitbox_area.scale *= new_scale


func _physics_process(delta: float) -> void:
	#TODO Sync Player and Enemy speed stats to be compatible
	if not AI_enabled or not visible or health_component.alive == false:
		return
	
	# Movement state setter
	setMovementState(delta)
	
	move_and_slide()


func setMovementState(delta: float) -> void:
	if fleeing:
		flee_timer -= delta
		if flee_timer <= 0.0:
			fleeing = false
			selectRandomPlanet()
		else:
			move_to_target(endPoint, delta, FLEE_SPEED_MULTIPLIER)
		return

	if global_position.distance_to(starbase.global_position) < 1500 and moveTarget == MOVE_STATE.Starbase:
		returnToStarbaseBool = false
		selectRandomPlanet()
		moveTarget = MOVE_STATE.Planet
	elif returnToStarbaseBool == false:
		planetMovement(delta)
		moveTarget = MOVE_STATE.Planet
	elif returnToStarbaseBool == true:
		starbaseMovement(delta)
		moveTarget = MOVE_STATE.Starbase
	else: print("No matching movement status")


func selectRandomPlanet() -> void:
	endPoint = LevelManager.planets.pick_random().global_position


func starbaseMovement(delta:float) -> void:
	if starbase:
		var starbaseLocation: Vector2 = starbase.global_position
		move_to_target(starbaseLocation, delta)


func planetMovement(delta:float) -> void: 
	move_to_target(endPoint, delta)
	
	if self.global_position.distance_to(endPoint) < 5:
		returnToStarbaseBool = true


func move_to_target(target_pos: Vector2, delta: float, speed_mult: float = 1.0) -> void:
	var to_target: Vector2 = target_pos - global_position
	var angle_diff: float = wrapf(to_target.angle() - global_rotation, -PI, PI)
	var angle_abs: float = absf(angle_diff)
	
	_rotate_toward_target(angle_diff, delta)
	
	var thrust_factor: float = clampf(1.0 - (angle_abs / deg_to_rad(90.0)), 0.0, 1.0)
	var target_velocity: Vector2 = transform.x * move_speed * speed_mult * thrust_factor
	velocity = velocity.move_toward(target_velocity, move_speed * delta * 2.0)


func _rotate_toward_target(angle_diff: float, delta: float) -> void:
	var max_turn: float = deg_to_rad(rotation_rate * delta)
	# Ease off when within 15 degrees of target
	var ease_factor: float = clampf(absf(angle_diff) / deg_to_rad(15.0), 0.0, 1.0)
	rotation += clampf(angle_diff, -max_turn, max_turn) * ease_factor


func explode(hit_event:HitEvent = HitEvent.new()) -> void:
	shield.turnShieldOff()
	sprite.visible = false
	
	SignalBus.neutralShipDied.emit(self)
	if hit_event.is_from_player: # Update reputation if died from player damage
		#print('killed by player')
		SignalBus.reputation_change_triggered.emit(self.faction, self.reputation_value)
	#else: print('not player kill')
	
	collision_shape.set_deferred("disabled", true)
	hitbox.set_deferred("disabled", true)
	%ship_explosion.play()
	
	animation.visible = true
	animation.play("explode")
	await animation.animation_finished
	
	queue_free()


func cloak_ship(length:float) -> void:
	cloak_animation.speed_scale = 2/length
	cloak_animation.play("cloak")

func uncloak_ship(length:float) -> void:
	cloak_animation.speed_scale = 2/length
	cloak_animation.play("uncloak")


func _on_hit_received(shooter: Node) -> void:
	fleeing = true
	flee_timer = FLEE_DURATION
	var flee_direction: Vector2 = (global_position - shooter.global_position).normalized()
	endPoint = global_position + flee_direction * 10000.0
