# --- Class ---
class_name UFO

# --- Extends ---
extends Ship2D

# --- Siganls ---

# --- ENUMS ---

# --- Constants ---
const THRUST_IMPULSE_FACTOR = 20.0
const UFO_POJECTILE_COLOR: Color = Color(0.58, 0.13, 0.42, 1)
const CANNON_COOLDOWN_NORMAL: float = 2.0
const CANNON_COOLDOWN_BOUNCING: float = 0.5
const BOUNCING_BULLET_TIME: float = 5.0
# --- Exported Variables ---

# --- Public Variables ---
var player: Node

# --- Private Variables ---

# --- Onready Variables ---

# --- Virtual _init method ---


# --- Virtual _ready method ---
func _ready() -> void:
	add_to_group("enemy")


# --- Virtual methods ---
func _physics_process(delta: float) -> void:
	var thrust_impulse: Vector2

	if player:
		thrust_impulse = global_position.direction_to(player.get_global_position())
		if $ShootTimer.is_stopped() && $VisibilityNotifier2D.is_on_screen():
			_shoot()
	else:
		thrust_impulse = global_position.direction_to(Vector2.ZERO)

	$Shapes.rotation += delta

	apply_central_impulse(thrust_impulse * THRUST_IMPULSE_FACTOR)


# --- Public methods ---
func apply_bouncing_bullet_powerup() -> void:
	set_bouncing_bullets_active(true)
	$BouncingBulletTimer.start(BOUNCING_BULLET_TIME)


func entity_destroyed() -> void:
	EventBus.emit_signal("ufo_destroyed", 100)
	.entity_destroyed()


# --- Private methods ---
func _shoot() -> void:
	_fire_projectile(
		get_global_position(),
		global_position.direction_to(player.get_global_position()),
		self,
		$ProjectileContainer,
		UFO_POJECTILE_COLOR
	)
	var shoot_cooldown: float = (
		CANNON_COOLDOWN_BOUNCING
		if bouncing_bullets_active
		else CANNON_COOLDOWN_NORMAL
	)
	$ShootTimer.start(shoot_cooldown)


func _on_PlayerSensor_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("detected player!!!")
		player = body


func _on_BouncingBulletTimer_timeout() -> void:
	set_bouncing_bullets_active(false)

# --- SetGet functions ---
