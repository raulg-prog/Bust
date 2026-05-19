class_name DiceSlider
extends Control

signal threshold_changed(value: int)

var threshold      : int   = 50
var mode_over      : bool  = true

# display_result drives the animated circle — setter auto-redraws each tween step
var display_result : float = 99.99 :
	set(v):
		display_result = v
		queue_redraw()

var show_result : bool = false :
	set(v):
		show_result = v
		queue_redraw()

var _dragging : bool = false

const TRACK_H  : float = 14.0
const MARKER_W : float = 8.0
const RESULT_R : float = 9.0
const CHIP_R   : float = 30.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_update_from_x(event.position.x)
	elif event is InputEventMouseMotion and _dragging:
		_update_from_x(event.position.x)


func _update_from_x(mx: float) -> void:
	if size.x == 0.0:
		return
	var new_t := int(clamp(mx / size.x * 100.0, 2.0, 98.0))
	if new_t != threshold:
		threshold = new_t
		queue_redraw()
		threshold_changed.emit(threshold)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w == 0.0 or h == 0.0:
		return

	# Track sits near the bottom to leave room for the result circle above
	var cy    := h * 0.85
	var split := float(threshold) / 100.0 * w
	var ty    := cy - TRACK_H * 0.5

	var lose_c := Color(0.973, 0.376, 0.376, 1)
	var win_c  := Color(0.376, 0.973, 0.502, 1)
	var dim_c  := Color(0.627, 0.627, 0.753, 1)
	var white  := Color(0.973, 0.973, 0.973, 1)

	# Two-colour track
	var left_c  : Color = lose_c if mode_over else win_c
	var right_c : Color = win_c  if mode_over else lose_c
	if split > 0.0:
		draw_rect(Rect2(0.0, ty, split, TRACK_H), left_c)
	if split < w:
		draw_rect(Rect2(split, ty, w - split, TRACK_H), right_c)

	# Tick marks + labels at 0 / 25 / 50 / 75 / 100
	var font      := ThemeDB.fallback_font
	var font_size := 11
	for tick in [0, 25, 50, 75, 100]:
		var tx := float(tick) / 100.0 * w
		draw_rect(Rect2(tx - 1.0, ty - 8.0, 2.0, 8.0), dim_c)
		draw_string(font, Vector2(tx - 10.0, ty - 10.0), str(tick),
					HORIZONTAL_ALIGNMENT_CENTER, 20, font_size, dim_c)

	# Threshold handle
	draw_rect(Rect2(split - MARKER_W * 0.5, ty - 5.0, MARKER_W, TRACK_H + 10.0), white)

	# Result circle — follows the animated display_result, stays visible between rolls
	if show_result:
		var rx    : float = clamp(display_result / 100.0, 0.0, 1.0) * w
		var won   := (mode_over     and display_result >= float(threshold)) or \
					 (not mode_over and display_result <  float(threshold))
		var dot_c := win_c if won else lose_c

		# Circle sits above the tick labels
		var chip_cy := ty - 56.0

		# Single solid circle with result number inside
		draw_circle(Vector2(rx, chip_cy), CHIP_R, dot_c)
		var txt := "%.2f" % display_result
		draw_string(font, Vector2(rx - 26.0, chip_cy + 6.0), txt,
					HORIZONTAL_ALIGNMENT_CENTER, 52, 14, white)

		# Ball dot on track
		draw_circle(Vector2(rx, cy), RESULT_R,       dot_c)
		draw_circle(Vector2(rx, cy), RESULT_R - 3.0, white)
