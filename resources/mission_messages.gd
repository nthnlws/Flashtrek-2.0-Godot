extends Resource
class_name MissionMessage

## Comms lines shown by the faction popup as a mission is accepted, progresses,
## becomes ready for turn-in and completes. Lines are picked by the mission's
## faction_owner, then mission type, then phase; anything missing falls back to
## that faction's GENERIC lines. Neutral missions only use GENERIC lines.
##
## Acceptance (from the issuing planet) and delivery completion (at the target
## planet) are voiced by that planet: its faction picks the lines and portrait,
## and its name is shown as the speaker.
##
## Placeholders: {ship_name} {system} {planet} {cargo} {bounty} {enemy} {remaining}

enum PHASE { ACCEPTED, PROGRESS, READY, COMPLETED }

const COLOR_BASE: String = "#E6E6E6"        # Off-white base
const COLOR_PLAYER_SHIP: String = "#6699CC" # Light Blue
const COLOR_HIGHLIGHT: String = "#FFCC66"   # Gold

const T := MissionData.MISSION_TYPE
const GENERIC: int = -1

static var federation_lines: Dictionary = {
	GENERIC: {
		PHASE.ACCEPTED: [
			"{ship_name}, your orders are logged. Proceed to the {system} system.",
			"{ship_name}, we're counting on you. Set a course for {system} and keep us informed.",
		],
		PHASE.PROGRESS: [
			"Good work, {ship_name}. Keep it up - Starfleet is monitoring your progress.",
			"{ship_name}, telemetry confirms progress. Continue the mission.",
		],
		PHASE.READY: [
			"Objectives complete, {ship_name}. Report to the starbase for debriefing.",
		],
		PHASE.COMPLETED: [
			"Mission accomplished, {ship_name}. Starfleet sends its compliments.",
			"Well done, {ship_name}. This one's going in your service record.",
		],
	},
	T.DELIVERY: {
		PHASE.ACCEPTED: [
			"{ship_name}, the {cargo} is aboard. Deliver it to {planet} in the {system} system.",
			"Cargo secured, {ship_name}. {planet} is expecting that {cargo} - don't keep them waiting.",
		],
		PHASE.COMPLETED: [
			"Delivery confirmed, {ship_name}. The colonists here send their thanks.",
			"The {cargo} arrived intact. Fine work, {ship_name}.",
			"Your delivery has arrived. Starfleet commends your service.",
			"Shipment secured. We appreciate your reliability.",
			"Thank you. The Federation acknowledges your efforts.",
			"Mission complete. Your record has been updated.",
			"Excellent work. Cargo confirmed and logged.",
			"Live long and prosper. The supplies are safe.",
			"Starfleet Command sends their regards for a job well done.",
			"Your assistance has been invaluable to our sector.",
		],
	},
	T.CONTAINER: {
		PHASE.ACCEPTED: [
			"{ship_name}, a supply container is adrift in the {system} system. Recover it with your tractor beam.",
			"Starfleet needs that container back, {ship_name}. Head to {system} and bring it in.",
		],
		PHASE.COMPLETED: [
			"Container recovered, {ship_name}. Those supplies will save lives.",
			"Cargo secured. Nicely done, {ship_name}.",
		],
	},
	T.KILL_FACTION: {
		PHASE.ACCEPTED: [
			"{ship_name}, {enemy} raiders are harassing the {system} system. Neutralize them.",
			"Red alert, {ship_name}. Drive the {enemy} forces out of {system}. Minimize casualties where you can.",
		],
		PHASE.PROGRESS: [
			"Target disabled, {ship_name}. {remaining} hostiles still in the area.",
			"Scratch one. Sensors read {remaining} {enemy} ships remaining, {ship_name}.",
		],
		PHASE.COMPLETED: [
			"The {system} system is secure. Starfleet thanks you, {ship_name}.",
			"All hostiles neutralized. Stand down, {ship_name} - outstanding work.",
		],
	},
	T.ESCORT: {
		PHASE.ACCEPTED: [
			"{ship_name}, a VIP transport awaits you in {system}. Stay close and keep it safe.",
			"The transport won't move without an escort, {ship_name}. Get to {system} and watch for {enemy} ambushes.",
		],
		PHASE.COMPLETED: [
			"The transport reached its destination. Our guests are grateful, {ship_name}.",
			"Escort complete, {ship_name}. Not a scratch on them - well flown.",
		],
	},
	T.ANALYZE: {
		PHASE.ACCEPTED: [
			"{ship_name}, the Science Directorate wants a full scan of {planet} in the {system} system.",
			"Orbit {planet} and run a planetary survey, {ship_name}. The data could be significant.",
		],
		PHASE.COMPLETED: [
			"Scan data received, {ship_name}. The science teams are already arguing over it.",
			"Survey of {planet} complete. Fascinating readings, {ship_name}.",
		],
	},
	T.SALVAGE: {
		PHASE.ACCEPTED: [
			"{ship_name}, a debris field in {system} holds recoverable components. Haul them in with your tractor beam.",
			"Engineering needs parts, {ship_name}. Recover the marked salvage in the {system} system.",
		],
		PHASE.PROGRESS: [
			"Salvage secured, {ship_name}. {remaining} more components still marked.",
			"Good catch. Sensors show {remaining} recoverable pieces left, {ship_name}.",
		],
		PHASE.READY: [
			"Cargo hold's full of salvage, {ship_name}. Return to the starbase and open a channel to offload.",
			"That's the last of it, {ship_name}. Bring the salvage to the starbase and hail us.",
		],
		PHASE.COMPLETED: [
			"Salvage offloaded, {ship_name}. Our engineers will have those parts in service by morning.",
			"Transfer complete. We'll clear the rest of the debris field, {ship_name}. Well done.",
		],
	},
	T.RESCUE: {
		PHASE.ACCEPTED: [
			"{ship_name}, we're receiving a distress call from {system}. Tow the disabled ship to the starbase.",
			"Lives are at stake, {ship_name}. Get to {system} and bring that crippled ship home.",
		],
		PHASE.PROGRESS: [
			"We see the beacon, {ship_name}. Lock your tractor beam and tow them to the starbase.",
		],
		PHASE.COMPLETED: [
			"The crew is safe aboard the starbase. You saved lives today, {ship_name}.",
			"Rescue complete. Medical teams are standing by. Thank you, {ship_name}.",
		],
	},
	T.BOUNTY: {
		PHASE.ACCEPTED: [
			"{ship_name}, the fugitive {bounty} was last seen in {system}. Bring them to justice.",
			"Starfleet Security wants {bounty} stopped, {ship_name}. Last known location: {system}.",
		],
		PHASE.PROGRESS: [
			"Intelligence update, {ship_name}: {bounty} has fled to the {system} system.",
			"{bounty} is on the move. Latest sighting puts them in {system}, {ship_name}.",
		],
		PHASE.COMPLETED: [
			"{bounty} is no longer a threat. Justice is served, {ship_name}.",
			"Starfleet Security confirms it: {bounty} is finished. Good hunting, {ship_name}.",
		],
	},
	T.SENSOR_SWEEP: {
		PHASE.ACCEPTED: [
			"{ship_name}, calibrate the sensor buoys in {system} before the survey window closes.",
			"Stellar Cartography needs those buoys calibrated in {system}, {ship_name}. The clock is ticking.",
		],
		PHASE.PROGRESS: [
			"Buoy online, {ship_name}. {remaining} left to calibrate.",
			"Clean calibration. {remaining} buoys remaining, {ship_name}.",
		],
		PHASE.COMPLETED: [
			"Sensor network online. Stellar Cartography thanks you, {ship_name}.",
			"All buoys calibrated with time to spare. Nicely done, {ship_name}.",
		],
	},
	T.DEFENSE: {
		PHASE.ACCEPTED: [
			"{ship_name}, {enemy} forces are massing on the {system} starbase. Hold the line.",
			"The {system} starbase needs every ship it can get, {ship_name}. Defend it at all costs.",
		],
		PHASE.PROGRESS: [
			"Wave repelled, {ship_name}. Brace yourself - {remaining} more expected.",
			"Shields holding. {remaining} attack waves still inbound, {ship_name}.",
		],
		PHASE.COMPLETED: [
			"The starbase stands. Everyone aboard owes you, {ship_name}.",
			"{enemy} forces are in retreat. Outstanding defense, {ship_name}.",
		],
	},
	T.CONTRABAND: {
		PHASE.ACCEPTED: [
			"{ship_name}, this is off the record. Get the {cargo} to {planet} and avoid {enemy} patrols.",
			"Discretion is vital, {ship_name}. {planet} needs that {cargo} - don't get scanned.",
		],
		PHASE.COMPLETED: [
			"Package received. As far as Starfleet is concerned, this never happened, {ship_name}.",
			"Receipt confirmed. Quietly done, {ship_name}.",
		],
	},
}

