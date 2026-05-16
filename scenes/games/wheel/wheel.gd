extends Control

const TOWN_ID  := 1
const MIN_BET  := 10.0
const SPIN_REV := 6      # full extra rotations before landing

# [multiplier, count, color]  — all profiles EV = 1.0 (no house edge)
# Low:  8×0x + 10×1.5x + 2×2.5x  →  0.5×1.5 + 0.1×2.5 = 1.0
# Med:  12×0x + 6×2x + 2×4x      →  0.3×2   + 0.1×4   = 1.0
# High: 15×0x + 4×2x + 1×12x     →  0.2×2   + 0.05×12 = 1.0
const RISK_PROFILES: Array = [
	[
		[0.0,  8, Color(0.20, 0.15, 0.28)],
		[1.5, 10, Color(0.10, 0.50, 0.20)],
		[2.5,  2, Color(0.15, 0.30, 0.80)],
	],
	[
		[0.0, 12, Color(0.20, 0.15, 0.28)],
		[2.0,  6, Color(0.10, 0.50, 0.20)],
		[4.0,  2, Color(0.15, 0.30, 0.80)],
	],
	[
		[0.0,  15, Color(0.20, 0.15, 0.28)],
		[2.0,   4, Color(0.10, 0.50, 0.20)],
		[12.0,  1, Color(0.75, 0.60, 0.05)],
	],
]

enum State { IDLE, SPINNING }

var state       : State = State.IDLE
var current_bet : float = 0.0
var risk_level  : int   = 0
var segments    : Array = []   # shuffled [mult, color] list for current spin

@onready var balance_label : Label   = %BalanceLabel
@onready var fame_label    : Label   = %FameLabel
@onready var result_label  : Label   = %ResultLabel
@onready var bet_input     : LineEdit = %BetInput
@onready var spin_btn      : Button  = %SpinButton
@onready var low_btn       : Button  = %LowButton
@onready var med_btn       : Button  = %MedButton
@onready var high_btn      : Button  = %HighButton
@onready var wheel_draw    : Control = %WheelDraw


func _ready() -> void:
	low_btn.pressed.connect(func(): _set_risk(0))
	med_btn.pressed.connect(func(): _set_risk(1))
	high_btn.pressed.connect(func(): _set_risk(2))
	spin_btn.pressed.connect(_on_spin)
	_set_risk(0)
	_update_hud()


func _set_risk(level: int) -> void:
	risk_level = level
	var gold  := Color(1.0, 0.878, 0.2, 1)
	var white := Color(1.0, 1.0, 1.0, 1)
	low_btn.modulate  = gold  if level == 0 else white
	med_btn.modulate  = gold  if level == 1 else white
	high_btn.modulate = gold  if level == 2 else white
	_rebuild_segments()


func _rebuild_segments() -> void:
	segments.clear()
	for tier in RISK_PROFILES[risk_level]:
		for _i in tier[1]:
			segments.append([tier[0], tier[2]])
	segments.shuffle()
	wheel_draw.segments = segments
	wheel_draw.rotation = 0.0
	wheel_draw.queue_redraw()


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

	# Fresh shuffle each spin
	_rebuild_segments()
	await get_tree().process_frame

	var n        : int   = segments.size()
	var win_idx  : int   = randi_range(0, n - 1)
	var win_mult : float = segments[win_idx][0]

	# Pointer is at 12 o'clock (top). Wheel is drawn with segment 0 starting at
	# -PI/2 (12 o'clock), each segment spanning TAU/n clockwise.
	# To land win_idx under the pointer: rotate so the centre of win_idx faces up.
	var seg_angle   := TAU / n
	var target_r    := -(win_idx + 0.5) * seg_angle          # negative = clockwise
	# Add full rotations so the wheel spins visibly
	target_r -= SPIN_REV * TAU
	# Normalise to always spin forward from current rotation
	while target_r > wheel_draw.rotation:
		target_r -= TAU
	if target_r > wheel_draw.rotation - TAU:
		target_r -= TAU * SPIN_REV

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(wheel_draw, "rotation", target_r, 3.5)
	tween.tween_callback(_on_spin_complete.bind(win_mult))


func _on_spin_complete(mult: float) -> void:
	if mult == 0.0:
		GameState.bankroll -= current_bet
		result_label.text = "No win  —  -$%s" % _fmt(current_bet)
	else:
		var profit := current_bet * (mult - 1.0)
		GameState.bankroll += profit
		GameState.add_fame(TOWN_ID, profit)
		var mult_str := "%dx" % int(mult) if mult == int(mult) else "%.1fx" % mult
		result_label.text = "+$%s  (%s)" % [_fmt(profit), mult_str]

	state             = State.IDLE
	spin_btn.disabled = false
	_update_hud()


func _update_hud() -> void:
	balance_label.text = "Balance:  $%s" % _fmt(GameState.bankroll)
	fame_label.text    = "%s / %s Fame" % [
		_fmt(GameState.town_fame[TOWN_ID]),
		_fmt(GameState.FAME_TARGETS[TOWN_ID])
	]


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
