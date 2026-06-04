extends Control

# ── CONSTANTS ─────────────────────────────────────────────────────────────────

const COLS         := 6
const ROWS         := 5
const CELL_SIZE    := 80
const NCELLS       := COLS * ROWS   # 30
const SYM_SCATTER  := 9
const SYM_MULT     := 10
const MIN_WIN      := 8
const MIN_BET      := 10.0
const TOWN_ID      := 4
const BUY_MULT     := 100.0
const FS_BASE      := 15
const FS_RETRIG    := 5
const FS_TRIGGER   := 4
const FS_RETRIG_SC := 3
# Orb count distribution matches GoO: Zeus places 0–4 orbs per spin
# Base game weights for 0/1/2/3/4 orbs:
const ORB_COUNT_WEIGHTS_BASE : Array[int] = [50, 30, 14, 5, 1]
const ORB_COUNT_WEIGHTS_FS   : Array[int] = [20, 35, 28, 12, 5]

# Paytable[sym][tier]: tier 0=8–9 syms, 1=10–11, 2=12+
const PAYTABLE : Array = [
	[0.5,  1.0,  2.0],   # 0 Anchor
	[0.5,  1.0,  2.0],   # 1 Rope
	[0.75, 1.5,  3.0],   # 2 Compass
	[0.75, 1.5,  3.0],   # 3 Cannonball
	[1.0,  2.0,  4.0],   # 4 Rum Bottle
	[2.5,  5.0, 12.0],   # 5 Treasure Chest
	[2.0,  5.0, 15.0],   # 6 Cutlass
	[2.5, 10.0, 25.0],   # 7 Pistol
	[5.0, 15.0, 50.0],   # 8 Skull
]

# Scatter pays (index = scatter count, 0-3 unused): 4 scatters=1x, 5=3x, 6+=10x
const SCATTER_PAY  : Array[float] = [0.0, 0.0, 0.0, 0.0, 1.0, 3.0, 10.0]

# Exact GoO orb values and weights
const MULT_VALUES  : Array[int] = [2,  3,  4,  5,  6,  8,  10, 12, 15, 20, 25, 50, 100, 250, 500]
const MULT_WEIGHTS : Array[int] = [25, 20, 15, 12, 8,  6,  4,  3,  3,  2,  1,  1,  1,   1,   1]

# 0-4 low (Anchor/Rope/Compass/Cannonball/Rum), 5-8 high (Chest/Cutlass/Pistol/Skull), 9 Scatter
const SYM_WEIGHTS  : Array[int] = [15, 15, 15, 15, 15, 5, 5, 5, 5, 4]

const COL_NAVY    := Color(0.016, 0.031, 0.094, 1)
const COL_PANEL   := Color(0.016, 0.047, 0.125, 0.96)
const COL_BORDER  := Color(0.502, 0.408, 0.063, 1)
const COL_GOLD    := Color(0.973, 0.847, 0.188, 1)
const COL_GOLD_DK := Color(0.659, 0.533, 0.094, 1)
const COL_GREEN   := Color(0.376, 0.973, 0.502, 1)
const COL_RED     := Color(0.973, 0.376, 0.376, 1)
const COL_BLUE    := Color(0.502, 0.753, 0.973, 1)

# ── SYMBOL NODE (procedural draw) ─────────────────────────────────────────────

