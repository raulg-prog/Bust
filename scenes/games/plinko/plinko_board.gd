class_name PlinkoBoard
extends Control

const ROWS       : int   = 12
const BUCKETS    : int   = 13
const TOP_Y      : float = 40.0
const ROW_H      : float = 30.0
const BUCKET_TOP : float = 400.0
const BUCKET_H   : float = 50.0
const PEG_R      : float = 4.0
const BALL_R     : float = 8.0

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

const COL_PEG  := Color(0.816, 0.816, 0.816, 1.0)
const COL_BALL := Color(0.973, 0.847, 0.188, 1.0)
const COL_EDGE := Color(0.000, 0.000, 0.000, 0.600)
const COL_LBL  := Color(0.973, 0.973, 0.973, 1.0)

# Each active drop gets its own entry: ball_id → Vector2 position.
var balls      : Dictionary = {}
var lit_bucket : int = -1:
	set(v): lit_bucket = v; queue_redraw()


func set_ball(id: int, pos: Vector2) -> void:
	balls[id] = pos
	queue_redraw()


func remove_ball(id: int) -> void:
	balls.erase(id)
	queue_redraw()


func _draw() -> void:
	var ps := _ps()
	# Pegs — row r has (r+1) pegs, centred horizontally
	for row in range(ROWS):
		for col in range(row + 1):
			draw_circle(peg_pos(row, col), PEG_R, COL_PEG)
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
	# All active balls
	for pos in balls.values():
		draw_circle(pos, BALL_R, COL_BALL)


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
