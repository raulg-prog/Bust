extends Control

# Populated by wheel.gd before each spin
var segments: Array = []  # Array of [multiplier: float, color: Color]

const FONT        := preload("res://Assets/Fonts/m5x7.ttf")
const FONT_SIZE   := 14
const RIM_THICK   := 14.0   # outer dark rim width
const DOT_COUNT   := 24     # pearl dots around the rim
const DOT_RADIUS  := 4.0
const HUB_RADIUS  := 28.0
const MAX_RADIUS  := 130.0  # hard cap — wheel never exceeds 260 px diameter

# Colors
const C_RIM       := Color(0.14, 0.09, 0.05, 1)     # dark brown outer rim
const C_RIM_INNER := Color(0.22, 0.16, 0.08, 1)     # slightly lighter inner rim ring
const C_HUB       := Color(0.10, 0.07, 0.18, 1)     # dark center hub
const C_HUB_RING  := Color(0.31, 0.239, 0.565, 1)   # purple hub border
const C_DIVIDER   := Color(0.0, 0.0, 0.0, 0.55)     # thin divider between segments
const C_LABEL     := Color(1.0, 1.0, 1.0, 1)
const C_DOT       := Color(0.95, 0.92, 0.80, 1)     # pearl/ivory dots
const C_DOT_DARK  := Color(0.40, 0.36, 0.28, 1)     # dot shadow


func _draw() -> void:
	if segments.is_empty():
		return

	var center  := size / 2.0
	var radius  := minf(minf(size.x, size.y) / 2.0, MAX_RADIUS)
	var inner_r := radius - RIM_THICK
	var n       := segments.size()
	var arc     := TAU / n

	# ── Outer rim ──────────────────────────────────────────────────────────────
	draw_circle(center, radius, C_RIM)
	draw_circle(center, radius - 3.0, C_RIM_INNER)

	# ── Pie segments ───────────────────────────────────────────────────────────
	var STEPS := 32   # polygon smoothness per segment
	for i in n:
		var a0 := i * arc - TAU / 4.0        # offset so 0° is up (12 o'clock)
		var a1 := a0 + arc
		var seg_color: Color = segments[i][1]

		var pts := PackedVector2Array()
		pts.append(center)
		for s in (STEPS + 1):
			var a := a0 + arc * s / STEPS
			pts.append(center + Vector2(cos(a), sin(a)) * inner_r)
		draw_colored_polygon(pts, seg_color)

		# Thin black divider line between segments
		var edge := center + Vector2(cos(a0), sin(a0)) * inner_r
		draw_line(center, edge, C_DIVIDER, 1.5)

	# ── Segment labels (rotated into the slice center) ─────────────────────────
	for i in n:
		var a0      := i * arc - TAU / 4.0
		var mid_a   := a0 + arc * 0.5
		var label_r := inner_r * 0.62       # how far from center to place text

		var lx := center.x + cos(mid_a) * label_r
		var ly := center.y + sin(mid_a) * label_r

		var m: float = segments[i][0]
		var txt: String
		if m == 0.0:
			txt = "X"
		elif m == int(m):
			txt = "%dx" % int(m)
		else:
			txt = "%.1fx" % m

		# Rotate canvas so text reads outward from center
		draw_set_transform(Vector2(lx, ly), mid_a + PI / 2.0, Vector2.ONE)
		var tw := FONT.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		draw_string(FONT, Vector2(-tw / 2.0, FONT_SIZE / 2.0 - 1), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, C_LABEL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)  # reset transform

	# ── Pearl dots on rim ──────────────────────────────────────────────────────
	var dot_r := radius - RIM_THICK * 0.5
	for d in DOT_COUNT:
		var a    := d * TAU / DOT_COUNT
		var pos  := center + Vector2(cos(a), sin(a)) * dot_r
		draw_circle(pos, DOT_RADIUS + 1.0, C_DOT_DARK)
		draw_circle(pos, DOT_RADIUS, C_DOT)

	# ── Center hub ─────────────────────────────────────────────────────────────
	draw_circle(center, HUB_RADIUS + 3.0, C_HUB_RING)
	draw_circle(center, HUB_RADIUS, C_HUB)