class SymbolNode extends Control:
	const GOLD    := Color(0.973, 0.847, 0.188, 1)
	const GOLD_DK := Color(0.659, 0.533, 0.094, 1)
	const IRON    := Color(0.220, 0.220, 0.251, 1)
	const IRON_LT := Color(0.376, 0.376, 0.439, 1)
	const BONE    := Color(0.910, 0.878, 0.816, 1)
	const WOOD    := Color(0.502, 0.314, 0.094, 1)
	const WOOD_DK := Color(0.314, 0.157, 0.031, 1)
	const WOOD_LT := Color(0.659, 0.439, 0.157, 1)
	const ROPE_C  := Color(0.722, 0.565, 0.282, 1)
	const ROPE_DK := Color(0.376, 0.251, 0.094, 1)
	const ROPE_LT := Color(0.878, 0.722, 0.439, 1)
	const NAVY    := Color(0.016, 0.031, 0.125, 1)
	const NAVY_LT := Color(0.094, 0.094, 0.251, 1)
	const AMBER   := Color(0.784, 0.439, 0.063, 1)
	const SHADOW  := Color(0.0, 0.0, 0.0, 0.38)

	var sym_id   : int = 0
	var mult_val : int = 0

	func _init(s: int, mv: int = 0) -> void:
		sym_id   = s
		mult_val = mv
		custom_minimum_size = Vector2(CELL_SIZE - 8, CELL_SIZE - 8)
		size                = Vector2(CELL_SIZE - 8, CELL_SIZE - 8)

	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := size.y * 0.5
		if mult_val > 0:
			_draw_mult_coin(cx, cy)
		else:
			match sym_id:
				0: _draw_anchor(cx, cy)
				1: _draw_rope(cx, cy)
				2: _draw_compass(cx, cy)
				3: _draw_cannonball(cx, cy)
				4: _draw_rum_bottle(cx, cy)
				5: _draw_chest(cx, cy)
				6: _draw_cutlass(cx, cy)
				7: _draw_pistol(cx, cy)
				8: _draw_skull(cx, cy)
				9: _draw_scatter(cx, cy)

	# ── ANCHOR ────────────────────────────────────────────────────────────────
	func _draw_anchor(cx: float, cy: float) -> void:
		var r := size.x * 0.38
		# Ring
		var rc := Vector2(cx, cy - r * 0.64)
		var rr := r * 0.19
		draw_arc(rc + Vector2(2, 2), rr, 0, TAU, 32, SHADOW, 4.0, true)
		draw_arc(rc, rr, 0, TAU, 32, NAVY_LT, 5.0, true)
		draw_arc(rc, rr, 0, TAU, 32, GOLD, 3.0, true)
		# Shaft shadow + shaft
		draw_line(Vector2(cx + 2, cy - r * 0.46), Vector2(cx + 2, cy + r * 0.56), SHADOW, 9, true)
		draw_line(Vector2(cx, cy - r * 0.46), Vector2(cx, cy + r * 0.56), NAVY_LT, 8, true)
		draw_line(Vector2(cx, cy - r * 0.46), Vector2(cx, cy + r * 0.56), GOLD, 5, true)
		draw_line(Vector2(cx, cy - r * 0.46), Vector2(cx, cy + r * 0.56), Color(1, 1, 1, 0.15), 2, true)
		# Crossbar
		draw_line(Vector2(cx - r * 0.56 + 2, cy - r * 0.16 + 2), Vector2(cx + r * 0.56 + 2, cy - r * 0.16 + 2), SHADOW, 9, true)
		draw_line(Vector2(cx - r * 0.56, cy - r * 0.16), Vector2(cx + r * 0.56, cy - r * 0.16), NAVY_LT, 8, true)
		draw_line(Vector2(cx - r * 0.56, cy - r * 0.16), Vector2(cx + r * 0.56, cy - r * 0.16), GOLD, 5, true)
		# Crossbar tips
		for s in [-1.0, 1.0]:
			draw_circle(Vector2(cx + s * r * 0.56 + 2, cy - r * 0.16 + 2), r * 0.08, SHADOW)
			draw_circle(Vector2(cx + s * r * 0.56, cy - r * 0.16), r * 0.09, NAVY_LT)
			draw_circle(Vector2(cx + s * r * 0.56, cy - r * 0.16), r * 0.06, GOLD)
		# Bottom circle
		draw_circle(Vector2(cx + 2, cy + r * 0.36 + 2), r * 0.24, SHADOW)
		draw_circle(Vector2(cx, cy + r * 0.36), r * 0.24, NAVY_LT)
		draw_arc(Vector2(cx, cy + r * 0.36), r * 0.24, 0, TAU, 32, GOLD, 3.0, true)
		draw_arc(Vector2(cx, cy + r * 0.36), r * 0.14, 0, TAU, 32, GOLD_DK, 3.0, true)
		# Flukes
		for s in [-1.0, 1.0]:
			var pts := PackedVector2Array([
				Vector2(cx + s * r * 0.04, cy + r * 0.3),
				Vector2(cx + s * r * 0.52, cy + r * 0.66),
				Vector2(cx + s * r * 0.4,  cy + r * 0.86),
				Vector2(cx + s * r * 0.06, cy + r * 0.56),
			])
			draw_polygon(pts, [NAVY_LT])
			draw_polyline(pts, GOLD, 2.5, true)
		# Highlight on ring
		draw_arc(rc, rr * 0.72, PI * 1.2, PI * 1.75, 16, Color(1, 1, 1, 0.4), 2.5, true)

	# ── ROPE KNOT ─────────────────────────────────────────────────────────────
	func _draw_rope(cx: float, cy: float) -> void:
		var r := size.x * 0.38
		# Hanging ends top
		for s in [-1.0, 1.0]:
			draw_line(Vector2(cx + s * r * 0.3 + 2, cy - r * 0.92 + 2),
				Vector2(cx + s * r * 0.18 + 2, cy - r * 0.28 + 2), SHADOW, 7, true)
			draw_line(Vector2(cx + s * r * 0.3, cy - r * 0.92),
				Vector2(cx + s * r * 0.18, cy - r * 0.28), ROPE_DK, 7, true)
			draw_line(Vector2(cx + s * r * 0.3, cy - r * 0.92),
				Vector2(cx + s * r * 0.18, cy - r * 0.28), ROPE_C, 4, true)
			draw_line(Vector2(cx + s * r * 0.3, cy - r * 0.92),
				Vector2(cx + s * r * 0.18, cy - r * 0.28), ROPE_LT, 1.5, true)
		# Left loop
		draw_arc(Vector2(cx - r * 0.24, cy - r * 0.04), r * 0.34, PI * 0.25, PI * 1.75, 28, ROPE_DK, 9, true)
		draw_arc(Vector2(cx - r * 0.24, cy - r * 0.04), r * 0.34, PI * 0.25, PI * 1.75, 28, ROPE_C, 6, true)
		draw_arc(Vector2(cx - r * 0.24, cy - r * 0.04), r * 0.34, PI * 0.25, PI * 1.75, 28, ROPE_LT, 2, true)
		# Right loop
		draw_arc(Vector2(cx + r * 0.24, cy - r * 0.04), r * 0.34, PI * 1.25, PI * 2.75, 28, ROPE_DK, 9, true)
		draw_arc(Vector2(cx + r * 0.24, cy - r * 0.04), r * 0.34, PI * 1.25, PI * 2.75, 28, ROPE_C, 6, true)
		draw_arc(Vector2(cx + r * 0.24, cy - r * 0.04), r * 0.34, PI * 1.25, PI * 2.75, 28, ROPE_LT, 2, true)
		# Center cross-band
		draw_rect(Rect2(cx - r * 0.2, cy - r * 0.22, r * 0.4, r * 0.44), ROPE_DK)
		draw_rect(Rect2(cx - r * 0.16, cy - r * 0.20, r * 0.32, r * 0.40), ROPE_C)
		draw_rect(Rect2(cx - r * 0.07, cy - r * 0.20, r * 0.14, r * 0.40), ROPE_LT)
		# Tail ends bottom
		for s in [-1.0, 1.0]:
			draw_line(Vector2(cx + s * r * 0.2 + 2, cy + r * 0.24 + 2),
				Vector2(cx + s * r * 0.32 + 2, cy + r * 0.88 + 2), SHADOW, 7, true)
			draw_line(Vector2(cx + s * r * 0.2, cy + r * 0.24),
				Vector2(cx + s * r * 0.32, cy + r * 0.88), ROPE_DK, 7, true)
			draw_line(Vector2(cx + s * r * 0.2, cy + r * 0.24),
				Vector2(cx + s * r * 0.32, cy + r * 0.88), ROPE_C, 4, true)
			draw_line(Vector2(cx + s * r * 0.2, cy + r * 0.24),
				Vector2(cx + s * r * 0.32, cy + r * 0.88), ROPE_LT, 1.5, true)
		# Wrap strands on band
		for i in 3:
			var y := cy - r * 0.12 + float(i) * r * 0.14
			draw_line(Vector2(cx - r * 0.16, y), Vector2(cx + r * 0.16, y), ROPE_DK, 1.5, true)

	# ── COMPASS ───────────────────────────────────────────────────────────────
	func _draw_compass(cx: float, cy: float) -> void:
		var r := size.x * 0.42
		# Shadow + bezel
		draw_circle(Vector2(cx + 2, cy + 3), r, SHADOW)
		draw_circle(Vector2(cx, cy), r, WOOD_DK)
		draw_arc(Vector2(cx, cy), r, 0, TAU, 64, GOLD, 4.0, true)
		draw_arc(Vector2(cx, cy), r * 0.94, 0, TAU, 64, GOLD_DK, 2.0, true)
		# Face
		draw_circle(Vector2(cx, cy), r * 0.84, Color(0.941, 0.910, 0.816, 1))
		# Degree rings
		draw_arc(Vector2(cx, cy), r * 0.84, 0, TAU, 64, Color(0.627, 0.533, 0.376, 1), 2.0, true)
		# Tick marks
		for i in 24:
			var angle := float(i) / 24.0 * TAU
			var is_card := i % 6 == 0
			var tick_out := r * 0.84
			var tick_in  := r * 0.70 if is_card else r * 0.76
			var thick    := 2.5 if is_card else 1.5
			draw_line(
				Vector2(cx + cos(angle) * tick_in, cy + sin(angle) * tick_in),
				Vector2(cx + cos(angle) * tick_out, cy + sin(angle) * tick_out),
				Color(0.376, 0.251, 0.094, 1), thick, true)
		# Needle N (red)
		var n_pts := PackedVector2Array([
			Vector2(cx, cy),
			Vector2(cx - r * 0.1,  cy + r * 0.12),
			Vector2(cx, cy - r * 0.64),
			Vector2(cx + r * 0.1,  cy + r * 0.12),
		])
		draw_polygon(n_pts, [Color(0, 0, 0, 0.25)])
		draw_polygon(n_pts, [Color(0.878, 0.157, 0.094, 1)])
		draw_line(Vector2(cx, cy - r * 0.64), Vector2(cx, cy + r * 0.12), Color(1, 0.4, 0.3, 0.4), 2, true)
		# Needle S (white/silver)
		var s_pts := PackedVector2Array([
			Vector2(cx, cy),
			Vector2(cx - r * 0.1, cy - r * 0.12),
			Vector2(cx, cy + r * 0.64),
			Vector2(cx + r * 0.1, cy - r * 0.12),
		])
		draw_polygon(s_pts, [Color(0.784, 0.784, 0.816, 1)])
		draw_line(Vector2(cx, cy + r * 0.08), Vector2(cx, cy + r * 0.64), Color(1, 1, 1, 0.3), 2, true)
		# Centre rivet
		draw_circle(Vector2(cx, cy), r * 0.1, WOOD_DK)
		draw_circle(Vector2(cx, cy), r * 0.07, GOLD)
		draw_circle(Vector2(cx, cy), r * 0.04, GOLD_DK)
		# N label
		draw_string(ThemeDB.fallback_font,
			Vector2(cx - 5, cy - r * 0.74 + 10), "N",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.188, 0.094, 0.031, 1))

	# ── CANNONBALL ────────────────────────────────────────────────────────────
	func _draw_cannonball(cx: float, cy: float) -> void:
		var r := size.x * 0.41
		draw_circle(Vector2(cx + 3, cy + 4), r, SHADOW)
		# Base sphere layers (painted iron look)
		draw_circle(Vector2(cx, cy), r, Color(0.094, 0.094, 0.125, 1))
		draw_circle(Vector2(cx + 1, cy + 2), r * 0.93, Color(0.078, 0.078, 0.110, 1))
		# Subtle texture rings
		draw_arc(Vector2(cx, cy), r * 0.75, PI * 0.3, PI * 0.9, 20, Color(0.125, 0.125, 0.157, 1), 2.5, true)
		draw_arc(Vector2(cx, cy), r * 0.5,  PI * 0.1, PI * 0.7, 16, Color(0.110, 0.110, 0.141, 1), 1.5, true)
		# Highlight zones (light from top-left)
		draw_circle(Vector2(cx - r * 0.26, cy - r * 0.3),  r * 0.32, Color(0.282, 0.282, 0.345, 1))
		draw_circle(Vector2(cx - r * 0.30, cy - r * 0.34), r * 0.18, Color(0.439, 0.439, 0.502, 1))
		draw_circle(Vector2(cx - r * 0.34, cy - r * 0.38), r * 0.09, Color(0.627, 0.627, 0.690, 1))
		draw_circle(Vector2(cx - r * 0.37, cy - r * 0.41), r * 0.045, Color(0.816, 0.816, 0.878, 1))
		# Edge rim highlight (opposite the shadow)
		draw_arc(Vector2(cx, cy), r - 2, PI * 1.1, PI * 1.55, 20, Color(0.220, 0.220, 0.282, 1), 3.5, true)

	# ── RUM BOTTLE ────────────────────────────────────────────────────────────
	func _draw_rum_bottle(cx: float, cy: float) -> void:
		var r := size.x * 0.38
		# Body polygon
		var body := PackedVector2Array([
			Vector2(cx - r * 0.36, cy - r * 0.08),
			Vector2(cx - r * 0.44, cy + r * 0.28),
			Vector2(cx - r * 0.44, cy + r * 0.76),
			Vector2(cx + r * 0.44, cy + r * 0.76),
			Vector2(cx + r * 0.44, cy + r * 0.28),
			Vector2(cx + r * 0.36, cy - r * 0.08),
		])
		# Shadow
		var body_sh : PackedVector2Array = PackedVector2Array()
		for p in body:
			body_sh.append(p + Vector2(3, 3))
		draw_polygon(body_sh, [SHADOW])
		# Dark glass
		draw_polygon(body, [Color(0.345, 0.157, 0.016, 1)])
		# Amber liquid fill (inner)
		var fill := PackedVector2Array([
			Vector2(cx - r * 0.35, cy + r * 0.10),
			Vector2(cx - r * 0.42, cy + r * 0.28),
			Vector2(cx - r * 0.42, cy + r * 0.74),
			Vector2(cx + r * 0.42, cy + r * 0.74),
			Vector2(cx + r * 0.42, cy + r * 0.28),
			Vector2(cx + r * 0.35, cy + r * 0.10),
		])
		draw_polygon(fill, [Color(0.722, 0.376, 0.047, 0.85)])
		# Liquid surface shimmer
		draw_line(Vector2(cx - r * 0.38, cy + r * 0.11), Vector2(cx + r * 0.38, cy + r * 0.11),
			Color(0.941, 0.659, 0.188, 0.5), 2.5, true)
		# Neck
		draw_rect(Rect2(cx - r * 0.19, cy - r * 0.52, r * 0.38, r * 0.46), Color(0.345, 0.157, 0.016, 1))
		draw_rect(Rect2(cx - r * 0.14, cy - r * 0.50, r * 0.28, r * 0.44), Color(0.502, 0.251, 0.031, 1))
		draw_rect(Rect2(cx - r * 0.10, cy - r * 0.50, r * 0.08, r * 0.44), Color(0.627, 0.345, 0.063, 0.4))
		# Cork
		draw_rect(Rect2(cx - r * 0.16, cy - r * 0.76, r * 0.32, r * 0.26), WOOD_DK)
		draw_rect(Rect2(cx - r * 0.13, cy - r * 0.73, r * 0.26, r * 0.20), WOOD)
		draw_rect(Rect2(cx - r * 0.08, cy - r * 0.71, r * 0.10, r * 0.14), WOOD_LT)
		# Label (cream background + border)
		draw_rect(Rect2(cx - r * 0.35, cy + r * 0.05, r * 0.70, r * 0.46), Color(0.941, 0.878, 0.753, 1))
		draw_rect(Rect2(cx - r * 0.35, cy + r * 0.05, r * 0.70, r * 0.46), GOLD_DK, false, 1.5)
		draw_rect(Rect2(cx - r * 0.32, cy + r * 0.08, r * 0.64, r * 0.40), Color(0.878, 0.784, 0.596, 1))
		# Label text
		draw_string(ThemeDB.fallback_font, Vector2(cx - r * 0.24, cy + r * 0.34),
			"RUM", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.251, 0.094, 0.031, 1))
		# Glass highlight streak
		draw_line(Vector2(cx - r * 0.30, cy - r * 0.04), Vector2(cx - r * 0.30, cy + r * 0.68),
			Color(1, 1, 1, 0.17), 4, true)
		# Body outline
		draw_polyline(body, GOLD_DK, 2.0, true)

	# ── TREASURE CHEST ────────────────────────────────────────────────────────
	func _draw_chest(cx: float, cy: float) -> void:
		var r := size.x * 0.40
		var bx := cx - r * 0.76
		var by := cy - r * 0.05
		var bw := r * 1.52
		var bh := r * 0.78
		# Shadow
		draw_rect(Rect2(bx + 3, by + 4, bw, bh), SHADOW)
		# Bottom box
		draw_rect(Rect2(bx, by, bw, bh), Color(0.345, 0.157, 0.031, 1))
		# Wood grain lines on bottom
		for i in 4:
			var y2 := by + float(i + 1) * bh / 5.0
			draw_line(Vector2(bx, y2), Vector2(bx + bw, y2), Color(0.251, 0.110, 0.022, 1), 1.5)
		# Lid shadow
		draw_rect(Rect2(bx + 2, cy - r * 0.42 + 3, bw, r * 0.40), SHADOW)
		# Lid rectangle base
		draw_rect(Rect2(bx, cy - r * 0.42, bw, r * 0.40), Color(0.502, 0.251, 0.063, 1))
		# Lid arch
		draw_arc(Vector2(cx, by + 1), r * 0.76, PI, TAU, 48, Color(0.502, 0.251, 0.063, 1), r * 0.40 * 2 + 1, true)
		# Lid highlight arc
		draw_arc(Vector2(cx, by + 1), r * 0.66, PI * 1.08, PI * 1.92, 32, Color(0.627, 0.345, 0.094, 1), 5.0, true)
		draw_arc(Vector2(cx, by + 1), r * 0.58, PI * 1.12, PI * 1.88, 24, Color(0.722, 0.439, 0.125, 0.6), 3.5, true)
		# Gold hinge band (horizontal)
		draw_rect(Rect2(bx, by - r * 0.07, bw, r * 0.14), GOLD_DK)
		draw_rect(Rect2(bx, by - r * 0.05, bw, r * 0.10), GOLD)
		# Gold strap (vertical center)
		draw_rect(Rect2(cx - r * 0.09, cy - r * 0.42, r * 0.18, bh + r * 0.42), GOLD_DK)
		draw_rect(Rect2(cx - r * 0.065, cy - r * 0.42, r * 0.13, bh + r * 0.42), GOLD)
		# Padlock body
		draw_circle(Vector2(cx, by + r * 0.04), r * 0.15, GOLD_DK)
		draw_circle(Vector2(cx, by + r * 0.04), r * 0.11, GOLD)
		draw_circle(Vector2(cx, by + r * 0.08), r * 0.07, Color(0.251, 0.125, 0.016, 1))
		# Padlock shackle
		draw_arc(Vector2(cx, by - r * 0.06), r * 0.09, PI, TAU, 16, GOLD_DK, 4.0, true)
		draw_arc(Vector2(cx, by - r * 0.06), r * 0.09, PI, TAU, 16, GOLD,    2.5, true)
		# Spilling coins
		for i in 5:
			var cx2 := bx + bw * (0.12 + float(i) * 0.18)
			var cy2 := by + bh + r * 0.06
			draw_circle(Vector2(cx2 + 1, cy2 + 1), r * 0.085, SHADOW)
			draw_circle(Vector2(cx2, cy2), r * 0.085, GOLD_DK)
			draw_circle(Vector2(cx2, cy2), r * 0.06,  GOLD)
		# Outline
		draw_rect(Rect2(bx, by, bw, bh), GOLD_DK, false, 2.0)
		draw_arc(Vector2(cx, by + 1), r * 0.76, PI, TAU, 48, GOLD_DK, 2.5, true)

	# ── CUTLASS ───────────────────────────────────────────────────────────────
	func _draw_cutlass(cx: float, cy: float) -> void:
		var r := size.x * 0.43
		# Blade: 4-point quad (back-edge handle → cutting-edge handle → cutting-edge tip → back-edge tip)
		# This ordering guarantees a convex, non-self-intersecting polygon
		var p0 := Vector2(cx - r * 0.55, cy + r * 0.65)   # back edge, handle
		var p1 := Vector2(cx - r * 0.38, cy + r * 0.52)   # cutting edge, handle
		var p2 := Vector2(cx + r * 0.55, cy - r * 0.52)   # cutting edge, tip
		var p3 := Vector2(cx + r * 0.68, cy - r * 0.68)   # back edge, tip
		# Shadow
		var sh_off := Vector2(3, 3)
		draw_polygon(PackedVector2Array([p0 + sh_off, p1 + sh_off, p2 + sh_off, p3 + sh_off]), [SHADOW])
		# Dark steel base
		draw_polygon(PackedVector2Array([p0, p1, p2, p3]), [Color(0.345, 0.376, 0.408, 1)])
		# Light steel face (inset slightly from cutting edge)
		var p1b := p0.lerp(p1, 0.55)
		var p2b := p3.lerp(p2, 0.55)
		draw_polygon(PackedVector2Array([p0, p1b, p2b, p3]), [Color(0.690, 0.722, 0.753, 1)])
		# Blade highlight streak
		draw_line(p1b.lerp(p0, 0.3), p2b.lerp(p3, 0.3),
			Color(0.910, 0.941, 0.973, 0.65), 2.5, true)
		draw_line(p1b.lerp(p0, 0.15), p2b.lerp(p3, 0.15),
			Color(1, 1, 1, 0.25), 1.2, true)
		# Fuller groove (mid-blade line)
		draw_line(p0.lerp(p1, 0.3), p3.lerp(p2, 0.3),
			Color(0.502, 0.533, 0.565, 1), 1.8, true)
		# Crossguard
		draw_rect(Rect2(cx - r * 0.24, cy + r * 0.36, r * 0.48, r * 0.14), WOOD_DK)
		draw_rect(Rect2(cx - r * 0.22, cy + r * 0.38, r * 0.44, r * 0.10), GOLD_DK)
		draw_rect(Rect2(cx - r * 0.20, cy + r * 0.40, r * 0.40, r * 0.06), GOLD)
		# Guard tips
		for s in [-1.0, 1.0]:
			draw_circle(Vector2(cx + s * r * 0.22, cy + r * 0.43), r * 0.07, GOLD_DK)
			draw_circle(Vector2(cx + s * r * 0.22, cy + r * 0.43), r * 0.05, GOLD)
		# Handle (4-point quad, explicitly convex)
		var h0 := Vector2(cx - r * 0.14, cy + r * 0.50)
		var h1 := Vector2(cx - r * 0.20, cy + r * 0.50)
		var h2 := Vector2(cx - r * 0.68, cy + r * 0.90)
		var h3 := Vector2(cx - r * 0.60, cy + r * 0.92)
		draw_polygon(PackedVector2Array([h0, h1, h2, h3]), [WOOD_DK])
		draw_polygon(PackedVector2Array([h0, h1, h2, h3]), [WOOD])
		# Handle wrap bands
		for i in 5:
			var t  := 0.15 + float(i) * 0.16
			var hp := h1.lerp(h2, t)
			draw_circle(hp, 3.0, GOLD_DK)
			draw_circle(hp, 2.0, GOLD)
		# Pommel
		draw_circle(Vector2(cx - r * 0.65 + 2, cy + r * 0.90 + 2), r * 0.12, SHADOW)
		draw_circle(Vector2(cx - r * 0.65, cy + r * 0.90), r * 0.12, WOOD_DK)
		draw_circle(Vector2(cx - r * 0.65, cy + r * 0.90), r * 0.09, GOLD_DK)
		draw_circle(Vector2(cx - r * 0.65, cy + r * 0.90), r * 0.06, GOLD)

	# ── FLINTLOCK PISTOL ──────────────────────────────────────────────────────
	func _draw_pistol(cx: float, cy: float) -> void:
		var r := size.x * 0.43
		# Barrel shadow
		draw_rect(Rect2(cx - r * 0.74 + 3, cy - r * 0.09 + 3, r * 1.0, r * 0.18), SHADOW)
		# Barrel body
		draw_rect(Rect2(cx - r * 0.74, cy - r * 0.09, r * 1.0, r * 0.18), Color(0.157, 0.157, 0.188, 1))
		draw_rect(Rect2(cx - r * 0.74, cy - r * 0.06, r * 0.98, r * 0.12), IRON)
		# Barrel highlight
		draw_line(Vector2(cx - r * 0.72, cy - r * 0.04), Vector2(cx + r * 0.24, cy - r * 0.04),
			IRON_LT, 2.5, true)
		# Barrel bands (gold rings)
		for xo in [0.0, 0.28, 0.52]:
			draw_arc(Vector2(cx - r * 0.74 + r * xo + r * 0.1, cy), r * 0.09,
				PI * 0.5, PI * 1.5, 12, GOLD_DK, 3.0, true)
		# Muzzle cap
		draw_rect(Rect2(cx - r * 0.78, cy - r * 0.115, r * 0.12, r * 0.23), Color(0.110, 0.110, 0.141, 1))
		draw_rect(Rect2(cx - r * 0.78, cy - r * 0.095, r * 0.11, r * 0.19), IRON)
		draw_arc(Vector2(cx + r * 0.26, cy), r * 0.1, 0, TAU, 16, GOLD, 2.5, true)
		# Flintlock box
		draw_rect(Rect2(cx + r * 0.04, cy - r * 0.24, r * 0.34, r * 0.33), WOOD_DK)
		draw_rect(Rect2(cx + r * 0.06, cy - r * 0.22, r * 0.30, r * 0.12), GOLD_DK)
		draw_rect(Rect2(cx + r * 0.08, cy - r * 0.20, r * 0.26, r * 0.09), GOLD)
		# Pan and frizzen
		draw_rect(Rect2(cx + r * 0.06, cy - r * 0.09, r * 0.16, r * 0.09), GOLD_DK)
		draw_rect(Rect2(cx + r * 0.14, cy - r * 0.18, r * 0.08, r * 0.18), IRON)
		# Hammer (cocked)
		var hmr := PackedVector2Array([
			Vector2(cx + r * 0.30, cy - r * 0.09),
			Vector2(cx + r * 0.24, cy - r * 0.22),
			Vector2(cx + r * 0.36, cy - r * 0.30),
			Vector2(cx + r * 0.38, cy - r * 0.16),
		])
		draw_polygon(hmr, [IRON])
		draw_polyline(hmr, IRON_LT, 1.5, true)
		# Grip (dark wood, angled downward)
		var grip := PackedVector2Array([
			Vector2(cx + r * 0.10, cy + r * 0.09),
			Vector2(cx + r * 0.38, cy + r * 0.09),
			Vector2(cx + r * 0.24, cy + r * 0.82),
			Vector2(cx + r * 0.06, cy + r * 0.78),
		])
		draw_polygon(grip, [WOOD_DK])
		draw_polygon(grip, [WOOD_LT])  # draw again for highlight: actually let's do overlay
		# Grip wood grain
		for i in 4:
			var t   := 0.2 + float(i) * 0.18
			var gp1 := Vector2(lerpf(cx + r*0.12, cx + r*0.08, t), lerpf(cy + r*0.09, cy + r*0.78, t))
			var gp2 := Vector2(lerpf(cx + r*0.36, cx + r*0.22, t), lerpf(cy + r*0.09, cy + r*0.82, t))
			draw_line(gp1, gp2, WOOD_DK, 1.5)
		draw_polygon(grip, [WOOD])  # semitransparent overlay
		# Grip highlight
		draw_line(Vector2(cx + r * 0.14, cy + r * 0.12), Vector2(cx + r * 0.10, cy + r * 0.74),
			Color(1, 1, 1, 0.15), 4, true)
		# Trigger
		draw_arc(Vector2(cx + r * 0.30, cy + r * 0.26), r * 0.16,
			PI * 0.18, PI * 0.95, 12, GOLD_DK, 3.5, true)
		draw_arc(Vector2(cx + r * 0.30, cy + r * 0.26), r * 0.16,
			PI * 0.18, PI * 0.95, 12, GOLD,    2.0, true)
		# Butt cap
		draw_arc(Vector2(cx + r * 0.15, cy + r * 0.80), r * 0.12, 0, TAU, 16, GOLD_DK, 3.5, true)
		draw_arc(Vector2(cx + r * 0.15, cy + r * 0.80), r * 0.12, 0, TAU, 16, GOLD, 2.0, true)

	# ── SKULL & CROSSBONES ────────────────────────────────────────────────────
	func _draw_skull(cx: float, cy: float) -> void:
		var r := size.x * 0.43
		var bone_c := Color(0.878, 0.847, 0.784, 1)
		var bone_d := Color(0.627, 0.596, 0.533, 1)
		var bone_l := Color(0.941, 0.910, 0.847, 1)
		# Crossed bones (drawn first, behind skull)
		for flip in [-1.0, 1.0]:
			var x1 : float = cx + float(flip) * r * 0.7
			var y1 : float = cy + r * 0.3
			var x2 : float = cx - float(flip) * r * 0.7
			var y2 : float = cy + r * 0.92
			draw_line(Vector2(x1 + 2, y1 + 2), Vector2(x2 + 2, y2 + 2), SHADOW, 8, true)
			draw_line(Vector2(x1, y1), Vector2(x2, y2), bone_d, 8, true)
			draw_line(Vector2(x1, y1), Vector2(x2, y2), bone_c, 5, true)
			draw_line(Vector2(x1, y1), Vector2(x2, y2), bone_l, 2, true)
			for ep in [Vector2(x1, y1), Vector2(x2, y2)]:
				draw_circle(ep + Vector2(2, 2), r * 0.115, SHADOW)
				draw_circle(ep, r * 0.115, bone_d)
				draw_circle(ep, r * 0.085, bone_c)
				draw_circle(ep, r * 0.050, bone_l)
		# Skull cranium shadow
		draw_circle(Vector2(cx + 2, cy - r * 0.14 + 3), r * 0.44, SHADOW)
		# Cranium
		draw_circle(Vector2(cx, cy - r * 0.14), r * 0.44, BONE)
		# Cheekbones slight bulge
		for s in [-1.0, 1.0]:
			draw_circle(Vector2(cx + s * r * 0.28, cy + r * 0.10), r * 0.20, BONE)
		# Jaw
		var jaw := PackedVector2Array([
			Vector2(cx - r * 0.32, cy + r * 0.10),
			Vector2(cx - r * 0.35, cy + r * 0.32),
			Vector2(cx - r * 0.24, cy + r * 0.42),
			Vector2(cx,            cy + r * 0.44),
			Vector2(cx + r * 0.24, cy + r * 0.42),
			Vector2(cx + r * 0.35, cy + r * 0.32),
			Vector2(cx + r * 0.32, cy + r * 0.10),
		])
		draw_polygon(jaw, [BONE])
		# Teeth (4 upper)
		for i in 4:
			var tx := cx - r * 0.26 + float(i) * r * 0.17
			draw_rect(Rect2(tx, cy + r * 0.16, r * 0.13, r * 0.20), Color(0.941, 0.910, 0.847, 1))
			draw_rect(Rect2(tx + r * 0.01, cy + r * 0.17, r * 0.11, r * 0.17), Color(1, 0.973, 0.910, 1))
		# Jaw line
		draw_polyline(jaw, Color(0.627, 0.596, 0.533, 0.5), 1.5, true)
		# Eye sockets (deep hollows)
		for s in [-1.0, 1.0]:
			draw_circle(Vector2(cx + s * r * 0.19, cy - r * 0.10), r * 0.135, Color(0.047, 0.031, 0.094, 1))
			draw_circle(Vector2(cx + s * r * 0.19, cy - r * 0.10), r * 0.090, Color(0.016, 0.008, 0.063, 1))
		# Nasal cavity
		var nose := PackedVector2Array([
			Vector2(cx, cy + r * 0.04),
			Vector2(cx - r * 0.08, cy + r * 0.16),
			Vector2(cx + r * 0.08, cy + r * 0.16),
		])
		draw_polygon(nose, [Color(0.047, 0.031, 0.094, 1)])
		# Cranium shading (brow ridge)
		draw_arc(Vector2(cx - r * 0.08, cy - r * 0.30), r * 0.2,
			PI * 1.1, PI * 1.72, 16, Color(1, 1, 1, 0.38), 5.0, true)
		# Cheek highlight
		draw_arc(Vector2(cx - r * 0.28, cy + r * 0.06), r * 0.12,
			PI * 1.2, PI * 1.8, 12, Color(1, 1, 1, 0.22), 3.0, true)

	# ── JOLLY ROGER (SCATTER) ─────────────────────────────────────────────────
	func _draw_scatter(cx: float, cy: float) -> void:
		var r := size.x * 0.43
		# Pole
		draw_line(Vector2(cx - r * 0.58 + 2, cy - r * 0.96 + 2),
			Vector2(cx - r * 0.58 + 2, cy + r * 0.90 + 2), SHADOW, 6, true)
		draw_line(Vector2(cx - r * 0.58, cy - r * 0.96),
			Vector2(cx - r * 0.58, cy + r * 0.90), WOOD_DK, 6, true)
		draw_line(Vector2(cx - r * 0.58, cy - r * 0.96),
			Vector2(cx - r * 0.58, cy + r * 0.90), WOOD_LT, 3, true)
		draw_line(Vector2(cx - r * 0.58, cy - r * 0.96),
			Vector2(cx - r * 0.58, cy + r * 0.90), Color(1, 1, 1, 0.12), 1.5, true)
		# Flag body (rippled black)
		var flag := PackedVector2Array([
			Vector2(cx - r * 0.58, cy - r * 0.94),
			Vector2(cx + r * 0.78, cy - r * 0.78),
			Vector2(cx + r * 0.74, cy - r * 0.44),
			Vector2(cx + r * 0.80, cy - r * 0.10),
			Vector2(cx + r * 0.76, cy + r * 0.14),
			Vector2(cx - r * 0.58, cy + r * 0.14),
		])
		draw_polygon(flag, [Color(0.016, 0.008, 0.047, 1)])
		# Flag ripple shading
		draw_line(Vector2(cx - r * 0.58, cy - r * 0.40), Vector2(cx + r * 0.78, cy - r * 0.44),
			Color(1, 1, 1, 0.06), 3.0, true)
		draw_line(Vector2(cx - r * 0.58, cy - r * 0.10), Vector2(cx + r * 0.78, cy - r * 0.10),
			Color(1, 1, 1, 0.04), 2.0, true)
		# Flag border
		draw_polyline(flag, Color(0.094, 0.063, 0.188, 1), 2.0, true)
		# Mini skull on flag
		var fc := Vector2(cx + r * 0.12, cy - r * 0.40)
		draw_circle(fc, r * 0.24, Color(0.910, 0.878, 0.816, 1))
		for s2 in [-1.0, 1.0]:
			draw_circle(Vector2(fc.x + s2 * r * 0.10, fc.y - r * 0.04), r * 0.075,
				Color(0.016, 0.008, 0.063, 1))
		var fn_pts := PackedVector2Array([
			Vector2(fc.x, fc.y + r * 0.06),
			Vector2(fc.x - r * 0.055, fc.y + r * 0.14),
			Vector2(fc.x + r * 0.055, fc.y + r * 0.14),
		])
		draw_polygon(fn_pts, [Color(0.016, 0.008, 0.063, 1)])
		# Mini crossbones on flag
		for flip2 in [-1.0, 1.0]:
			draw_line(
				Vector2(fc.x + flip2 * r * 0.22, fc.y + r * 0.22),
				Vector2(fc.x - flip2 * r * 0.22, fc.y + r * 0.44),
				Color(0.910, 0.878, 0.816, 0.9), 3, true)
		# SCATTER label on flag
		draw_string(ThemeDB.fallback_font,
			Vector2(cx - r * 0.42, cy + r * 0.08),
			"SCATTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, GOLD)

	# ── MULTIPLIER COIN ───────────────────────────────────────────────────────
	func _draw_mult_coin(cx: float, cy: float) -> void:
		var r := size.x * 0.43
		# Shadow
		draw_circle(Vector2(cx + 3, cy + 4), r, SHADOW)
		# Coin layers
		draw_circle(Vector2(cx, cy), r,        Color(0.439, 0.282, 0.016, 1))
		draw_circle(Vector2(cx, cy), r * 0.92, Color(0.722, 0.502, 0.047, 1))
		draw_circle(Vector2(cx, cy), r * 0.84, GOLD_DK)
		draw_circle(Vector2(cx, cy), r * 0.76, GOLD)
		# Inner ring
		draw_arc(Vector2(cx, cy), r * 0.68, 0, TAU, 48, GOLD_DK, 3.0, true)
		# Knurled edge detail
		for i in 16:
			var ang := float(i) / 16.0 * TAU
			var ep  := Vector2(cx + cos(ang) * r * 0.94, cy + sin(ang) * r * 0.94)
			draw_circle(ep, 2.0, Color(0.502, 0.345, 0.016, 1))
		# Multiplier text
		var label     := str(mult_val) + "x"
		var fsize     := 18 if mult_val < 10 else (14 if mult_val < 100 else 11)
		var text_w    := float(len(label)) * float(fsize) * 0.55
		draw_string(ThemeDB.fallback_font,
			Vector2(cx - text_w * 0.5, cy + float(fsize) * 0.38),
			label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(0.125, 0.063, 0.016, 1))
		# Highlight arc
		draw_arc(Vector2(cx - r * 0.14, cy - r * 0.20), r * 0.36,
			PI * 1.08, PI * 1.78, 20, Color(1, 1, 1, 0.48), 4.5, true)


# ── STATE ─────────────────────────────────────────────────────────────────────

enum State { IDLE, SPINNING }

var _state    : State = State.IDLE
var _fading   : bool  = false
var _bet      : float = 10.0
var _spin_win : float = 0.0
var _in_fs    : bool  = false
var _fs_left  : int   = 0

# Grid: -1=empty, 0-8=regular sym, SYM_SCATTER=9, SYM_MULT=10
var _grid      : Array[int] = []
var _mult_vals : Array[int] = []   # mult value per cell (0 if not a mult)
var _slots     : Array      = []   # Panel slot backgrounds
var _sym_nodes : Array      = []   # SymbolNode per cell (null=empty)

var _grid_node  : Control
var _sym_layer  : Control
var _fade_rect  : ColorRect
var _bet_input  : LineEdit
var _bal_lbl    : Label
var _win_lbl    : Label
var _spin_btn   : Button
var _buy_btn    : Button
var _fs_lbl        : Label
var _mult_disp     : Label
var _total_win_lbl : Label


# ── SETUP ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_fade_rect = find_child("FadeRect", true, false) as ColorRect
	var back   := find_child("BackBtn",  true, false) as Button
	if back:
		back.pressed.connect(_on_back)
	_grid.resize(NCELLS);     _grid.fill(-1)
	_mult_vals.resize(NCELLS); _mult_vals.fill(0)
	_slots.resize(NCELLS)
	_sym_nodes.resize(NCELLS); _sym_nodes.fill(null)
	_build_layout()
	_build_grid_nodes()
	_randomize_grid(false)
	_spawn_all_syms(false)
	_update_hud()
	_fade_in()


# ── LAYOUT ────────────────────────────────────────────────────────────────────

func _make_sb(bg: Color, border: Color = COL_BORDER, bw: int = 2) -> StyleBoxFlat:
	var sb           := StyleBoxFlat.new()
	sb.bg_color       = bg
	sb.border_color   = border
	sb.border_width_left   = bw
	sb.border_width_right  = bw
	sb.border_width_top    = bw
	sb.border_width_bottom = bw
	return sb


func _build_layout() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	move_child(center, 1)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	center.add_child(hbox)

	hbox.add_child(_build_left_panel())
	hbox.add_child(_build_right_area())


func _build_left_panel() -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(220, 0)
	panel.add_theme_stylebox_override("panel", _make_sb(COL_PANEL))

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mg.add_theme_constant_override(side, 16)
	panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	var title := Label.new()
	title.text                 = "PIRATE'S BOOTY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COL_GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title)

	_add_div(vbox)
	vbox.add_child(_small_lbl("BET"))
	_bet_input      = LineEdit.new()
	_bet_input.text = str(int(_bet))
	_bet_input.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_bet_input)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	vbox.add_child(hb)
	for pair in [["1/2", "_on_half"], ["2×", "_on_double"]]:
		var b := Button.new()
		b.text                  = pair[0]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(Callable(self, pair[1]))
		hb.add_child(b)

	_add_div(vbox)

	_spin_btn                     = Button.new()
	_spin_btn.text                = "SPIN"
	_spin_btn.custom_minimum_size = Vector2(0, 52)
	_spin_btn.add_theme_font_size_override("font_size", 18)
	_spin_btn.pressed.connect(_on_spin)
	vbox.add_child(_spin_btn)

	_buy_btn                     = Button.new()
	_buy_btn.text                = "BUY BONUS\n(100× BET)"
	_buy_btn.custom_minimum_size = Vector2(0, 40)
	_buy_btn.add_theme_font_size_override("font_size", 12)
	_buy_btn.pressed.connect(_on_buy_bonus)
	vbox.add_child(_buy_btn)

	_add_div(vbox)

	vbox.add_child(_small_lbl("BALANCE"))
	_bal_lbl = Label.new()
	_bal_lbl.add_theme_font_size_override("font_size", 14)
	_bal_lbl.add_theme_color_override("font_color", COL_GREEN)
	vbox.add_child(_bal_lbl)

	vbox.add_child(_small_lbl("WIN"))
	_win_lbl      = Label.new()
	_win_lbl.text = "$0"
	_win_lbl.add_theme_font_size_override("font_size", 14)
	_win_lbl.add_theme_color_override("font_color", COL_GOLD)
	vbox.add_child(_win_lbl)

	_add_div(vbox)

	_fs_lbl      = Label.new()
	_fs_lbl.text = ""
	_fs_lbl.add_theme_font_size_override("font_size", 13)
	_fs_lbl.add_theme_color_override("font_color", COL_GREEN)
	_fs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fs_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_fs_lbl)

	_mult_disp      = Label.new()
	_mult_disp.text = ""
	_mult_disp.add_theme_font_size_override("font_size", 12)
	_mult_disp.add_theme_color_override("font_color", COL_GOLD)
	_mult_disp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mult_disp.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_mult_disp)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	return panel


