# --- Class ---
class_name Projectile2D

# --- Extends ---
extends RigidBody2D

# --- Siganls ---

# --- ENUMS ---

# --- Constants ---
const IMPULSE_FACTOR = 1000
const MAX_RADIUS = 12
const POINTS = 18
const PROJECTILE_MASS = 0.1
const NUMBER_OF_CONTACTS = 1
const SPARKS = preload("res://effects/bullet_sparks.tscn")
# --- Exported Variables ---

# --- Public Variables ---

# --- Private Variables ---
var direction = Vector2.UP setget set_direction
var can_bounce: bool = false setget set_can_bounce
var bounce_number: int = 0

# --- Onready Variables ---


# --- Virtual _init method ---
func _init(radius: int = MAX_RADIUS, parent: Node = self, color: Color = Color.white) -> void:
	# configure physics
	set_physics_properties()
	# draw the polygon
	set_drawn_shape(radius, color)
	# add a collision shape
	set_collision_shape(radius)
	# visibility notifier for going off screen
	add_visibility_notifier()
	# enable collisions
	add_collisions(parent)


# --- Virtual _ready method ---
func _ready() -> void:
	var start_impulse: Vector2 = direction * IMPULSE_FACTOR
	apply_central_impulse(start_impulse)


# --- Virtual methods ---
func _integrate_forces(state):
	for i in state.get_contact_count():
		# Otherwise we get sparks when projectiles bounce off the screen edges
		# or off each other.
		if state.get_contact_collider_object(i).has_method("take_damage"):
			Sparks.emit_from_collision(state, i, SPARKS, get_parent())


# --- Public methods ---
# defines the physics properites of the projectile
func set_physics_properties() -> void:
	var PhysicsMaterial = preload("res://entities/projectile_physics_material.tres")
	set_physics_material_override(PhysicsMaterial)
	set_mass(PROJECTILE_MASS)
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	set_max_contacts_reported(NUMBER_OF_CONTACTS)
	set_contact_monitor(true)
	set_linear_damp(0)
	set_angular_damp(0)


# Set the visible shape of a new projectile
func set_drawn_shape(radius: int, color: Color) -> void:
	var polygon = Polygon2D.new()
	# particles will be a circle
	var outline: PoolVector2Array = []
	outline.resize(POINTS)
	for i in POINTS:
		var angle: float = PI * 2 * i / POINTS
		outline[i] = Vector2.UP.rotated(angle) * radius
	polygon.set_polygon(outline)
	polygon.set_color(color)
	add_child(polygon)


# Set the hitbox for a new projectile
func set_collision_shape(radius: int) -> void:
	# projectiles will use a circle shape for their hitbox.
	var owner: int = create_shape_owner(self)
	var shape = CircleShape2D.new()
	shape.set_radius(radius)
	shape_owner_add_shape(owner, shape)


func add_collisions(parent: Node) -> void:
	set_contact_monitor(true)
	set_max_contacts_reported(1)
	if parent:
		add_collision_exception_with(parent)
	#connect signals
	connect("body_entered", self, "_on_body_entered")


func add_visibility_notifier() -> void:
	var rect = Rect2(-2, -2, 4, 4)
	var vis = VisibilityNotifier2D.new()
	vis.set_rect(rect)
	add_child(vis)
	vis.connect("screen_exited", self, "_on_screen_exited")


# --- Private methods ---
func _on_body_entered(body: Node) -> void:
	# damge entities
	if body.has_method("take_damage"):
		body.take_damage()
		queue_free()
	# for bouncing bullets, reduce the bounce count and delete when depleted.
	bounce_number -= 1
	if bounce_number < 0:
		queue_free()


func _on_screen_exited() -> void:
	queue_free()


# --- SetGet functions ---
func set_direction(value: Vector2 = Vector2.UP) -> void:
	direction = value


func set_can_bounce(value: bool = false) -> void:
	can_bounce = value
	if can_bounce:
		set_collision_layer_bit(1, true)
		set_collision_mask_bit(1, true)
		bounce_number = 3
