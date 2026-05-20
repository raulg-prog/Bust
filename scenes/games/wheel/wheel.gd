extends Control

const TOWN_ID  := 1
const MIN_BET  := 10.0
const SPIN_REV := 6   # full rotations added before landing

# Segments clockwise from 12 o'clock — must match Wheel2.png exactly
# 1.0 = Spin Again or 1x (return bet + free re-spin, no Fame change)
# Bust segments every 5th position (4, 9, 14, 19) — evenly spaced
# EV = 1.15: 5(1)+8(0.5)+2(2)+1(10)+4(0) / 20 = 23/20
const SEGMENTS: Array[float] = [
	1.0,   # 0  Spin Again  (12:00)
	0.5,   # 1  0.5x
	1.0,   # 2  1x
	0.5,   # 3  0.5x
	0.0,   # 4  Bust
	0.5,   # 5  0.5x        (3:00)
	2.0,   # 6  2x
	0.5,   # 7  0.5x
	1.0,   # 8  1x
	0.0,   # 9  Bust
	1.0,   # 10 Spin Again  (6:00)
	0.5,   # 11 0.5x
	10.0,  # 12 Jackpot 10x
	0.5,   # 13 0.5x
	0.0,   # 14 Bust
	0.5,   # 15 0.5x        (9:00)
	2.0,   # 16 2x
	0.5,   # 17 0.5x
	1.0,   # 18 1x
	0.0,   # 19 Bust
]

# Only these indices trigger auto-respin — 1x segments return the bet but stop.
const SPIN_AGAIN_IDX: Array[int] = [0, 10]

enum State { IDLE, SPINNING }

var state           : State = State.IDLE
var current_bet     : float = 0.0
var wheel_exact_rot : float = 0.0   # canonical wheel angle — never read from wheel_image.rotation

@onready var balance_label : Label       = %BalanceLabel
@onready var fame_label    : Label       = %FameLabel
@onready var result_label  : Label       = %ResultLabel
@onready var bet_input     : LineEdit    = %BetInput
@onready var spin_btn      : BaseButton  = %SpinButton
@onready var wheel_image   : TextureRect = %WheelImage
@onready var pivot_marker  : Control     = %PivotMarker


func _ready() -> void:
	randomize()
	spin_btn.pressed.connect(_on_spin)
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://cascade.tscn"))
	# Two frames: nested containers (Center→VBox→Control) need a second pass
	# before size/position values are finalised.
	await get_tree().process_frame
	await get_tree().process_frame
	_sync_pivot()
	wheel_image.resized.connect(_sync_pivot)
	_update_hud()


func _sync_pivot() -> void:
	# pivot_marker.position is local to WheelContainer; wheel_image sits at (0,0).
	# Drag PivotMarker in the editor to fine-tune if the hub isn't centred in the PNG.
	wheel_image.pivot_offset = pivot_marker.position


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
	var n         := SEGMENTS.size()
	var win_idx   := randi_range(0, n - 1)
	var win_mult  := SEGMENTS[win_idx]

	# Segment i is centred at i*(TAU/n) clockwise from 12 o'clock.
	var seg_angle := TAU / float(n)
	var land_r    := -float(win_idx) * seg_angle

	var start_r  := wheel_exact_rot                          # always a small exact value in [-TAU, 0]
	var excess   := fposmod(start_r - land_r, TAU)           # CCW distance to travel in [0, TAU)
	var target_r := start_r - excess - float(SPIN_REV) * TAU # always within ~50 rad of 0

	wheel_exact_rot = land_r  # commit before tween so callback can snap to it

	# Force the wheel to the exact start position — ensures the tween begins from a
	# float-precise value and target_r never accumulates across spins.
	wheel_image.rotation = start_r

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(wheel_image, "rotation", target_r, 3.5)
	tween.tween_callback(_on_spin_complete.bind(win_idx, win_mult))


func _on_spin_complete(win_idx: int, mult: float) -> void:
	# Snap the visual to the exact segment centre — corrects any tween float residual.
	wheel_image.rotation = wheel_exact_rot

	if win_idx in SPIN_AGAIN_IDX:
		result_label.add_theme_color_override("font_color", Color(0.973, 0.973, 0.439, 1))
		result_label.text = "Spin Again!"
		await get_tree().create_timer(0.7).timeout
		result_label.text = ""
		_do_spin()
		return

	# delta is positive (profit) or negative (loss)
	var delta := current_bet * (mult - 1.0)
	GameState.bankroll += delta

	if mult == 1.0:
		result_label.add_theme_color_override("font_color", Color(0.973, 0.973, 0.439, 1))
		result_label.text = "1x  —  bet returned"
	elif mult > 1.0:
		GameState.add_fame(TOWN_ID, delta)
		result_label.add_theme_color_override("font_color", Color(0.376, 0.973, 0.502, 1))
		result_label.text = "+$%s  (%s)" % [_fmt(delta), _mult_str(mult)]
	elif mult == 0.0:
		result_label.add_theme_color_override("font_color", Color(0.973, 0.376, 0.376, 1))
		result_label.text = "0x  —  -$%s" % _fmt(current_bet)
	else:
		result_label.add_theme_color_override("font_color", Color(0.973, 0.376, 0.376, 1))
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