func _build_right_area() -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var info := Label.new()
	info.text = "8+ matching symbols anywhere wins  ·  coins multiply wins  ·  4+ flags = free spins"
	info.add_theme_font_size_override("font_size", 10)
	info.add_theme_color_override("font_color", COL_BLUE)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.custom_minimum_size = Vector2(COLS * CELL_SIZE, 0)
	vbox.add_child(info)

	_grid_node                       = Control.new()
	_grid_node.custom_minimum_size   = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	_grid_node.clip_contents         = true
	_grid_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(_grid_node)

	_sym_layer             = Control.new()
	_sym_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sym_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sym_layer.z_index     = 1
	_grid_node.add_child(_sym_layer)

	# Big win display below grid
	_total_win_lbl                       = Label.new()
	_total_win_lbl.text                  = ""
	_total_win_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_total_win_lbl.add_theme_font_size_override("font_size", 36)
	_total_win_lbl.add_theme_color_override("font_color", COL_GOLD)
	_total_win_lbl.custom_minimum_size   = Vector2(COLS * CELL_SIZE, 50)
	vbox.add_child(_total_win_lbl)

	return vbox


func _add_div(parent: Control) -> void:
	var d := Panel.new()
	d.custom_minimum_size = Vector2(0, 2)
	d.add_theme_stylebox_override("panel", _make_sb(COL_BORDER, COL_BORDER, 0))
	parent.add_child(d)


