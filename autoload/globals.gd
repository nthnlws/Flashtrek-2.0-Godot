# --- Class ---

# --- Extends ---
extends Node

# --- Siganls ---

# --- ENUMS ---

# --- Constants ---
const PROJECTILE_OUTLINE_POINTS = 18

# --- Exported Variables ---

# --- Public Variables ---
var projectile_outline: PoolVector2Array = []

# --- Private Variables ---

# --- Onready Variables ---


# --- Virtual _init method ---
func _init() -> void:
	_set_projectile_outline()


# --- Virtual _ready method ---

# --- Virtual methods ---

# --- Public methods ---

# --- Private methods ---


# --- SetGet functions ---
# private setter for projectile outline
func _set_projectile_outline() -> void:
	var outline: PoolVector2Array = []
	projectile_outline.resize(PROJECTILE_OUTLINE_POINTS)
	for i in PROJECTILE_OUTLINE_POINTS:
		var angle: float = PI * 2 * i / PROJECTILE_OUTLINE_POINTS
		projectile_outline[i] = Vector2.UP.rotated(angle)


func get_projectile_outline() -> PoolVector2Array:
	return projectile_outline