static var klingon_lines: Dictionary = {
	GENERIC: {
		PHASE.ACCEPTED: [
			"{ship_name}! You have your orders. Go to {system} and do not return in shame!",
			"The Empire has spoken, {ship_name}. Make for {system} and bring glory to the House.",
		],
		PHASE.PROGRESS: [
			"You fight well, {ship_name}. Do not grow careless now!",
			"Progress, {ship_name}. Continue - the Empire is watching.",
		],
		PHASE.READY: [
			"It is done, {ship_name}. Return to the starbase and report!",
		],
		PHASE.COMPLETED: [
			"Qapla', {ship_name}! Tonight we drink bloodwine in your honor!",
			"Your deeds are worthy, {ship_name}. The Empire remembers.",
		],
	},
	T.DELIVERY: {
		PHASE.ACCEPTED: [
			"{ship_name}, deliver this {cargo} to {planet} in {system}. Do not lose it, or lose your head.",
			"The warriors on {planet} await the {cargo}. Fly swiftly, {ship_name}!",
		],
		PHASE.COMPLETED: [
			"We have our {cargo}. You have done a warrior's errand well, {ship_name}.",
			"The {cargo} arrived. A small task, but done with honor, {ship_name}.",
			"The cargo is delivered. You have done honor to this task.",
			"Your duty is fulfilled. Qapla’!",
			"Well fought. The shipment has arrived intact.",
			"You have earned your reward in glory and goods.",
			"Delivery made. Strength is proven through action.",
			"Today is a good day to deliver! Qapla’!",
			"The High Council acknowledges your worth.",
			"A warrior's task, completed with honor.",
		],
	},
	T.CONTAINER: {
		PHASE.ACCEPTED: [
			"A container of ours drifts in {system}, {ship_name}. Take it back before scavengers do!",
			"{ship_name}! Recover the lost container in {system}. It belongs to the Empire.",
		],
		PHASE.COMPLETED: [
			"The container is ours again. Good, {ship_name}.",
			"You reclaimed what was ours, {ship_name}. Honor is restored.",
		],
	},
	T.KILL_FACTION: {
		PHASE.ACCEPTED: [
			"{enemy} dogs infest {system}, {ship_name}! Hunt them down and show no mercy!",
			"Today is a good day to die - for {enemy} ships! Go to {system} and destroy them, {ship_name}!",
		],
		PHASE.PROGRESS: [
			"Ha! Another falls! {remaining} {enemy} cowards remain, {ship_name}!",
			"Their blood boils in space! Only {remaining} left - finish them, {ship_name}!",
		],
		PHASE.COMPLETED: [
			"The {enemy} are broken! Songs will be sung of this battle, {ship_name}!",
			"{system} is cleansed of vermin. Qapla', {ship_name}!",
		],
	},
	T.ESCORT: {
		PHASE.ACCEPTED: [
			"A transport requires your protection in {system}, {ship_name}. Guard it as you would your own House.",
			"{ship_name}, escort our transport through {system}. If {enemy} ships attack, crush them.",
		],
		PHASE.COMPLETED: [
			"The transport arrived unharmed. You are a worthy shield, {ship_name}.",
			"Escort complete. Our passengers live because of you, {ship_name}.",
		],
	},
	T.ANALYZE: {
		PHASE.ACCEPTED: [
			"Our scientists demand a scan of {planet} in {system}. Do it quickly, {ship_name}.",
			"{ship_name}, scan {planet}. Even warriors must know the ground they fight upon.",
		],
		PHASE.COMPLETED: [
			"The scan is complete. The scientists are pleased. Rare, {ship_name}.",
			"We have the data from {planet}. Good, now return to real work, {ship_name}.",
		],
	},
	T.SALVAGE: {
		PHASE.ACCEPTED: [
			"A wreck field in {system} holds usable parts, {ship_name}. Seize them with your tractor beam!",
			"Our engineers need scrap, {ship_name}. Pick the bones of the wreckage in {system}.",
		],
		PHASE.PROGRESS: [
			"Good! {remaining} more pieces to haul, {ship_name}. Keep your beam steady!",
			"Another prize taken. {remaining} left in that graveyard, {ship_name}.",
		],
		PHASE.READY: [
			"Your hold is full of spoils, {ship_name}! Bring them to the starbase and hail us!",
			"The salvage is yours. Return to the starbase and open a channel, {ship_name}!",
		],
		PHASE.COMPLETED: [
			"The spoils are unloaded! The rest of that junk will be melted down. Qapla', {ship_name}!",
			"Our forges will put these parts to use. You have done well, {ship_name}.",
		],
	},
	T.RESCUE: {
		PHASE.ACCEPTED: [
			"Warriors lie adrift in {system}, {ship_name}. No Klingon is left behind - bring them home!",
			"{ship_name}! A crippled ship calls for aid in {system}. Tow it to the starbase!",
		],
		PHASE.PROGRESS: [
			"We see their beacon! Seize them with your tractor beam and drag them home, {ship_name}!",
		],
		PHASE.COMPLETED: [
			"Our warriors live to fight again. The House owes you a debt, {ship_name}.",
			"They are home. You have honor, {ship_name}.",
		],
	},
	T.BOUNTY: {
		PHASE.ACCEPTED: [
			"The dishonored {bounty} hides in {system}. Hunt them, {ship_name}!",
			"{bounty} has shamed the Empire. Find them in {system} and end them, {ship_name}!",
		],
		PHASE.PROGRESS: [
			"The coward {bounty} flees to {system}! After them, {ship_name}!",
			"{bounty} runs like a targ! Our spies say {system}, {ship_name}.",
		],
		PHASE.COMPLETED: [
			"{bounty} is dead! A fine hunt, {ship_name}!",
			"The dishonored one is no more. The Empire rewards you, {ship_name}.",
		],
	},
	T.SENSOR_SWEEP: {
		PHASE.ACCEPTED: [
			"{ship_name}, calibrate the buoys in {system}. Quickly - the window will not wait for you.",
			"Our fleet needs eyes in {system}. Calibrate those sensor buoys, {ship_name}!",
		],
		PHASE.PROGRESS: [
			"Buoy calibrated. {remaining} remain - faster, {ship_name}!",
			"One more online. {remaining} to go, {ship_name}. Do not dawdle!",
		],
		PHASE.COMPLETED: [
			"Our fleet sees all in {system} now. Well done, {ship_name}.",
			"The sensor net is complete. Nothing will hide from us, {ship_name}.",
		],
	},
	T.DEFENSE: {
		PHASE.ACCEPTED: [
			"{enemy} fools dare attack our starbase in {system}! Stand with us, {ship_name}!",
			"The starbase in {system} is under threat, {ship_name}. We will make them bleed!",
		],
		PHASE.PROGRESS: [
			"They break upon our guns! {remaining} waves remain, {ship_name}!",
			"A glorious slaughter! Ready yourself - {remaining} more waves come, {ship_name}!",
		],
		PHASE.COMPLETED: [
			"The {enemy} flee in disgrace! A great victory, {ship_name}!",
			"The starbase stands! This battle will be remembered, {ship_name}!",
		],
	},
	T.CONTRABAND: {
		PHASE.ACCEPTED: [
			"{ship_name}, carry this {cargo} to {planet}. If {enemy} patrols ask, you know nothing.",
			"Get the {cargo} to {planet}, {ship_name}. Let no {enemy} ship scan your hold.",
		],
		PHASE.COMPLETED: [
			"We have the goods. Cunning as well as brave, {ship_name}.",
			"The {cargo} is delivered. Speak of this to no one, {ship_name}.",
		],
	},
}