func _small_lbl(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", COL_BLUE)
	return l


# ── GRID NODES ────────────────────────────────────────────────────────────────

func _build_grid_nodes() -> void:
	var sb := _make_sb(Color(0.008, 0.016, 0.063, 1), Color(0.188, 0.125, 0.047, 1), 1)
	for i in NCELLS:
		var slot      := Panel.new()
		slot.position  = Vector2((i % COLS) * CELL_SIZE, (i / COLS) * CELL_SIZE)
		slot.size      = Vector2(CELL_SIZE, CELL_SIZE)
		slot.add_theme_stylebox_override("panel", sb)
		_grid_node.add_child(slot)
		_slots[i] = slot


func _sym_pos(i: int) -> Vector2:
	return Vector2((i % COLS) * CELL_SIZE + 4.0, (i / COLS) * CELL_SIZE + 4.0)


func _make_sym_node(sym: int, mv: int, pos: Vector2) -> SymbolNode:
	var n := SymbolNode.new(sym, mv)
	n.position = pos
	_sym_layer.add_child(n)
	return n


func _clear_all_syms() -> void:
	for i in NCELLS:
		_sym_nodes[i] = null
	for child in _sym_layer.get_children():
		child.free()


# Spawn symbol nodes. If animate=true, start above grid for drop-in.
# If free_spins=true, preserve existing mult nodes.
func _spawn_all_syms(animate: bool, preserve_mults: bool = false) -> void:
	if not preserve_mults:
		_clear_all_syms()
	for i in NCELLS:
		if _grid[i] == -1:
			continue
		if preserve_mults and _grid[i] == SYM_MULT and _sym_nodes[i] != null:
			continue   # keep existing mult node in place
		if _sym_nodes[i]:
			(_sym_nodes[i] as SymbolNode).queue_free()
			_sym_nodes[i] = null
		var dest := _sym_pos(i)
		var start_y : float = dest.y if not animate else dest.y - float(ROWS) * CELL_SIZE
		_sym_nodes[i] = _make_sym_node(_grid[i], _mult_vals[i], Vector2(dest.x, start_y))


# ── RANDOMIZATION ─────────────────────────────────────────────────────────────

func _rand_sym() -> int:
	var total := 0
	for w in SYM_WEIGHTS:
		total += w
	var pick := randi() % total
	var acc  := 0
	for idx in SYM_WEIGHTS.size():
		acc += SYM_WEIGHTS[idx]
		if pick < acc:
			return idx
	return 0


func _rand_mult_val() -> int:
	var total := 0
	for w in MULT_WEIGHTS:
		total += w
	var pick := randi() % total
	var acc  := 0
	for idx in MULT_WEIGHTS.size():
		acc += MULT_WEIGHTS[idx]
		if pick < acc:
			return MULT_VALUES[idx]
	return 2


func _rand_orb_count(in_fs: bool) -> int:
	var weights := ORB_COUNT_WEIGHTS_FS if in_fs else ORB_COUNT_WEIGHTS_BASE
	var total := 0
	for w in weights:
		total += w
	var pick := randi() % total
	var acc  := 0
	for idx in weights.size():
		acc += weights[idx]
		if pick < acc:
			return idx
	return 0


# Randomize grid. In free spins, preserve existing mult cells then add new orbs.
func _randomize_grid(in_fs: bool) -> void:
	# Step 1: fill all non-preserved cells with regular symbols
	for i in NCELLS:
		if in_fs and _grid[i] == SYM_MULT:
			continue
		_grid[i]      = _rand_sym()
		_mult_vals[i] = 0
	# Step 2: place 0–4 orbs on random non-mult cells (GoO mechanic)
	var n_orbs := _rand_orb_count(in_fs)
	var available : Array[int] = []
	for i in NCELLS:
		if _grid[i] != SYM_MULT:
			available.append(i)
	available.shuffle()
	for i in mini(n_orbs, available.size()):
		var cell        := available[i]
		_grid[cell]      = SYM_MULT
		_mult_vals[cell] = _rand_mult_val()


# ── SPIN FLOW ─────────────────────────────────────────────────────────────────

func _on_spin() -> void:
	if _state != State.IDLE or _fading:
		return
	var raw := _bet_input.text.strip_edges()
	if not raw.is_valid_float():
		_win_lbl.text = "Invalid bet"
		return
	var bv := float(raw)
	if bv < MIN_BET:
		_win_lbl.text = "Min $" + str(int(MIN_BET))
		return
	if bv > GameState.bankroll:
		_win_lbl.text = "Not enough"
		return
	_bet = bv
	_do_spin()


func _on_buy_bonus() -> void:
	if _state != State.IDLE or _fading or _in_fs:
		return
	var raw := _bet_input.text.strip_edges()
	if not raw.is_valid_float():
		_win_lbl.text = "Invalid bet"
		return
	var bv := float(raw)
	if bv < MIN_BET:
		_win_lbl.text = "Min $" + str(int(MIN_BET))
		return
	var cost := bv * BUY_MULT
	if cost > GameState.bankroll:
		_win_lbl.text = "Need $" + _fmt(cost)
		return
	_bet = bv
	GameState.bankroll -= cost
	_spin_win = 0.0
	_update_hud()
	_trigger_free_spins(FS_BASE)


func _do_spin() -> void:
	_spin_win          = 0.0
	_state             = State.SPINNING
	_spin_btn.disabled = true
	_buy_btn.disabled  = true
	_win_lbl.text      = "$0"
	if _total_win_lbl:
		_total_win_lbl.text = ""
	if not _in_fs:
		GameState.bankroll -= _bet
	_update_hud()

	_randomize_grid(_in_fs)
	_spawn_all_syms(true, _in_fs)
	_animate_drop_in(_on_drop_complete)


func _on_drop_complete() -> void:
	# Check for scatter trigger / retrigger
	var sc_count := 0
	for i in NCELLS:
		if _grid[i] == SYM_SCATTER:
			sc_count += 1

	if _in_fs and sc_count >= FS_RETRIG_SC:
		_fs_left += FS_RETRIG
		_update_fs_hud()
	elif not _in_fs and sc_count >= FS_TRIGGER:
		# Payout scatter prize
		if sc_count < SCATTER_PAY.size():
			_spin_win += _bet * SCATTER_PAY[sc_count]
		_run_tumble_chain(true)  # finish tumbles then trigger FS
		return

	_run_tumble_chain(false)


func _run_tumble_chain(trigger_fs_after: bool = false) -> void:
	var wins := _find_wins()
	if wins.is_empty():
		_finish_spin(trigger_fs_after)
		return

	var tumble_win := 0.0
	var removed : Array[int] = []
	for sym : int in wins:
		var cells : Array = wins[sym]
		var cnt   : int   = cells.size()
		tumble_win += _bet * _payout_mult(sym, cnt)
		for idx : int in cells:
			removed.append(idx)
			_grid[idx] = -1

	# Apply multiplier coins currently on grid
	var mult_sum := _sum_mults()
	if mult_sum > 1:
		tumble_win *= float(mult_sum)

	_spin_win += tumble_win
	var win_str := "$" + _fmt(_spin_win)
	_win_lbl.text = win_str
	if _total_win_lbl:
		_total_win_lbl.text = win_str
	if mult_sum > 1:
		_mult_disp.text = "×" + str(mult_sum) + " multiplier!"

	_animate_remove(removed, func() -> void:
		_animate_tumble(func() -> void:
			var tw := create_tween()
			tw.tween_interval(0.18)
			tw.tween_callback(func() -> void:
				_run_tumble_chain(trigger_fs_after)
			)
		)
	)


# ── WIN DETECTION ─────────────────────────────────────────────────────────────

# Returns {sym_id: [cell_indices, ...]} for symbols with 8+ anywhere on grid.
func _find_wins() -> Dictionary:
	var counts : Dictionary = {}
	var cells  : Dictionary = {}
	for i in NCELLS:
		var s := _grid[i]
		if s < 0 or s == SYM_SCATTER or s == SYM_MULT:
			continue
		if not counts.has(s):
			counts[s] = 0
			cells[s]  = []
		counts[s] += 1
		cells[s].append(i)
	var result : Dictionary = {}
	for s in counts:
		if counts[s] >= MIN_WIN:
			result[s] = cells[s]
	return result


func _sum_mults() -> int:
	var total := 0
	for i in NCELLS:
		if _grid[i] == SYM_MULT:
			total += _mult_vals[i]
	return maxi(total, 1)


func _payout_mult(sym: int, count: int) -> float:
	if sym < 0 or sym >= PAYTABLE.size():
		return 0.0
	var tier := 0
	if count >= 12:
		tier = 2
	elif count >= 10:
		tier = 1
	return PAYTABLE[sym][tier]


# ── ANIMATIONS ────────────────────────────────────────────────────────────────

func _animate_drop_in(callback: Callable) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	for i in NCELLS:
		var node := _sym_nodes[i] as SymbolNode
		if not node:
			continue
		var dest_y : float = _sym_pos(i).y
		var col    : int   = i % COLS
		tw.tween_property(node, "position:y", dest_y, 0.55)\
			.set_delay(col * 0.05)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_QUAD)
	tw.set_parallel(false)
	tw.tween_callback(callback)


