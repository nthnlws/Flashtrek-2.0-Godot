extends Node
class_name DamageHandlerComponent

@export var shield: Shield
@export var hull: HullDamageReceiver
@export var health_component: HealthComponent


func _ready() -> void:
	if shield:
		shield.recieved_damage.connect(collect_damage_events)
	if hull:
		hull.recieved_damage.connect(collect_damage_events)


var _is_processing_scheduled: bool = false # Flag to prevent multiple deferred calls
var frame_hit_events:Array[HitEvent] = []
func collect_damage_events(hit_event:HitEvent) -> void:
	if Utility.current_gamestate == Utility.GAMESTATE.WARPING:
		return
	
	frame_hit_events.append(hit_event)
	if not _is_processing_scheduled:
		_is_processing_scheduled = true
		call_deferred("handle_frame_hits")


func handle_frame_hits() -> void:
	var handled_projectiles:Dictionary = {}

	# Loop 1: Prioritize Shield Hits
	for event: HitEvent in frame_hit_events:
		if event.hit_shield and shield.shieldActive:
			health_component.take_shield_damage(event)
			handled_projectiles[event.projectile_ID] = true

	# Loop 2: Process Hull Hits
	for event: HitEvent in frame_hit_events:
		if event.hit_hull:
			# Check if the projectile was already handled by shield
			if handled_projectiles.has(event.projectile_ID):
				continue # Skip, shield already took the hit.

			health_component.take_hull_damage(event)
	
	frame_hit_events.clear()
	_is_processing_scheduled = false
