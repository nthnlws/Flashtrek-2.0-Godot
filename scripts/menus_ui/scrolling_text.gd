extends Control

const SCROLL_SPEED: float = 20.0
var ticker_text: String

var _label: Label
var _label_copy: Label
var _scroll_offset: float = 0.0  # Float accumulator — never rounded

const ANCHOR_YEAR: int = 2025 
const ANCHOR_MONTH: int = 08 # October
const ANCHOR_DAY: int = 12

const ANCHOR_STARDATE_BASE: float = 4513.0


func _ready() -> void:
	clip_contents = true
	
	update_stardate()
	
	_label = Label.new()
	_label.name = "Label"
	_label_copy = Label.new()
	_label_copy.name = "LabelCopy"

	for lbl: Label in [_label, _label_copy]:
		lbl.text = ticker_text
		lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.1, 1.0))
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Disable integer offsets so sub-pixel positioning is respected
		lbl.use_parent_material = false
		add_child(lbl)

	await get_tree().process_frame
	_label_copy.position.x = _label.size.x


func _process(delta: float) -> void:
	var width: float = _label.size.x
	if width == 0.0:
		return

	# Accumulate as a true float — no rounding here
	_scroll_offset += SCROLL_SPEED * delta

	# Wrap the offset to avoid float overflow over long sessions
	if _scroll_offset >= width:
		_scroll_offset = fmod(_scroll_offset, width)

	# Apply fractional position to both labels
	_label.position.x      = -_scroll_offset
	_label_copy.position.x = -_scroll_offset + width


func update_stardate() -> void:
	# Calculate the current Stardate
	var current_stardate: float = Utility.get_federation_date()
	
	# Format the text for the label, showing one decimal place
	ticker_text = "SECTOR 084 PATROL ACTIVE  ·  ALL SYSTEMS NOMINAL  ·  STARFLEET COMMAND AUTHORIZED  ·  NO HOSTILE CONTACTS DETECTED  ·  FEDERATION STARDATE %.1f  ·" % current_stardate