func _animate_remove(indices: Array[int], callback: Callable) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	for idx in indices:
		if _sym_nodes[idx]:
			tw.tween_property(_sym_nodes[idx], "modulate:a", 0.0, 0.22)
	tw.set_parallel(false)
	tw.tween_callback(func() -> void:
		for idx in indices:
			if _sym_nodes[idx] and is_instance_valid(_sym_nodes[idx]):
				_sym_nodes[idx].free()
			_sym_nodes[idx] = null
		callback.call()
	)


func _animate_tumble(callback: Callable) -> void:
	# Apply gravity to _grid data
	for c in COLS:
		var write := ROWS - 1
		for r2 in range(ROWS - 1, -1, -1):
			var idx := r2 * COLS + c
			if _grid[idx] != -1:
				if write != r2:
					_grid[write * COLS + c]     = _grid[idx]
					_mult_vals[write * COLS + c] = _mult_vals[idx]
					_grid[idx]      = -1
					_mult_vals[idx] = 0
				write -= 1
		# Fill empty top rows with new regular symbols
		for r2 in range(write, -1, -1):
			_grid[r2 * COLS + c]      = _rand_sym()
			_mult_vals[r2 * COLS + c] = 0

	# Nuke every node and respawn cleanly — eliminates all tracking bugs
	_clear_all_syms()
	_spawn_all_syms(true, _in_fs)
	_animate_drop_in(callback)


