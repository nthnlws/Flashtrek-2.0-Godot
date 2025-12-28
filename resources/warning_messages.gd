extends Resource
class_name WarningMessage

const COLOR_BASE: String = "#EB4034"		# Red Base
const COLOR_PLAYER_SHIP: String = "#6699CC" # Light Blue
const COLOR_ENEMY_SHIP: String = "#FFCC66"  # Gold

static var federation_warnings:Array[String] = [
	"Vessel {ship_name}, this is a restricted area under Federation law. Please alter your course immediately to avoid a diplomatic incident.",
	"Attention {ship_name}, you have entered a Federation security zone. Cease your current trajectory and leave the area, or we will be forced to take defensive measures.",
	"This is Starfleet command. {ship_name}, your ship has been flagged for trespassing in a defense sector. You are ordered to leave immediately.",
	"{ship_name}, you are in violation of treaty T-78 section 4. This is your official and final warning. Exit the system now to avoid interception.",
	"Unidentified ship {ship_name}, you are encroaching on a Federation colony's defensive perimeter. For the safety of our citizens, you must withdraw at once.",
]

static var romulan_warnings: Array[String] = [
	"Attention vessel {ship_name}. You have violated the borders of the Romulan Star Empire. Your incursion has been noted. Withdraw at once.",
	"{ship_name}, you are not authorized to be in this sector. This conversation is your only reprieve. Leave now, or we will take decisive action.",
	"This is the Imperial Warbird {warship_name}. To the ship {ship_name}, we are aware of your presence. Your continued violation of our space will have severe consequences.",
	"{ship_name}, your ignorance of sovereign borders is unacceptable. Consider this a final courtesy. Depart from Romulan territory immediately or be removed.",
	"Unidentified ship {ship_name}, you have entered a restricted military zone of the Romulan Star Empire. Power down your weapons and leave, or you will be fired upon.",
]

static var klingon_warnings: Array[String] = [
	"Unidentified vessel {ship_name}, you trespass in the territory of the Klingon Empire! Turn back now or be destroyed where you stand!",
	"{ship_name}, your presence insults us. This is your only warning. Leave Klingon space or we will paint these stars with your vessel's flaming wreckage.",
	"Cowards on the {ship_name}, you have blundered into the jaws of the beast. We grant you one chance to flee with your lives. Do not test our patience.",
	"This is the {warship_name} to the vessel {ship_name}. You are a stain upon our territory. Correct your course immediately or prepare for an honorable death.",
	"Hear me, {ship_name}! Your weak ship pollutes our stars. Alter course now, or we will give you a warrior's end!",
	]

static var klingon_ship_names: Array[String] = [
	"I.K.S. Vor'cha", "I.K.S. Negh'Var", "I.K.S. Bortas", "I.K.S. Gr'oth", "I.K.S. Maht'Hla",
	"I.K.S. Rotarran", "I.K.S. K'Tinga", "I.K.S. Hegh'ta", "I.K.S. Somraw", "I.K.S. T'Ong",
]

static var romulan_ship_names: Array[String] = [
	"I.R.W. Khazara", "I.R.W. Haakona", "I.R.W. Terix", "I.R.W. Valdore", "I.R.W. D'deridex",
	"I.R.W. Belak", "I.R.W. T'Verex", "I.R.W. Makar", "I.R.W. Decius", "I.R.W. Devoras",
]

## Wraps a string in BBCode color tags
static func _apply_style(text: String, color_hex: String) -> String:
	return "[color=" + color_hex + "]" + text + "[/color]"


static func get_federation_warning(player_name: String) -> String:
	var raw_template: String = federation_warnings.pick_random()
	
	var styled_player: String = _apply_style(player_name, COLOR_PLAYER_SHIP)
	var styled_template: String = _apply_style(raw_template, COLOR_BASE)
	
	return styled_template.format({"ship_name": styled_player})

static func get_romulan_warning(player_name: String) -> String:
	var warship_name: String = romulan_ship_names.pick_random()
	var raw_template: String = romulan_warnings.pick_random()
	
	var styled_player: String = _apply_style(player_name, COLOR_PLAYER_SHIP)
	var styled_warship: String = _apply_style(warship_name, COLOR_ENEMY_SHIP)
	var styled_template: String = _apply_style(raw_template, COLOR_BASE)
	
	return styled_template.format({
		"warship_name": styled_warship,
		"ship_name": styled_player
	})

static func get_klingon_warning(player_name: String) -> String:
	var warship_name: String = klingon_ship_names.pick_random()
	var raw_template: String = klingon_warnings.pick_random()
	
	var styled_player: String = _apply_style(player_name, COLOR_PLAYER_SHIP)
	var styled_warship: String = _apply_style(warship_name, COLOR_ENEMY_SHIP)
	var styled_template: String = _apply_style(raw_template, COLOR_BASE)
	
	return styled_template.format({
		"warship_name": styled_warship,
		"ship_name": styled_player
	})