static var romulan_lines: Dictionary = {
	GENERIC: {
		PHASE.ACCEPTED: [
			"{ship_name}, your task is sanctioned. Proceed to {system}. Do not disappoint the Empire.",
			"The Tal Shiar will be watching, {ship_name}. Make for the {system} system.",
		],
		PHASE.PROGRESS: [
			"Adequate progress, {ship_name}. Continue.",
			"We are observing, {ship_name}. Proceed as planned.",
		],
		PHASE.READY: [
			"Your task is complete. Report to the starbase, {ship_name}.",
		],
		PHASE.COMPLETED: [
			"Your service has been noted, {ship_name}. The Empire is... satisfied.",
			"Efficiently done, {ship_name}. You may yet prove useful.",
		],
	},
	T.DELIVERY: {
		PHASE.ACCEPTED: [
			"{ship_name}, deliver this {cargo} to {planet} in {system}. Ask no questions.",
			"The {cargo} is expected on {planet}, {ship_name}. Punctuality is appreciated.",
		],
		PHASE.COMPLETED: [
			"We have received the {cargo}. Acceptable, {ship_name}.",
			"Delivery confirmed. Your discretion has been noted, {ship_name}.",
			"Your task is complete. Your efficiency has been noted.",
			"Delivery received. The Empire is satisfied.",
			"You’ve served the mission well—for now.",
			"Shipment secured. Your discretion is appreciated.",
			"Another successful operation. You may continue.",
			"The Tal Shiar commends your silence on this matter.",
			"Do not let success breed arrogance. The Praetor thanks you.",
			"A profitable exchange. Jolan tru.",
		],
	},
	T.CONTAINER: {
		PHASE.ACCEPTED: [
			"An Imperial container drifts in {system}, {ship_name}. Recover it before others take interest.",
			"{ship_name}, retrieve our container in {system}. Its contents are not your concern.",
		],
		PHASE.COMPLETED: [
			"The container is secure. Its contents remain... private. Well done, {ship_name}.",
			"Recovered intact. The Empire appreciates your restraint, {ship_name}.",
		],
	},
	T.KILL_FACTION: {
		PHASE.ACCEPTED: [
			"{enemy} vessels trespass in {system}, {ship_name}. Remove them.",
			"{ship_name}, eliminate the {enemy} presence in {system}. Leave no witnesses.",
		],
		PHASE.PROGRESS: [
			"One fewer {enemy} ship. {remaining} remain, {ship_name}.",
			"Efficient. {remaining} targets remain, {ship_name}.",
		],
		PHASE.COMPLETED: [
			"{system} is cleansed. The Praetor will hear of this, {ship_name}.",
			"The {enemy} have been dealt with. Precisely as planned, {ship_name}.",
		],
	},
	T.ESCORT: {
		PHASE.ACCEPTED: [
			"A transport of some importance awaits in {system}, {ship_name}. Ensure it arrives.",
			"{ship_name}, escort our transport through {system}. Its passengers must not be harmed.",
		],
		PHASE.COMPLETED: [
			"The transport has arrived. Its passengers were never here, {ship_name}.",
			"Escort complete. Your competence is noted, {ship_name}.",
		],
	},
	T.ANALYZE: {
		PHASE.ACCEPTED: [
			"{ship_name}, perform a full scan of {planet} in {system}. Transmit everything.",
			"We require data on {planet}, {ship_name}. The reasons are classified.",
		],
		PHASE.COMPLETED: [
			"Scan data received. It will be put to... good use, {ship_name}.",
			"The survey of {planet} is complete. You saw nothing unusual, {ship_name}.",
		],
	},
	T.SALVAGE: {
		PHASE.ACCEPTED: [
			"A debris field in {system} contains components of interest, {ship_name}. Recover them discreetly.",
			"{ship_name}, the wreckage in {system} holds valuable technology. Retrieve the marked pieces.",
		],
		PHASE.PROGRESS: [
			"Component secured. {remaining} remain, {ship_name}.",
			"Acceptable. {remaining} more pieces to recover, {ship_name}.",
		],
		PHASE.READY: [
			"All components recovered. Return to the starbase and open a secure channel, {ship_name}.",
			"You have what we need. Bring it to the starbase and hail us, {ship_name}.",
		],
		PHASE.COMPLETED: [
			"The components are ours. We will dispose of the remaining wreckage, {ship_name}.",
			"Transfer complete. The debris field will be... sanitized. Well done, {ship_name}.",
		],
	},
	T.RESCUE: {
		PHASE.ACCEPTED: [
			"A disabled vessel in {system} carries sensitive cargo, {ship_name}. Tow it to the starbase.",
			"{ship_name}, a crippled ship drifts in {system}. The Empire wants it back. Tow it home.",
		],
		PHASE.PROGRESS: [
			"Beacon located. Secure the vessel with your tractor beam, {ship_name}.",
		],
		PHASE.COMPLETED: [
			"The vessel is recovered. Its crew will be... debriefed. Thank you, {ship_name}.",
			"Rescue complete. The Empire does not forget a favor, {ship_name}.",
		],
	},
	T.BOUNTY: {
		PHASE.ACCEPTED: [
			"The traitor {bounty} was last seen in {system}, {ship_name}. End them.",
			"{bounty} knows too much, {ship_name}. Find them in {system}.",
		],
		PHASE.PROGRESS: [
			"Tal Shiar intelligence places {bounty} in {system} now, {ship_name}.",
			"{bounty} has slipped away to {system}. Pursue, {ship_name}.",
		],
		PHASE.COMPLETED: [
			"{bounty} has been silenced. The Tal Shiar is pleased, {ship_name}.",
			"The traitor is gone. As is any record of this task, {ship_name}.",
		],
	},
	T.SENSOR_SWEEP: {
		PHASE.ACCEPTED: [
			"{ship_name}, calibrate the sensor buoys in {system}. The window is brief.",
			"We require eyes in {system}, {ship_name}. Calibrate the buoys before time expires.",
		],
		PHASE.PROGRESS: [
			"Buoy calibrated. {remaining} remain, {ship_name}.",
			"Signal clean. {remaining} buoys left, {ship_name}. Do not linger.",
		],
		PHASE.COMPLETED: [
			"The network is active. Nothing in {system} escapes our notice now, {ship_name}.",
			"Calibration complete. The Empire sees further today, {ship_name}.",
		],
	},
	T.DEFENSE: {
		PHASE.ACCEPTED: [
			"{enemy} forces move against our starbase in {system}, {ship_name}. Repel them.",
			"{ship_name}, the starbase in {system} must not fall. Defend it.",
		],
		PHASE.PROGRESS: [
			"Wave repelled. {remaining} remain, {ship_name}. Hold position.",
			"The {enemy} regroup. Expect {remaining} more waves, {ship_name}.",
		],
		PHASE.COMPLETED: [
			"The {enemy} have withdrawn. The starbase endures, {ship_name}.",
			"Defense successful. The Senate will be informed, {ship_name}.",
		],
	},
	T.CONTRABAND: {
		PHASE.ACCEPTED: [
			"{ship_name}, take the {cargo} to {planet}. {enemy} patrols must not scan your hold.",
			"This {cargo} does not exist, {ship_name}. Deliver it to {planet} unseen.",
		],
		PHASE.COMPLETED: [
			"Receipt confirmed. You were never here, {ship_name}.",
			"Delivered without incident. The Tal Shiar may call on you again, {ship_name}.",
		],
	},
}

