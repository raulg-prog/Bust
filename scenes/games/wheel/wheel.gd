extends Control

const TOWN_ID  := 1
const MIN_BET  := 10.0
const SPIN_REV := 6   # full rotations added before landing

# Segments clockwise from 12 o'clock — must match the wheel image exactly
# 1.0 = Spin Again (return bet, free re-spin, no Fame change)
const SEGMENTS: Array[float] = [
	1.0,   # 0  Spin Again
	3.0,   # 1  3x
	0.1,   # 2  0.1x
	0.5,   # 3  0.5x
	0.25,  # 4  0.25x
	5.0,   # 5  5x
	0.1,   # 6  0.1x
	0.25,  # 7  0.25x
	2.0,   # 8  2x
	0.1,   # 9  0.1x
	1.0,   # 10 Spin Again
	0.1,   # 11 0.1x
	3.0,   # 12 3x
	0.5,   # 13 0.5x
	0.25,  # 14 0.25x
	0.0,   # 15 0x
	0.25,  # 16 0.25x
	0.5,   # 17 0.5x
	0.1,   # 18 0.1x
	2.0,   # 19 2x
]

enum State { IDLE, SPINNING }

var state       : State = State.IDLE
var current_bet : float = 0.0

@onready var balance_label : Label       = %BalanceLabel
@onready var fame_label    : Label       = %FameLabel
@onready var result_label  : Label       = %ResultLabel
@onready var bet_input     : LineEdit    = %BetInput
@onready var spin_btn      : Button      = %SpinButton
@onready var wheel_image   : Control     = %WheelImage
@onready var pivot_marker  : Control     = %PivotMarker


func _ready() -> void:
	spin_btn.pressed.connect(_on_spin)
	await get_tree().process_frame

	# ── Wheel sizing ─────────────────────────────────────────────────────────
	# WheelArea lives inside the VBoxContainer (GameArea).
	# SIZE_SHRINK_CENTER on both axes tells the VBox to give it exactly its
	# minimum size (260×260) instead of expanding to fill all available space.
	var wheel_area := wheel_image.get_parent() as Control
	if wheel_area:
		wheel_area.custom_minimum_size   = Vector2(260.0, 260.0)
		wheel_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		wheel_area.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

	# WheelImage is inside WheelArea (a plain Control, not a Container).
	# Use PRESET_FULL_RECT so it fills WheelArea exactly — no anchor math needed.
	wheel_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	await get_tree().process_frame

	wheel_image.pivot_offset = wheel_image.size * 0.5
	pivot_marker.hide()

	# ── Move legacy TopSection / BottomSection out of the wheel's way ────────
	# The editor may have an old cached scene where these overlap the wheel.
	# Pin TopSection to the very top of the screen and BottomSection to the
	# very bottom so they are always visible regardless of wheel size.
	_pin_sections()

	if not wheel_image.resized.is_connected(queue_redraw):
		wheel_image.resized.connect(queue_redraw)
	queue_redraw()
	_update_hud()


func _pin_sections() -> void:
	var top := get_node_or_null("TopSection") as Control
	var bot := get_node_or_null("BottomSection") as Control
	if top:
		top.anchor_left   = 0.5;  top.anchor_right  = 0.5
		top.anchor_top    = 0.0;  top.anchor_bottom = 0.0
		top.offset_left   = -260.0; top.offset_right  = 260.0
		top.offset_top    = 8.0;    top.offset_bottom = 80.0
	if bot:
		bot.anchor_left   = 0.5;  bot.anchor_right  = 0.5
		bot.anchor_top    = 1.0;  bot.anchor_bottom = 1.0
		bot.offset_left   = -260.0; bot.offset_right  = 260.0
		bot.offset_top    = -90.0;  bot.offset_bottom = -8.0


func _draw() -> void:
	if not is_instance_valid(wheel_image):
		return
	var pos := wheel_image.global_position
	var sz  := wheel_image.size
	if sz.x < 1.0:
		return
	var cx     := pos.x + sz.x * 0.5
	var tip_y  := pos.y - 6.0
	var base_y := pos.y - 30.0
	var pts    := PackedVector2Array([
		Vector2(cx,        tip_y),
		Vector2(cx - 14.0, base_y),
		Vector2(cx + 14.0, base_y),
	])
	draw_colored_polygon(pts, Color(1.0, 0.878, 0.2, 1.0))
	draw_polyline(PackedVector2Array([
		Vector2(cx - 14.0, base_y),
		Vector2(cx,        tip_y),
		Vector2(cx + 14.0, base_y),
		Vector2(cx - 14.0, base_y),
	]), Color(0.0, 0.0, 0.0, 0.6), 1.5)


func _on_spin() -> void:
	if state == State.SPINNING:
		return
	var bet := bet_input.text.to_float()
	if bet < MIN_BET:
		result_label.text = "Minimum bet: $%s" % _fmt(MIN_BET)
		return
	if bet > GameState.bankroll:
		result_label.text = "Not enough funds."
		return

	current_bet       = bet
	state             = State.SPINNING
	spin_btn.disabled = true
	result_label.text = ""
	_do_spin()


func _do_spin() -> void:
	var n        := SEGMENTS.size()
	var win_idx  := randi_range(0, n - 1)
	var win_mult := SEGMENTS[win_idx]

	# Segment i's centre sits at i*(TAU/n) clockwise from 12 o'clock in the image.
	# Rotate the wheel CCW by that angle to bring it to the pointer.
	var seg_angle := TAU / float(n)
	var land_r    := -float(win_idx) * seg_angle

	var cur      := wheel_image.rotation
	var excess   := fposmod(cur - land_r, TAU)
	var target_r := cur - excess - float(SPIN_REV) * TAU

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(wheel_image, "rotation", target_r, 3.5)
	tween.tween_callback(_on_spin_complete.bind(win_mult))


func _on_spin_complete(mult: float) -> void:
	if mult == 1.0:
		result_label.text = "Spin Again!"
		await get_tree().create_timer(0.7).timeout
		result_label.text = ""
		_do_spin()
		return

	var delta := current_bet * (mult - 1.0)
	GameState.bankroll += delta

	if mult > 1.0:
		GameState.add_fame(TOWN_ID, delta)
		result_label.text = "+$%s  (%s)" % [_fmt(delta), _mult_str(mult)]
	elif mult == 0.0:
		result_label.text = "No win  —  -$%s" % _fmt(current_bet)
	else:
		result_label.text = "%s  —  -$%s" % [_mult_str(mult), _fmt(-delta)]

	state             = State.IDLE
	spin_btn.disabled = false
	_update_hud()


func _update_hud() -> void:
	balance_label.text = "Balance:  $%s" % _fmt(GameState.bankroll)
	fame_label.text    = "%s / %s Fame" % [
		_fmt(GameState.town_fame[TOWN_ID]),
		_fmt(GameState.FAME_TARGETS[TOWN_ID])
	]


func _mult_str(m: float) -> String:
	if m == 0.0:
		return "0x"
	if m == int(m):
		return "%dx" % int(m)
	var s := "%.2f" % m
	while s.ends_with("0"):
		s = s.left(s.length() - 1)
	return s + "x"


func _fmt(val: float) -> String:
	var s      := "%.0f" % val
	var result := ""
	var count  := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0 and s[i] != "-":
			result = "," + result
		result = s[i] + result
		count += 1
	return result
