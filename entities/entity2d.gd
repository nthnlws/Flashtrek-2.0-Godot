# --- Class ---
class_name Entity2D
# --- Extends ---
extends RigidBody2D

# --- Siganls ---

# --- ENUMS ---

# --- Constants ---

# --- Exported Variables ---

# --- Public Variables ---

# --- Private Variables ---
# number of hit points the entity has. Default value is 10 but this can be over ridden.
var hp: int = 10
# --- Onready Variables ---

# --- Virtual _init method ---

# --- Virtual _ready method ---

# --- Virtual methods ---


# --- Public methods ---
# Apply damage to the entity. DO NOT OVERRIDE.
func take_damage(value: int = 1) -> void:
	# Reduce hp by the passed in ammount
	hp -= value
	damage_taken()
	# if the hp goes below 0, the entity is destroyed.
	if hp <= 0:
		entity_destroyed()


# Function for specific behaviour on taking damage. Overridable.
func damage_taken() -> void:
	pass


# Function to hold specific behaviour for entity destruction. Overridable.
func entity_destroyed() -> void:
	# defaults to removing the entity.
	queue_free()
# --- Private methods ---

# --- SetGet functions ---