static var neutral_lines: Dictionary = {
	GENERIC: {
		PHASE.ACCEPTED: [
			"Contract accepted, {ship_name}. Head to the {system} system - payment on completion.",
			"Deal's a deal, {ship_name}. Get to {system} and we'll square up after.",
		],
		PHASE.PROGRESS: [
			"Looking good, {ship_name}. Keep at it.",
			"Nice work so far, {ship_name}. Don't stop now.",
		],
		PHASE.READY: [
			"That's everything, {ship_name}. Swing by the starbase and hail us to get paid.",
		],
		PHASE.COMPLETED: [
			"Job done, {ship_name}. Credits are on their way.",
			"Pleasure doing business, {ship_name}. Come back anytime.",
		],
	},
}


static func get_message(mission: MissionData, phase: PHASE, remaining: int = -1) -> String:
	var lines: Array = _lines_for(get_speaker_faction(mission, phase), mission.type, phase)
	if lines.is_empty():
		return ""

	var target_system: String = mission.target_system.system_name if mission.target_system else ""
	var data: Dictionary = {
		"ship_name": _apply_style(Utility.player_name, COLOR_PLAYER_SHIP),
		"system": _highlight(target_system),
		"planet": _highlight(mission.target_planet_name),
		"cargo": _highlight(mission.cargo),
		"bounty": _highlight(mission.bounty_name),
		"enemy": _highlight(Utility.FACTION.keys()[_enemy_for(mission)].capitalize()),
		"remaining": _highlight(str(maxi(remaining, 0))),
	}
	var text: String = _apply_style(lines.pick_random(), COLOR_BASE).format(data)

	var speaker: String = get_speaker_planet(mission, phase)
	if not speaker.is_empty():
		text = _highlight(speaker + ":") + " " + text
	return text


