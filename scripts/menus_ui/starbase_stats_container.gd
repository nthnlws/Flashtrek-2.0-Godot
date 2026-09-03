extends VBoxContainer


func update_ship_stats(selected_ship: ShipCardButton) -> void:
	var ship_info: ShipState = selected_ship.ship_info
	var faction: Utility.FACTION = ship_info.current_faction
	var factionRanges: FactionRanges = Utility.get_faction_stat_ranges(faction)

	# Existing stat bars unchanged
	_set_stat_bar(%HealthBar,   ship_info.scaled_max_HP, factionRanges.max_hp_MIN, factionRanges.max_hp_MAX)
	_set_stat_bar(%ShieldBar,   ship_info.scaled_max_shield, factionRanges.max_shield_MIN, factionRanges.max_shield_MAX)
	_set_stat_bar(%SpeedBar,    ship_info.scaled_speed, factionRanges.speed_MIN, factionRanges.speed_MAX)
	_set_stat_bar(%MovementBar, ship_info.scaled_agility, factionRanges.agility_MIN, factionRanges.agility_MAX)
	_set_stat_bar(%DamageBar,   ship_info.scaled_damage_mult, factionRanges.damage_MIN, factionRanges.damage_MAX)

	var formatted_name: String = Utility.fed_blue + Utility.SHIP_TYPES.keys()[ship_info.ship_type].replace("_", " ").capitalize()
	%ship_name.text = "[color=#FFCC66]Ship Name:[/color] %s" % formatted_name


func _set_stat_bar(bar: Control, value: float, min_range: float, max_range: float, min_fill: float = 0.2, contrast: float = 0.6) -> void:
	if max_range <= min_range:
		bar.set_progress(min_fill * 100.0)
		return
		
	var t: float       = clampf((value - min_range) / (max_range - min_range), 0.0, 1.0)
	var curved: float  = pow(t, contrast)
	var display: float = lerpf(min_fill, 1.0, curved)
	
	bar.set_progress(display * 100.0)
