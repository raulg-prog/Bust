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

	# Outer wood border
	draw_circle(Vector2(cx, cy), r,        Color(0.314, 0.188, 0.063, 1))
	# Track
	draw_circle(Vector2(cx, cy), r * 0.96, Color(0.063, 0.047, 0.031, 1))

	# Pockets
	for i in N:
		var num := WHEEL_ORDER[i]
		var a0  := float(i) * seg + wheel_rot - TAU * 0.25
		var a1  := a0 + seg

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
		pts.append(Vector2(cx, cy))
		for s in 10:
			var a := a0 + seg * float(s) / 9.0
			pts.append(Vector2(cx + cos(a) * r * 0.93, cy + sin(a) * r * 0.93))
		draw_polygon(pts, PackedColorArray([col]))

		# Divider
		draw_line(
			Vector2(cx + cos(a0) * r * 0.30, cy + sin(a0) * r * 0.30),
			Vector2(cx + cos(a0) * r * 0.93, cy + sin(a0) * r * 0.93),
			Color(0.314, 0.188, 0.063, 0.8), 1.5
		)

	# Hub rings
	draw_circle(Vector2(cx, cy), r * 0.30, Color(0.157, 0.094, 0.031, 1))
	draw_circle(Vector2(cx, cy), r * 0.24, Color(0.314, 0.188, 0.063, 1))
	draw_circle(Vector2(cx, cy), r * 0.15, Color(0.094, 0.063, 0.031, 1))
	draw_circle(Vector2(cx, cy), r * 0.08, Color(0.502, 0.314, 0.094, 1))

	# Ball
	if show_ball:
		var br := r * 0.86
		var bx := cx + cos(ball_angle) * br
		var by := cy + sin(ball_angle) * br
		draw_circle(Vector2(bx, by), 7.0, Color(0.973, 0.973, 0.973, 1))
		draw_circle(Vector2(bx, by), 4.5, Color(0.627, 0.627, 0.627, 1))

	# Fixed gold pointer at 12 o'clock
	var tip := Vector2(cx, cy - r * 0.95)
	var pl  := Vector2(cx - 9, cy - r * 1.04)
	var pr  := Vector2(cx + 9, cy - r * 1.04)
	draw_polygon(PackedVector2Array([tip, pl, pr]),
		PackedColorArray([Color(0.973, 0.847, 0.188, 1)]))
