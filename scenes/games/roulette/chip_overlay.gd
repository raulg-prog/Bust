extends Control
# Transparent overlay drawn on top of the number grid.
# Handles mouse input for straight / split / corner bets and draws placed chips.

signal bet_requested(key: String)

# Grid layout mirrors roulette.gd _build_board()
# Row 0 = top: 3,6,9,...,36  |  Row 1 = mid: 2,5,8,...,35  |  Row 2 = bot: 1,4,7,...,34
const ROW_NUMS : Array[Array] = [
	[3,6,9,12,15,18,21,24,27,30,33,36],
	[2,5,8,11,14,17,20,23,26,29,32,35],
	[1,4,7,10,13,16,19,22,25,28,31,34],
]
const CHIP_COLORS : Array[Color] = [
	Color(0.502, 0.502, 0.502, 1),  # $10  grey
	Color(0.157, 0.502, 0.220, 1),  # $25  green
	Color(0.659, 0.157, 0.157, 1),  # $50  red
	Color(0.157, 0.314, 0.659, 1),  # $100 blue
	Color(0.439, 0.157, 0.659, 1),  # $500 purple
]
const CHIP_VALS  : Array[float] = [10.0, 25.0, 50.0, 100.0, 500.0]
const THRESH     : float = 9.0   # px from cell edge → treat click as split/corner

var bets   : Dictionary = {}   # shared reference to roulette.gd bets dict
var locked : bool       = false

# Internal grid state (built once after layout settles)
var _crects : Dictionary = {}   # key → Rect2  (overlay local-space)
var _grid   : Dictionary = {}   # Vector2i(col,row) → key
var _posmap : Dictionary = {}   # key → Vector2i(col,row)
var _live   : bool       = false
var _hover  : String     = ""   # key under cursor for hover highlight


# ── Setup ─────────────────────────────────────────────────────────────────────

func init_grid(btn_map: Dictionary) -> void:
	_crects.clear()
	_grid.clear()
	_posmap.clear()
	# col 0: 0 and 00
	_reg("n_0",  btn_map, 0, 0)
	_reg("n_00", btn_map, 0, 1)
	# cols 1-12: the 36 numbers
	for ri in 3:
		for ci in 12:
			var num : int = ROW_NUMS[ri][ci]
			_reg("n_%d" % num, btn_map, ci + 1, ri)
	# 2:1 column buttons — straight bets only, no split/corner grid entry
	_reg_plain("col_1", btn_map)
	_reg_plain("col_2", btn_map)
	_reg_plain("col_3", btn_map)
	_live = true
	queue_redraw()


func _reg_plain(key: String, bmap: Dictionary) -> void:
	# Register only in _crects — routes clicks through the overlay without
	# participating in adjacency / split / corner detection
	if not bmap.has(key):
		return
	var gr := (bmap[key] as Button).get_global_rect()
	_crects[key] = Rect2(gr.position - global_position, gr.size)


func _reg(key: String, bmap: Dictionary, col: int, row: int) -> void:
	if not bmap.has(key):
		return
	var gr := (bmap[key] as Button).get_global_rect()
	# Convert global button position into the overlay's local space
	_crects[key] = Rect2(gr.position - global_position, gr.size)
	_grid[Vector2i(col, row)]  = key
	_posmap[key]               = Vector2i(col, row)


# ── Input ─────────────────────────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if not _live:
		return
	# Track hover for highlight (don't consume motion events)
	if event is InputEventMouseMotion:
		var new_h := _hover_at((event as InputEventMouseMotion).position)
		if new_h != _hover:
			_hover = new_h
			queue_redraw()
		return
	if locked:
		return
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var key := _pick(mb.position)
	if key != "":
		bet_requested.emit(key)
		accept_event()   # prevent click reaching outside-bet buttons for this area


func _hover_at(pos: Vector2) -> String:
	for key in _crects:
		if (_crects[key] as Rect2).has_point(pos):
			return key
	return ""


# ── Bet-type detection ────────────────────────────────────────────────────────

func _pick(pos: Vector2) -> String:
	# 1. Find which cell was clicked (exact hit)
	var pk := ""
	var pr := Rect2()
	for key in _crects:
		var r : Rect2 = _crects[key]
		if r.has_point(pos):
			pk = key
			pr = r
			break

	# Fallback: click landed in the gap between cells (3 px separation).
	# Find the nearest cell within THRESH*2 so corner/split detection still works.
	if pk == "":
		var best_d := THRESH * 2.5
		for key in _crects:
			var r : Rect2 = _crects[key]
			var closest := Vector2(clampf(pos.x, r.position.x, r.end.x),
			                       clampf(pos.y, r.position.y, r.end.y))
			var d := pos.distance_to(closest)
			if d < best_d:
				best_d = d
				pk = key
				pr = r
		if pk == "":
			return ""

	# 2. Measure proximity to each edge
	var nl := pos.x - pr.position.x                  < THRESH
	var nr := pr.position.x + pr.size.x - pos.x      < THRESH
	var nt := pos.y - pr.position.y                  < THRESH
	var nb := pr.position.y + pr.size.y - pos.y      < THRESH

	var al := _adj(pk, -1,  0)
	var ar := _adj(pk,  1,  0)
	var at := _adj(pk,  0, -1)
	var ab := _adj(pk,  0,  1)

	# 3. Corner bets (4 cells at a diagonal intersection)
	if nl and nt and al != "" and at != "":
		var c := _adj(at, -1, 0)
		if c != "":
			return _co(pk, al, at, c)
	if nr and nt and ar != "" and at != "":
		var c := _adj(at, 1, 0)
		if c != "":
			return _co(pk, ar, at, c)
	if nl and nb and al != "" and ab != "":
		var c := _adj(ab, -1, 0)
		if c != "":
			return _co(pk, al, ab, c)
	if nr and nb and ar != "" and ab != "":
		var c := _adj(ab, 1, 0)
		if c != "":
			return _co(pk, ar, ab, c)

	# 4. Split bets (2 adjacent cells)
	if nl and al != "": return _sp(pk, al)
	if nr and ar != "": return _sp(pk, ar)
	if nt and at != "": return _sp(pk, at)
	if nb and ab != "": return _sp(pk, ab)

	# 5. Straight bet
	return pk