## Planet voicing this phase, or empty when the mission's faction speaks.
static func get_speaker_planet(mission: MissionData, phase: PHASE) -> String:
	if phase == PHASE.ACCEPTED:
		return mission.origin_planet_name
	if phase == PHASE.COMPLETED and mission.is_delivery_type():
		return mission.target_planet_name
	return ""


## Faction whose lines and portrait are used for this phase.
static func get_speaker_faction(mission: MissionData, phase: PHASE) -> Utility.FACTION:
	if phase == PHASE.ACCEPTED and not mission.origin_planet_name.is_empty():
		return mission.origin_planet_faction
	if phase == PHASE.COMPLETED and mission.is_delivery_type() and mission.target_system:
		var planet: PlanetData = mission.target_system.get_planet_data(mission.target_planet_name)
		if planet:
			return planet.faction
	return mission.faction_owner


static func _lines_for(faction: Utility.FACTION, type: MissionData.MISSION_TYPE, phase: PHASE) -> Array:
	var table: Dictionary
	match faction:
		Utility.FACTION.FEDERATION: table = federation_lines
		Utility.FACTION.KLINGON: table = klingon_lines
		Utility.FACTION.ROMULAN: table = romulan_lines
		_: table = neutral_lines

	var by_type: Dictionary = table.get(type, {})
	if by_type.has(phase):
		return by_type[phase]
	return table[GENERIC].get(phase, [])


static func _enemy_for(mission: MissionData) -> Utility.FACTION:
	if mission.type == MissionData.MISSION_TYPE.CONTRABAND:
		return mission.scanning_faction
	return mission.enemy_faction


static func _highlight(text: String) -> String:
	return _apply_style(text, COLOR_HIGHLIGHT)


## Nested color tags let highlights override the base color.
static func _apply_style(text: String, color_hex: String) -> String:
	return "[color=" + color_hex + "]" + text + "[/color]"
