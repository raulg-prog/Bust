extends Control

# American roulette wheel order clockwise from 12 o'clock (37 = "00")
const WHEEL_ORDER : Array[int] = [
	0, 28, 9, 26, 30, 11, 7, 20, 32, 17, 5, 22, 34, 15, 3,
	24, 36, 13, 1, 37, 27, 10, 25, 29, 12, 8, 19, 31, 18,
	6, 21, 33, 16, 4, 23, 35, 14, 2
]
const RED_NUMS : Array[int] = [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36]
const N := 38

var wheel_rot : float = 0.0   # current rotation offset in radians
var ball_angle: float = 0.0   # ball position angle (world, not relative to wheel)
var show_ball : bool  = false
var lit_num   : int   = -2    # -2=none, -1=00, 0-36=number to highlight gold


func _draw() -> void:
	var cx  := size.x * 0.5
	var cy  := size.y * 0.5
	var r   := minf(cx, cy) * 0.93
	var seg := TAU / float(N)
	var ctr := Vector2(cx, cy)

	# ── Outer border + track ─────────────────────────────────────────────────
	# Draw the wood ring (full circle), then paint the track circle on top —
	# the narrow gap between them becomes the visible wood border.
	_fill_circle(ctr, r,        Color(0.314, 0.188, 0.063, 1), 256)
	_fill_circle(ctr, r * 0.96, Color(0.063, 0.047, 0.031, 1), 256)

	# ── Pockets ──────────────────────────────────────────────────────────────
	# 36 arc-points per pocket → smooth outer rim at any wheel size
	for i in N:
		var num := WHEEL_ORDER[i]
		var a0  := float(i) * seg + wheel_rot - TAU * 0.25

		var col : Color
		if num == 0 or num == 37:
			col = Color(0.063, 0.345, 0.125, 1)
		elif num in RED_NUMS:
			col = Color(0.502, 0.063, 0.063, 1)
		else:
			col = Color(0.094, 0.094, 0.094, 1)
		if num == lit_num or (num == 37 and lit_num == -1):
			col = Color(0.973, 0.847, 0.188, 1)

		var pts := PackedVector2Array()
		pts.append(ctr)
		for s in 36:
			var a := a0 + seg * float(s) / 35.0
			pts.append(Vector2(cx + cos(a) * r * 0.93, cy + sin(a) * r * 0.93))
		draw_polygon(pts, PackedColorArray([col]))

		# Divider — antialiased for crisp edges
		draw_line(
			Vector2(cx + cos(a0) * r * 0.30, cy + sin(a0) * r * 0.30),
			Vector2(cx + cos(a0) * r * 0.93, cy + sin(a0) * r * 0.93),
			Color(0.314, 0.188, 0.063, 0.9), 1.5, true
		)

	# ── Number labels ─────────────────────────────────────────────────────────
	var font      := ThemeDB.fallback_font
	var font_size := maxi(9, int(r * 0.07))
	for i in N:
		var num  := WHEEL_ORDER[i]
		var ac   := float(i) * seg + wheel_rot - TAU * 0.25 + seg * 0.5
		var tx   := cx + cos(ac) * r * 0.72
		var ty   := cy + sin(ac) * r * 0.72
		var label: String = "00" if num == 37 else str(num)
		var ts   := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_set_transform(Vector2(tx, ty), ac + TAU * 0.25)
		draw_string(font, Vector2(-ts.x * 0.5, ts.y * 0.3), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.973, 0.973, 0.973, 1))
		draw_set_transform(Vector2.ZERO, 0.0)

	# ── Hub rings ─────────────────────────────────────────────────────────────
	_fill_circle(ctr, r * 0.30, Color(0.157, 0.094, 0.031, 1), 128)
	_fill_circle(ctr, r * 0.24, Color(0.314, 0.188, 0.063, 1), 128)
	_fill_circle(ctr, r * 0.15, Color(0.094, 0.063, 0.031, 1), 128)
	_fill_circle(ctr, r * 0.08, Color(0.502, 0.314, 0.094, 1), 128)

	# ── Ball ──────────────────────────────────────────────────────────────────
	if show_ball:
		var br  := r * 0.86
		var bpt := Vector2(cx + cos(ball_angle) * br, cy + sin(ball_angle) * br)
		# Ball size scales with wheel so it looks right at any resolution
		var bo  := clampf(r * 0.030, 5.0, 11.0)
		var bi  := clampf(r * 0.019, 3.0,  7.0)
		_fill_circle(bpt, bo, Color(0.973, 0.973, 0.973, 1), 48)
		_fill_circle(bpt, bi, Color(0.627, 0.627, 0.627, 1), 48)

	# ── Gold pointer at 12 o'clock ────────────────────────────────────────────
	var tip := Vector2(cx, cy - r * 0.95)
	var pl  := Vector2(cx - 9, cy - r * 1.04)
	var pr  := Vector2(cx + 9, cy - r * 1.04)
	draw_polygon(PackedVector2Array([tip, pl, pr]),
		PackedColorArray([Color(0.973, 0.847, 0.188, 1)]))


# ── Helpers ───────────────────────────────────────────────────────────────────

# Filled circle drawn as a high-poly fan — smooth at any radius
func _fill_circle(center: Vector2, radius: float, color: Color, segs: int) -> void:
	var pts := PackedVector2Array()
	pts.resize(segs + 2)
	pts[0] = center
	for i in segs + 1:
		var a := float(i) / float(segs) * TAU
		pts[i + 1] = center + Vector2(cos(a), sin(a)) * radius
	draw_polygon(pts, PackedColorArray([color]))
