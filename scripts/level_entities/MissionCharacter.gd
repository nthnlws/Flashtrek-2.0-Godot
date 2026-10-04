extends FactionCharacter
class_name MissionCharacter

enum Role {
	HUNTER,   ## Faction AI, always hostile to the player
	ESCORTED, ## Passive; follows `route` while the player is within escort_leash
	DISABLED, ## Passive; can be towed by the tractor beam
	ATTACKER, ## Assaults `objective_node` when nothing scores higher
}

## Low enough that threat from the player can outscore the objective.
const OBJECTIVE_TARGET_BONUS: float = 0.3

## Must be set before entering the tree.
var role: Role = Role.HUNTER
var hostile_to_player: bool = true

var objective_node: Node2D


func _ready() -> void:
	super()
	if _is_passive():
		hostile_to_player = false
	# Deferred so spawners can set role-specific fields (e.g. objective_node) first
	_enter_idle_state.call_deferred()


func _enter_idle_state() -> void:
	movement.change_state(_idle_state())


func explode(hit_event:HitEvent = HitEvent.new()) -> void:
	shield.turnShieldOff()
	sprite.visible = false
	_set_engaged_player(false)

	SignalBus.missionCharacterDied.emit(self)

	collision_shape.set_deferred("disabled", true)
	%ship_explosion.play()

	animation.visible = true
	animation.play("explode")
	await animation.animation_finished

	queue_free()


# --- Role behaviour ---

func _is_passive() -> bool:
	return role == Role.ESCORTED or role == Role.DISABLED


func _idle_state() -> ShipMovementComponent.State:
	match role:
		Role.ESCORTED:
			return AIState.FOLLOW_ROUTE
		Role.DISABLED:
			return AIState.DISABLED
		Role.ATTACKER:
			return AIState.INVESTIGATE if is_instance_valid(objective_node) else AIState.PATROL
		_:
			return super()


func _on_movement_state_changed(previous: ShipMovementComponent.State, current: ShipMovementComponent.State) -> void:
	if current == AIState.INVESTIGATE and role == Role.ATTACKER and is_instance_valid(objective_node):
		movement.investigate_position = objective_node.global_position
	super(previous, current)


func _think() -> void:
	if _is_passive():
		return
	super()


func _can_retreat() -> bool:
	return role == Role.HUNTER


func _is_hostile_to_player() -> bool:
	if _is_passive():
		return false
	return hostile_to_player or super()


func _gather_candidates() -> Array[Node2D]:
	var candidates: Array[Node2D] = super()
	if role == Role.ATTACKER and _is_targetable(objective_node) and not candidates.has(objective_node):
		candidates.append(objective_node)
	return candidates


func _target_bonus(target: Node2D) -> float:
	return OBJECTIVE_TARGET_BONUS if target == objective_node else 0.0


func _on_hit_received(shooter: Node) -> void:
	if _is_passive():
		var attacker: Node2D = shooter as Node2D
		if is_instance_valid(attacker) and not _is_friendly_fire(attacker):
			_emit_distress(attacker)
		return
	super(shooter)


# --- Towing ---

## Tractor beam tow interface.
func can_be_towed() -> bool:
	return role == Role.DISABLED and health_component.alive