# ── FREE SPINS ────────────────────────────────────────────────────────────────

func _trigger_free_spins(count: int) -> void:
	_in_fs   = true
	_fs_left = count
	# Clear any base-game mults — accumulation starts fresh inside the bonus
	for i in NCELLS:
		if _grid[i] == SYM_MULT:
			_grid[i]      = -1
			_mult_vals[i] = 0
			if _sym_nodes[i]:
				(_sym_nodes[i] as SymbolNode).queue_free()
				_sym_nodes[i] = null
	_update_fs_hud()
	_show_bonus_intro(count, _next_free_spin)


func _show_bonus_intro(spins: int, callback: Callable) -> void:
	var overlay := Panel.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index   = 80
	overlay.modulate.a = 0.0
	var sb := StyleBoxFlat.new()
	sb.bg_color            = Color(0.0, 0.0, 0.0, 0.88)
	sb.border_color        = COL_GOLD
	sb.border_width_left   = 4
	sb.border_width_right  = 4
	sb.border_width_top    = 4
	sb.border_width_bottom = 4
	overlay.add_theme_stylebox_override("panel", sb)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var t1 := Label.new()
	t1.text                = "⚓  FREE SPINS  ⚓"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 52)
	t1.add_theme_color_override("font_color", COL_GOLD)
	vbox.add_child(t1)

	var t2 := Label.new()
	t2.text                = str(spins) + " FREE SPINS AWARDED!"
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_font_size_override("font_size", 28)
	t2.add_theme_color_override("font_color", COL_GREEN)
	vbox.add_child(t2)

	var t3 := Label.new()
	t3.text                = "Doubloon coins accumulate all bonus!"
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t3.add_theme_font_size_override("font_size", 16)
	t3.add_theme_color_override("font_color", COL_BLUE)
	vbox.add_child(t3)

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(overlay, "modulate:a", 1.0, 0.35)
	tw.tween_interval(2.5)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void:
		overlay.queue_free()
		callback.call()
	)


