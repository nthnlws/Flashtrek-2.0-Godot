extends RefCounted
class_name ShipPartTradeoffs
## Shared keys for the `tradeoffs` dictionary on secondary-slot parts.
## Always use these constants instead of raw strings so a typo fails loudly
## instead of silently returning the 1.0 default.
## Values are multipliers: 1.0 = no change, 0.8 = -20 %, 1.25 = +25 %.

# Read every frame by the player (movement)
const AGILITY_MULT: String = "agility_mult"
const SPEED_MULT: String = "speed_mult"
const ACCEL_MULT: String = "accel_mult"

# Cached values, updated when SecondarySlot.tradeoffs_changed fires
const MAX_ENERGY_MULT: String = "max_energy_mult"   # EnergyComponent
const MAX_HULL_MULT: String = "max_hull_mult"       # HealthComponent
const MAX_SHIELD_MULT: String = "max_shield_mult"   # HealthComponent
const FIRE_RATE_MULT: String = "fire_rate_mult"     # PrimarySlot -> primary weapon
