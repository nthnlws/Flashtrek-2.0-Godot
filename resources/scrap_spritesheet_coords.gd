@tool
extends Resource
class_name ScrapSpriteSheet

const SCRAP_SHEET: Texture2D = preload("uid://bmybeo1pjo21w")

# --- Row 0 ---
var smallscrap1: Vector4 = Vector4(0, 0, 64, 64)
var smallscrap2: Vector4 = Vector4(64, 0, 64, 64)
var mediumscrap1: Vector4 = Vector4(128, 0, 64, 64)
var mediumscrap2: Vector4 = Vector4(192, 0, 64, 64)
var largescrap1: Vector4 = Vector4(256, 0, 128, 128) # 2x2 cells
var mediumscrap3: Vector4 = Vector4(384, 0, 64, 128) # 1x2 cells

# --- Row 1 ---
var wires1: Vector4 = Vector4(0, 64, 64, 64)
var wires2: Vector4 = Vector4(64, 64, 64, 64)
var smallscrap3: Vector4 = Vector4(128, 64, 64, 64)
var wires3: Vector4 = Vector4(192, 64, 64, 64)
# (Columns 4-6 are occupied by largescrap1 and mediumscrap3 above)

# --- Row 2 ---
var scaffolding1: Vector4 = Vector4(0, 128, 64, 64)
var scaffolding2: Vector4 = Vector4(64, 128, 64, 64)
var panel1: Vector4 = Vector4(128, 128, 64, 64)
var panel2: Vector4 = Vector4(192, 128, 64, 64)
var wires4: Vector4 = Vector4(256, 128, 64, 64)
var ship_thruster1: Vector4 = Vector4(320, 128, 128, 64) # 2x1 cells

# --- Row 3 ---
var hull_scrap1: Vector4 = Vector4(0, 192, 64, 64)
var hull_scrap2: Vector4 = Vector4(64, 192, 64, 64)
var hull_scrap3: Vector4 = Vector4(128, 192, 64, 64)
var hull_scrap4: Vector4 = Vector4(192, 192, 64, 64)
var hull_scrap5: Vector4 = Vector4(256, 192, 64, 64)
var ship_thruster2: Vector4 = Vector4(320, 192, 128, 64) # 2x1 cells

# --- Row 4 ---
var saucerscrap: Vector4 = Vector4(0, 256, 128, 128) # 2x2 cells
var scaffolding3: Vector4 = Vector4(128, 256, 64, 64)
var engine_part: Vector4 = Vector4(192, 256, 64, 64)
var hull_scrap6: Vector4 = Vector4(256, 256, 64, 64)
var hull_scrap7: Vector4 = Vector4(320, 256, 64, 64)

# --- Row 5 ---
# (Columns 0-1 are occupied by saucerscrap above)
var smallscrap4: Vector4 = Vector4(128, 320, 64, 64)

# --- Grouped Arrays ---
var small_scraps: Array[Vector4]
var medium_scraps: Array[Vector4]
var large_scraps: Array[Vector4]
var saucer_scraps: Array[Vector4]
func _init() -> void:
	small_scraps = [
		smallscrap1, smallscrap2, mediumscrap1, mediumscrap2,
		wires1, wires2, smallscrap3, wires3,
		scaffolding1, scaffolding2, panel1, panel2, wires4,
		hull_scrap1, hull_scrap2, hull_scrap3, hull_scrap4, hull_scrap5,
		scaffolding3, engine_part, hull_scrap6, hull_scrap7, smallscrap4
	]
	
	medium_scraps = [
		mediumscrap3, ship_thruster1, ship_thruster2
	]
	
	large_scraps = [
		largescrap1,
		saucerscrap
	]
	
	saucer_scraps = [
		saucerscrap
	]
