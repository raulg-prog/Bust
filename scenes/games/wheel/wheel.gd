extends Control

const TOWN_ID  := 1
const MIN_BET  := 10.0
const SPIN_REV := 6   # full rotations added before landing

# Segments clockwise from 12 o'clock — must match the wheel image exactly
# 1.0 = Spin Again (return bet, free re-spin, no Fame change)
# EV = 1.0: 2(1)+2(3)+1(5)+2(2)+3(0.5)+4(0.25)+5(0.1)+1(0) / 20 = 1.0
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
@onready var wheel_image   : TextureRect = %WheelImage
@onready var pivot_marker  : Control     = %PivotMarker


func _ready() -> void:
	spin_btn.pressed.connect(_on_spin)
	await get_tree().process_frame
	# Pivot is the center of PivotMarker, expressed in WheelImage's local space.
	# Drag PivotMarker in the editor until it sits on the wheel hub, then it's exact.
	var hub := pivot_marker.position + pivot_marker.size / 2.0
	wheel_image.pivot_offset = hub - wheel_image.position
	pivot_marker.hide()
	_update_hud()


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

	# Segment i's center sits at i*(TAU/n) clockwise from 12 o'clock in the image.
	# To bring it to the pointer (top), rotate the wheel CCW by that same angle.
	var seg_angle := TAU / float(n)
	var land_r    := -float(win_idx) * seg_angle

	# Find the equivalent landing angle that is at least SPIN_REV full rotations
	# counter-clockwise from the current rotation.
	var cur      := wheel_image.rotation
	var excess   := fposmod(cur - land_r, TAU)   # overshoot past landing in [0, TAU)
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

	# delta is positive (profit) or negative (loss)
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