func _adj(key: String, dx: int, dy: int) -> String:
	if not _posmap.has(key):
		return ""
	var p : Vector2i = _posmap[key]
	return _grid.get(Vector2i(p.x + dx, p.y + dy), "")


func _sp(a: String, b: String) -> String:
	var v : Array[String] = [a, b]
	v.sort()
	return "sp|%s|%s" % [v[0], v[1]]


func _co(a: String, b: String, c: String, d: String) -> String:
	var v : Array[String] = [a, b, c, d]
	v.sort()
	return "co|%s|%s|%s|%s" % [v[0], v[1], v[2], v[3]]


# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	if not _live:
		return

	# Hover highlight on current cell
	if _hover != "" and not locked and _crects.has(_hover):
		draw_rect(_crects[_hover] as Rect2, Color(0.973, 0.847, 0.188, 0.22))

	# Split / corner hover hints — dim border regions
	if _hover != "" and not locked:
		var pr : Rect2 = _crects.get(_hover, Rect2())
		_draw_split_hints(pr, _hover)

	# Chips
	var font      := ThemeDB.fallback_font
	var font_size := 8
	for key in bets:
		var amt : float = bets[key]
		if amt <= 0.0:
			continue
		var pt := _chip_center(key)
		if pt.x < -9000.0:
			continue
		_draw_chip(pt, amt, font, font_size)


func _draw_split_hints(pr: Rect2, pk: String) -> void:
	# Faint glow strips along borders that have an adjacent valid cell
	var hint := Color(0.973, 0.847, 0.188, 0.12)
	var tw   := 5.0
	if _adj(pk, -1, 0) != "": draw_rect(Rect2(pr.position.x, pr.position.y, tw, pr.size.y), hint)
	if _adj(pk,  1, 0) != "": draw_rect(Rect2(pr.position.x + pr.size.x - tw, pr.position.y, tw, pr.size.y), hint)
	if _adj(pk,  0,-1) != "": draw_rect(Rect2(pr.position.x, pr.position.y, pr.size.x, tw), hint)
	if _adj(pk,  0, 1) != "": draw_rect(Rect2(pr.position.x, pr.position.y + pr.size.y - tw, pr.size.x, tw), hint)


func _draw_chip(pt: Vector2, amt: float, font: Font, font_size: int) -> void:
	var col := _chip_col(amt)
	var cr  := 11.0

	# Drop shadow
	draw_circle(pt + Vector2(1.5, 2.0), cr, Color(0.0, 0.0, 0.0, 0.40))

	# Body
	draw_circle(pt, cr, col)

	# Beveled highlight ring (inner lighter band)
	var hl := col.lightened(0.35)
	draw_arc(pt, cr * 0.78, 0.0, TAU, 64, hl, 2.5, true)

	# Outer white rim
	draw_arc(pt, cr - 0.5, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.55), 1.0, true)

	# Dark center circle so text pops
	draw_circle(pt, cr * 0.52, col.darkened(0.25))

	# Amount text
	var lbl := _fmt_short(amt)
	var ts  := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, pt + Vector2(-ts.x * 0.5, ts.y * 0.35),
		lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 1.0, 1.0, 1.0))


func _chip_center(key: String) -> Vector2:
	if _crects.has(key):
		return (_crects[key] as Rect2).get_center()
	var parts := key.split("|")
	if parts.size() >= 3:
		var sum := Vector2.ZERO
		var cnt := 0
		for i in range(1, parts.size()):
			if _crects.has(parts[i]):
				sum += (_crects[parts[i]] as Rect2).get_center()
				cnt += 1
		if cnt > 0:
			return sum / float(cnt)
	return Vector2(-9999.0, -9999.0)


func _chip_col(amt: float) -> Color:
	var c := CHIP_COLORS[0]
	for i in CHIP_VALS.size():
		if amt >= CHIP_VALS[i]:
			c = CHIP_COLORS[i]
	return c


func _fmt_short(v: float) -> String:
	if v >= 1000.0:
		return "%dk" % int(v / 1000.0)
	return "%d" % int(v)
