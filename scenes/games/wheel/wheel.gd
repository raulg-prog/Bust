extends Control

const TOWN_ID := 1
const MIN_BET := 10.0
const SEG_W   := 80
const SEG_H   := 60
const REPS    := 6   # strip repetitions — more = longer spin

# [multiplier, count, color]  — all profiles have EV = 1.0 (no house edge)
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
var segments    : Array = []   # one shuffled cycle
var flat_segs   : Array = []   # REPS × segments

@onready var balance_label : Label         = %BalanceLabel
@onready var fame_label    : Label         = %FameLabel
@onready var segment_strip : HBoxContainer = %SegmentStrip
@onready var wheel_clip    : Control       = %WheelClip
@onready var result_label  : Label         = %ResultLabel
@onready var bet_input     : LineEdit      = %BetInput
@onready var spin_btn      : Button        = %SpinButton
@onready var low_btn       : Button        = %LowButton
@onready var med_btn       : Button        = %MedButton
@onready var high_btn      : Button        = %HighButton


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
	_build_strip()


func _build_strip() -> void:
	for child in segment_strip.get_children():
		child.free()
	segment_strip.position.x = 0.0

	segments.clear()
	for tier in RISK_PROFILES[risk_level]:
		for _i in tier[1]:
			segments.append([tier[0], tier[2]])
	segments.shuffle()

	flat_segs.clear()
	for _r in REPS:
		flat_segs.append_array(segments)

	for seg in flat_segs:
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color            = seg[1]
		style.border_width_left   = 1
		style.border_width_right  = 1
		style.border_width_top    = 0
		style.border_width_bottom = 0
		style.border_color        = Color(0.08, 0.06, 0.12, 1)
		panel.add_theme_stylebox_override("panel", style)
		panel.custom_minimum_size       = Vector2(SEG_W, SEG_H)
		panel.size_flags_horizontal     = Control.SIZE_SHRINK_CENTER
		panel.size_flags_vertical       = Control.SIZE_SHRINK_CENTER

		var lbl := Label.new()
		lbl.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment        = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal     = Control.SIZE_SHRINK_CENTER
		lbl.size_flags_vertical       = Control.SIZE_SHRINK_CENTER
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		lbl.add_theme_font_size_override("font_size", 14)
		var m: float = seg[0]
		lbl.text = "✕" if m == 0.0 else ("%dx" % int(m) if m == int(m) else "%.1fx" % m)
		panel.add_child(lbl)
		segment_strip.add_child(panel)


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

	_build_strip()
	await get_tree().process_frame

	# Land on a random segment in the last repetition for maximum spin distance
	var win_idx  : int   = (REPS - 1) * segments.size() + randi_range(0, segments.size() - 1)
	var win_mult : float = flat_segs[win_idx][0]

	# Center the winning segment under the pointer (pointer is at clip center)
	var target_x := wheel_clip.size.x / 2.0 - (win_idx * SEG_W + SEG_W / 2.0)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(segment_strip, "position:x", target_x, 2.5)
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
