extends Control

const TOWN_ID      := 2
const MIN_BET      := 10.0
const HISTORY_SIZE := 6

enum RollMode { OVER, UNDER }
enum State    { IDLE, ROLLING }

var state     : State    = State.IDLE
var roll_mode : RollMode = RollMode.OVER
var threshold : int      = 50
var history   : Array    = []   # [{result: float, won: bool}, ...]

@onready var balance_label    : Label      = %BalanceLabel
@onready var fame_label       : Label      = %FameLabel
@onready var slider_bg        : DiceSlider = %SliderBg
@onready var threshold_label  : Label      = %ThresholdLabel
@onready var mult_label       : Label      = %MultLabel
@onready var mode_toggle_btn  : Button     = %ModeToggleBtn
@onready var win_chance_label : Label      = %WinChanceLabel
@onready var bet_input        : LineEdit   = %BetInput
@onready var half_btn         : Button     = %HalfBtn
@onready var double_btn       : Button     = %TwoXBtn
@onready var payout_label     : Label      = %PayoutLabel
@onready var roll_btn         : Button     = %RollButton
@onready var result_label     : Label      = %ResultLabel
@onready var back_btn         : Button     = %BackButton

var history_panels : Array[PanelContainer] = []
var history_labels : Array[Label]          = []


func _ready() -> void:
	randomize()
	for i in HISTORY_SIZE:
		var panel := find_child("HistPanel%d" % i) as PanelContainer
		var lbl   := find_child("HistLabel%d"  % i) as Label
		history_panels.append(panel)
		history_labels.append(lbl)
		panel.visible = false

	slider_bg.threshold_changed.connect(_on_threshold_changed)
	bet_input.text_changed.connect(_on_bet_changed)
	roll_btn.pressed.connect(_on_roll)
	half_btn.pressed.connect(_on_half)
	double_btn.pressed.connect(_on_double)
	mode_toggle_btn.pressed.connect(_toggle_mode)
	back_btn.pressed.connect(_on_back)

	_update_hud()
	_update_stats()


func _on_bet_changed(_text: String) -> void:
	_update_payout()


func _on_half() -> void:
	var bet := bet_input.text.to_float()
	if bet > 0.0:
		bet_input.text = "%.0f" % maxf(MIN_BET, bet * 0.5)
		_update_payout()


func _on_double() -> void:
	var bet := bet_input.text.to_float()
	if bet > 0.0:
		bet_input.text = "%.0f" % (bet * 2.0)
		_update_payout()


func _toggle_mode() -> void:
	if roll_mode == RollMode.OVER:
		_set_under()
	else:
		_set_over()


func _set_over() -> void:
	roll_mode           = RollMode.OVER
	slider_bg.mode_over = true
	slider_bg.queue_redraw()
	_update_stats()


func _set_under() -> void:
	roll_mode           = RollMode.UNDER
	slider_bg.mode_over = false
	slider_bg.queue_redraw()
	_update_stats()


func _on_threshold_changed(val: int) -> void:
	threshold = val
	_update_stats()


func _win_chance() -> float:
	if roll_mode == RollMode.OVER:
		return float(100 - threshold) / 100.0
	return float(threshold) / 100.0


func _multiplier() -> float:
	return 1.0 / _win_chance()


func _on_roll() -> void:
	if state == State.ROLLING:
		return
	var bet := bet_input.text.to_float()
	if bet < MIN_BET:
		result_label.add_theme_color_override("font_color", Color(0.973, 0.973, 0.439, 1))
		result_label.text = "Minimum bet: $%s" % _fmt(MIN_BET)
		return
	if bet > GameState.bankroll:
		result_label.add_theme_color_override("font_color", Color(0.973, 0.973, 0.439, 1))
		result_label.text = "Not enough funds."
		return

	state                    = State.ROLLING
	roll_btn.disabled        = true
	mode_toggle_btn.disabled = true   # lock mode during animation
	result_label.text        = ""

	var final_result : float = float(randi_range(0, 9999)) / 100.0
	var won          := (roll_mode == RollMode.OVER  and final_result >= float(threshold)) or \
	                   (roll_mode == RollMode.UNDER and final_result <  float(threshold))
	var mult         := _multiplier()

	_animate_roll(final_result, bet, won, mult)


func _animate_roll(final_result: float, bet: float, won: bool, mult: float) -> void:
	# Jump circle to far right, then scroll to landing position
	slider_bg.display_result = 100.0
	slider_bg.show_result    = true

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(slider_bg, "display_result", final_result, 1.4)
	tween.tween_callback(_show_final.bind(final_result, bet, won, mult))


func _show_final(final_result: float, bet: float, won: bool, mult: float) -> void:
	history.push_front({"result": final_result, "won": won})
	if history.size() > HISTORY_SIZE:
		history.pop_back()
	_update_history()

	if won:
		var profit := bet * (mult - 1.0)
		GameState.bankroll += profit
		GameState.add_fame(TOWN_ID, profit)
	else:
		GameState.bankroll -= bet

	await get_tree().create_timer(0.3).timeout
	state                    = State.IDLE
	roll_btn.disabled        = false
	mode_toggle_btn.disabled = false  # unlock mode after animation
	# show_result stays true — circle remains on the line until next Place Bet
	_update_hud()
	_update_payout()


func _update_history() -> void:
	for i in HISTORY_SIZE:
		var panel : PanelContainer = history_panels[i]
		var lbl   : Label          = history_labels[i]
		if panel == null or lbl == null:
			continue
		if i < history.size():
			panel.visible = true
			var entry : Dictionary = history[i]
			lbl.text = "%.2f" % entry.result
			lbl.add_theme_color_override("font_color",
				Color(0.376, 0.973, 0.502, 1) if entry.won else Color(0.973, 0.376, 0.376, 1))
			# Fade the newest entry in so it's clear which roll just landed
			if i == 0:
				panel.modulate.a = 0.0
				var t := create_tween()
				t.tween_property(panel, "modulate:a", 1.0, 0.35)
		else:
			panel.visible = false


func _update_payout() -> void:
	var bet := bet_input.text.to_float()
	payout_label.text = "$--" if bet <= 0.0 else "$%s" % _fmt(bet * _multiplier())


func _update_stats() -> void:
	mult_label.text        = "%.4fx" % _multiplier()
	win_chance_label.text  = "%.2f%%" % (_win_chance() * 100.0)
	var mode_str           := "Roll Over" if roll_mode == RollMode.OVER else "Roll Under"
	mode_toggle_btn.text   = "%s\n%.2f" % [mode_str, float(threshold)]
	threshold_label.text   = str(threshold)
	_update_payout()


func _update_hud() -> void:
	balance_label.text = "Balance:  $%s" % _fmt(GameState.bankroll)
	fame_label.text    = "%s / %s Fame" % [
		_fmt(GameState.town_fame[TOWN_ID]),
		_fmt(GameState.FAME_TARGETS[TOWN_ID])
	]


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


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
