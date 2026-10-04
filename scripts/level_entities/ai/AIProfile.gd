## NPC combat behaviour. Does not affect ship stats.
class_name AIProfile
extends Resource

enum Style {
	STANDOFF,   ## Close to preferred_range and hold
	ORBIT,      ## Circle at preferred_range facing the target
	KITE,       ## Back off when the target closes in
	ATTACK_RUN, ## Charge, overshoot, turn back
	SIEGE,      ## Slow long-range standoff
}

@export var style: Style = Style.STANDOFF
@export var preferred_range: float = 1000.0
@export var combat_speed_mult: float = 1.0
@export var retreat_hull_fraction: float = 0.25
@export var rejoin_hull_fraction: float = 0.7


static func for_archetype(archetype: Scaling.ARCHETYPE) -> AIProfile:
	var profile: AIProfile = AIProfile.new()
	match archetype:
		Scaling.ARCHETYPE.ESCORT:
			profile.style = Style.ORBIT
			profile.preferred_range = 900.0
			profile.combat_speed_mult = 0.9
		Scaling.ARCHETYPE.SCIENCE:
			profile.style = Style.KITE
			profile.preferred_range = 1600.0
			profile.retreat_hull_fraction = 0.35
		Scaling.ARCHETYPE.FREIGHTER:
			profile.style = Style.KITE
			profile.preferred_range = 1400.0
			profile.retreat_hull_fraction = 0.5
		Scaling.ARCHETYPE.RAIDER:
			profile.style = Style.ATTACK_RUN
			profile.preferred_range = 350.0
			profile.combat_speed_mult = 1.2
			profile.retreat_hull_fraction = 0.3
		Scaling.ARCHETYPE.DREADNOUGHT:
			profile.style = Style.SIEGE
			profile.preferred_range = 1500.0
			profile.combat_speed_mult = 0.6
			profile.retreat_hull_fraction = 0.15
		_: # CRUISER / NONE
			profile.style = Style.STANDOFF
			profile.preferred_range = 1000.0
	return profile
