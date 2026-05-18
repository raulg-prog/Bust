@tool
class_name PlinkoBoard
extends Control

const ROWS       : int   = 12
const BUCKETS    : int   = 13
const TOP_Y      : float = 40.0
const ROW_H      : float = 30.0
const BUCKET_TOP : float = 400.0
const BUCKET_H   : float = 50.0
const PEG_R      : float = 6.0

const MULTS : Array[float] = [
	500.0, 25.0, 7.0, 2.0, 0.5, 0.2, 0.1,
	0.2, 0.5, 2.0, 7.0, 25.0, 500.0
]

# GBA-snapped bucket colors — symmetric, dark reds for losses, green for 2x, gold for wins
const BUCKET_COLORS : Array[Color] = [
	Color(0.973, 0.847, 0.188, 1.0),  # 500x — full gold
	Color(0.973, 0.816, 0.157, 1.0),  # 25x  — gold
	Color(0.878, 0.565, 0.094, 1.0),  # 7x   — amber
	Color(0.094, 0.627, 0.188, 1.0),  # 2x   — green
	Color(0.565, 0.157, 0.157, 1.0),  # 0.5x — mid red
	Color(0.439, 0.094, 0.094, 1.0),  # 0.2x — dark red
	Color(0.314, 0.063, 0.063, 1.0),  # 0.1x — darkest red
	Color(0.439, 0.094, 0.094, 1.0),  # 0.2x
	Color(0.565, 0.157, 0.157, 1.0),  # 0.5x
	Color(0.094, 0.627, 0.188, 1.0),  # 2x   — green
	Color(0.878, 0.565, 0.094, 1.0),  # 7x   — amber
	Color(0.973, 0.816, 0.157, 1.0),  # 25x  — gold
	Color(0.973, 0.847, 0.188, 1.0),  # 500x — full gold
]

const PEG_TEX = preload("res://Assets/Plinko/Asset 1 peg.png")

const COL_EDGE := Color(0.000, 0.000, 0.000, 0.600)
const COL_LBL  := Color(0.973, 0.973, 0.973, 1.0)

var lit_bucket : int = -1:
	set(v): lit_bucket = v; queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Wait for layout to settle so size.x is valid before placing colliders.
	await get_tree().process_frame
	_build_peg_colliders()


func _notification(what: int) -> void:
	# Re-draw and rebuild colliders whenever the control is resized (fires in editor too).
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
		if Engine.is_editor_hint() and size.x > 0.0:
			_build_peg_colliders()


func _build_peg_colliders() -> void:
	if size.x <= 0.0:
		return
	# Collect then free any previously built bodies (safe mid-iteration pattern).
	var old : Array = []
	for child in get_children():
		if child is StaticBody2D:
			old.append(child)
	for body in old:
		body.free()
	# One StaticBody2D + CircleShape2D per peg — visible in Godot's collision overlay.
	for row in range(ROWS):
		for col in range(row + 1):
			var sb   := StaticBody2D.new()
			sb.position = peg_pos(row, col)
			var cs   := CollisionShape2D.new()
			var circ := CircleShape2D.new()
			circ.radius = PEG_R
			cs.shape = circ
			sb.add_child(cs)
			add_child(sb)


func _draw() -> void:
	var ps := _ps()
	# Pegs — row r has (r+1) pegs, centred horizontally
	var pd := PEG_R * 2.0
	for row in range(ROWS):
		for col in range(row + 1):
			var pp := peg_pos(row, col)
			draw_texture_rect(PEG_TEX, Rect2(pp - Vector2(PEG_R, PEG_R), Vector2(pd, pd)), false)
	# Buckets
	var font := ThemeDB.fallback_font
	for i in range(BUCKETS):
		var bx  := float(i) * ps
		var col : Color = BUCKET_COLORS[i]
		if i == lit_bucket:
			col = col.lightened(0.25)
		draw_rect(Rect2(bx, BUCKET_TOP, ps, BUCKET_H), col)
		draw_rect(Rect2(bx, BUCKET_TOP, ps, BUCKET_H), COL_EDGE, false, 1.0)
		draw_string(font,
				Vector2(bx, BUCKET_TOP + 32.0),
				_fmt_mult(MULTS[i]),
				HORIZONTAL_ALIGNMENT_CENTER, ps, 10, COL_LBL)


func peg_pos(row: int, col: int) -> Vector2:
	var ps := _ps()
	return Vector2(
		size.x * 0.5 + (float(col) - float(row) * 0.5) * ps,
		TOP_Y + float(row) * ROW_H
	)


func bucket_center(idx: int) -> Vector2:
	var ps := _ps()
	return Vector2((float(idx) + 0.5) * ps, BUCKET_TOP + BUCKET_H * 0.5)


func spawn_pos() -> Vector2:
	return Vector2(size.x * 0.5, 10.0)


# Horizontal spacing between pegs — equals one bucket width, adapts to control size.
func _ps() -> float:
	return size.x / float(BUCKETS)


func _fmt_mult(m: float) -> String:
	if m >= 10.0:
		return "%dx" % int(m)
	elif m >= 1.0:
		return "%.0fx" % m
	else:
		return "%.1fx" % m