func _next_free_spin() -> void:
	if _fs_left <= 0:
		_end_free_spins()
		return
	_fs_left -= 1
	_spin_btn.disabled = true
	_buy_btn.disabled  = true
	_update_fs_hud()
	_do_spin()


func _end_free_spins() -> void:
	_in_fs = false
	# Clear all mult orbs on exit
	for i in NCELLS:
		if _grid[i] == SYM_MULT:
			_grid[i]      = -1
			_mult_vals[i] = 0
			if _sym_nodes[i]:
				(_sym_nodes[i] as SymbolNode).queue_free()
				_sym_nodes[i] = null
	_mult_disp.text = ""
	_fs_lbl.text    = ""
	_state             = State.IDLE
	_spin_btn.disabled = false
	_buy_btn.disabled  = false
	_update_hud()


func _update_fs_hud() -> void:
	if _in_fs:
		_fs_lbl.text = "FREE SPINS: " + str(_fs_left) + " left"
	else:
		_fs_lbl.text = ""
	# Show accumulated mult total
	var ms := _sum_mults()
	if _in_fs and ms > 1:
		_mult_disp.text = "Coin pool: ×" + str(ms)
	else:
		_mult_disp.text = ""


# ── FINISH ────────────────────────────────────────────────────────────────────

func _finish_spin(trigger_fs_after: bool = false) -> void:
	if _spin_win > 0.0:
		GameState.bankroll += _spin_win
		GameState.add_fame(TOWN_ID, _spin_win * 0.1)
		_win_lbl.text = "+$" + _fmt(_spin_win)
	else:
		_win_lbl.text = "$0"

	if trigger_fs_after:
		_trigger_free_spins(FS_BASE)
		return

	if _in_fs:
		var tw := create_tween()
		tw.tween_interval(0.5)
		tw.tween_callback(_next_free_spin)
		return

	_state             = State.IDLE
	_spin_btn.disabled = false
	_buy_btn.disabled  = false
	_update_hud()


