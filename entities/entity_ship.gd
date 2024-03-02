# --- Class ---
class_name Ship2D

# --- Extends ---
extends Entity2D

# --- Siganls ---

# --- ENUMS ---

# --- Constants ---
const MAX_HP: int = 10
const BOUNCING_PROJECTILE_COLOR: Color = Color(1.0, 0.52, 0.15, 1)
const SPRAY: float = 0.1
# --- Exported Variables ---
export var projectile_radius: int = 12
# --- Public Variables ---
var bouncing_bullets_active: bool = false setget set_bouncing_bullets_active
# --- Private Variables ---

# --- Onready Variables ---

# --- Virtual _init method ---

# --- Virtual _ready method ---

# --- Virtual methods ---


# --- Public methods ---
func apply_health_powerup(value: int = 1) -> void:
	# HP can not go over MAX_HP
	# negate the damage to cause HP to increase
	take_damage(-min(MAX_HP - hp, value))


# overrideable
func apply_bouncing_bullet_powerup() -> void:
	set_bouncing_bullets_active(true)


# --- Private methods ---
func _fire_projectile(
	pos: Vector2, dir: Vector2, exception: Node, container: Node, color: Color = Color.white
) -> void:
	var projectile_color: Color = BOUNCING_PROJECTILE_COLOR if bouncing_bullets_active else color
	var p: Projectile2D = Projectile2D.new(projectile_radius, exception, projectile_color)
	p.set_position(pos)
	randomize()
	var rot: float = float(bouncing_bullets_active) * rand_range(-SPRAY, SPRAY)
	p.set_direction(dir.rotated(rot))
	p.set_can_bounce(bouncing_bullets_active)
	container.add_child(p)


# --- SetGet functions ---
func set_bouncing_bullets_active(value: bool) -> void:
	bouncing_bullets_active = value