# ── HUD ───────────────────────────────────────────────────────────────────────

func _update_hud() -> void:
	if _bal_lbl:
		var br := GameState.bankroll
		_bal_lbl.text = "$" + _fmt(br)
		_bal_lbl.add_theme_color_override("font_color",
			COL_RED if br < 200.0 else COL_GREEN)
	_update_fs_hud()


# ── BET HELPERS ───────────────────────────────────────────────────────────────

func _on_half() -> void:
	_bet            = max(MIN_BET, floor(_bet * 0.5))
	_bet_input.text = str(int(_bet))


func _on_double() -> void:
	_bet            = min(GameState.bankroll, _bet * 2.0)
	_bet_input.text = str(int(_bet))


# ── TRANSITIONS ───────────────────────────────────────────────────────────────

func _fade_in() -> void:
	if not _fade_rect:
		return
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade_rect, "color:a", 0.0, 0.4)


func _on_back() -> void:
	if _fading or _state != State.IDLE or _in_fs:
		return
	_fading = true
	if not _fade_rect:
		get_tree().call_deferred("change_scene_to_file",
			"res://scenes/main_menu/MainMenu.tscn")
		return
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade_rect, "color:a", 1.0, 0.3)
	tw.tween_callback(func() -> void:
		get_tree().call_deferred("change_scene_to_file",
			"res://scenes/main_menu/MainMenu.tscn"))


# ── HELPERS ───────────────────────────────────────────────────────────────────

func _fmt(val: float) -> String:
	if val >= 1_000_000.0:
		return "%.1fM" % (val / 1_000_000.0)
	if val >= 1_000.0:
		return "%.1fK" % (val / 1_000.0)
	return str(int(val))
