extends Control

const TOWN_ID := 2
const MIN_BET := 10.0

const RED_NUMS : Array[int] = [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36]

# Clockwise wheel order (37 = "00") — must match roulette_wheel.gd
const WHEEL_ORDER : Array[int] = [
	0, 28, 9, 26, 30, 11, 7, 20, 32, 17, 5, 22, 34, 15, 3,
	24, 36, 13, 1, 37, 27, 10, 25, 29, 12, 8, 19, 31, 18,
	6, 21, 33, 16, 4, 23, 35, 14, 2
]

const CHIP_VALUES : Array[float] = [10.0, 25.0, 50.0, 100.0, 500.0]
const CHIP_LABELS : Array[String] = ["$10", "$25", "$50", "$100", "$500"]
const CHIP_COLORS : Array[Color]  = [
	Color(0.502, 0.502, 0.502, 1),
	Color(0.157, 0.502, 0.220, 1),
	Color(0.659, 0.157, 0.157, 1),
	Color(0.157, 0.314, 0.659, 1),
	Color(0.439, 0.157, 0.659, 1),
]

const SPIN_REV := 5

enum State { IDLE, TRANSITION, SPINNING, SHOW_RESULT, RETURNING }

var state          : State  = State.IDLE
var selected_chip  : float  = 10.0
var bets           : Dictionary = {}   # bet_key -> float
var bet_btns       : Dictionary = {}   # bet_key -> Button
var win_num        : int    = -2       # -2=none, -1=00, 0-36
var spin_history   : Array  = []       # Array[int]
var last_bets      : Dictionary = {}   # saved from previous round for Rebet
var wheel_exact_rot: float  = 0.0
var board_start_y  : float  = 0.0
var wheel_start_y  : float  = 0.0
var _num_vbox      : Control                      # reference to the number rows container

@onready var balance_label  : Label          = %BalanceLabel
@onready var fame_label     : Label          = %FameLabel
@onready var bet_total_label: Label          = %BetTotalLabel
@onready var result_label   : Label          = %ResultLabel
@onready var win_label      : Label          = %WinLabel
@onready var board_view     : Control        = %BoardView
@onready var wheel_view     : Control        = %WheelView
@onready var wheel_draw     : Control        = %WheelDraw
@onready var show_spin_btn  : Button         = %ShowSpinButton
@onready var clear_btn      : Button         = %ClearBetsBtn
@onready var rebet_btn      : Button         = %RebetBtn
@onready var board_container: VBoxContainer  = %BoardContainer
@onready var history_row    : HBoxContainer  = %HistoryRow
@onready var chip_row       : HBoxContainer  = %ChipRow
@onready var chip_overlay   : Control        = %ChipOverlay

# StyleBoxes built at runtime
var _sb_num_red   : StyleBoxFlat
var _sb_num_black : StyleBoxFlat
var _sb_num_green : StyleBoxFlat
var _sb_num_hover : StyleBoxFlat
var _sb_outside   : StyleBoxFlat
var _sb_outside_h : StyleBoxFlat
var _sb_panel     : StyleBoxFlat
var _sb_btn_n     : StyleBoxFlat
var _sb_btn_h     : StyleBoxFlat
var _sb_action_n  : StyleBoxFlat
var _sb_action_h  : StyleBoxFlat
var _sb_chip_sel  : StyleBoxFlat
var _sb_chip_norm : StyleBoxFlat
var _sb_highlight : StyleBoxFlat


func _ready() -> void:
	randomize()
	_build_styles()
	_build_chip_selector()
	_build_board()

	show_spin_btn.pressed.connect(_on_show_wheel)
	clear_btn.pressed.connect(_on_clear_bets)
	rebet_btn.pressed.connect(_on_rebet)
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn"))

	# WheelView starts off-screen below; chip overlay sized to match board
	await get_tree().process_frame
	await get_tree().process_frame   # second frame: layout fully settled
	board_start_y = board_view.position.y
	wheel_start_y = get_viewport_rect().size.y
	wheel_view.position.y = wheel_start_y

	# Position chip overlay to cover only the number rows (not outside bets)
	# so that outside bet buttons can still receive mouse input normally
	chip_overlay.position = _num_vbox.global_position - board_view.global_position
	chip_overlay.size     = _num_vbox.size
	chip_overlay.bets     = bets
	chip_overlay.bet_requested.connect(_on_bet_placed)
	chip_overlay.init_grid(bet_btns)

	_update_hud()
	_set_idle_ui()


# ── Styles ────────────────────────────────────────────────────────────────────

func _build_styles() -> void:
	_sb_num_red   = _flat(Color(0.502, 0.063, 0.063, 1), Color(0.659, 0.125, 0.125, 1))
	_sb_num_black = _flat(Color(0.094, 0.094, 0.094, 1), Color(0.220, 0.220, 0.220, 1))
	_sb_num_green = _flat(Color(0.063, 0.345, 0.125, 1), Color(0.125, 0.502, 0.220, 1))
	_sb_num_hover = _flat(Color(0.220, 0.220, 0.063, 1), Color(0.973, 0.847, 0.188, 1))
	_sb_outside   = _flat(Color(0.031, 0.094, 0.063, 1), Color(0.125, 0.345, 0.188, 1))
	_sb_outside_h = _flat(Color(0.094, 0.157, 0.063, 1), Color(0.973, 0.847, 0.188, 1))
	_sb_panel     = _flat(Color(0.031, 0.094, 0.047, 1), Color(0.125, 0.345, 0.157, 1), 20)
	_sb_btn_n     = _flat(Color(0.031, 0.094, 0.047, 1), Color(0.125, 0.345, 0.157, 1))
	_sb_btn_h     = _flat(Color(0.063, 0.157, 0.094, 1), Color(0.973, 0.847, 0.188, 1))
	_sb_action_n  = _flat(Color(0.094, 0.220, 0.125, 1), Color(0.220, 0.659, 0.345, 1))
	_sb_action_h  = _flat(Color(0.125, 0.282, 0.157, 1), Color(0.973, 0.847, 0.188, 1))
	_sb_chip_sel  = _flat(Color(0.157, 0.314, 0.157, 1), Color(0.973, 0.847, 0.188, 1))
	_sb_chip_norm = _flat(Color(0.031, 0.094, 0.047, 1), Color(0.125, 0.345, 0.157, 1))
	_sb_highlight = _flat(Color(0.220, 0.188, 0.031, 1), Color(0.973, 0.847, 0.188, 1))


func _flat(bg: Color, border: Color, margin: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color            = bg
	s.border_color        = border
	s.border_width_left   = 2
	s.border_width_top    = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	s.content_margin_left   = float(margin)
	s.content_margin_top    = float(margin)
	s.content_margin_right  = float(margin)
	s.content_margin_bottom = float(margin)
	return s


# ── Chip selector ─────────────────────────────────────────────────────────────

func _build_chip_selector() -> void:
	for i in CHIP_VALUES.size():
		var btn := Button.new()
		btn.text = CHIP_LABELS[i]
		btn.custom_minimum_size = Vector2(48, 36)
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 11)
		_style_chip_btn(btn, i == 0)
		btn.pressed.connect(_on_chip_selected.bind(i))
		chip_row.add_child(btn)


func _style_chip_btn(btn: Button, selected: bool) -> void:
	var sb : StyleBoxFlat = _sb_chip_sel if selected else _sb_chip_norm
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, sb)
	btn.add_theme_color_override("font_color",         CHIP_COLORS[CHIP_LABELS.find(btn.text)])
	btn.add_theme_color_override("font_hover_color",   Color(0.973, 0.847, 0.188, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.973, 0.847, 0.188, 1))


func _on_chip_selected(idx: int) -> void:
	selected_chip = CHIP_VALUES[idx]
	var btns := chip_row.get_children()
	for i in btns.size():
		_style_chip_btn(btns[i] as Button, i == idx)


# ── Board ─────────────────────────────────────────────────────────────────────

func _build_board() -> void:
	for c in board_container.get_children():
		c.queue_free()
	bet_btns.clear()

	# Outer HBox: [zero_col | number_rows+2:1]
	# The chip overlay is sized to this container, covering both 0/00 and all numbers.
	var num_outer := HBoxContainer.new()
	num_outer.add_theme_constant_override("separation", 3)
	board_container.add_child(num_outer)
	_num_vbox = num_outer

	# ── Zero column: 0 and 00 stretch to span all 3 number rows ─────────────
	var zero_vbox := VBoxContainer.new()
	zero_vbox.add_theme_constant_override("separation", 3)
	zero_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	num_outer.add_child(zero_vbox)

	for zero_pair : Array in [["n_0", "0"], ["n_00", "00"]]:
		var zkey : String = zero_pair[0]
		var zlbl : String = zero_pair[1]
		var zbtn := _make_num_btn(zkey, zlbl, _sb_num_green)
		zbtn.size_flags_vertical = SIZE_EXPAND_FILL
		zbtn.pressed.connect(_on_bet_placed.bind(zkey))
		zero_vbox.add_child(zbtn)
		bet_btns[zkey] = zbtn

	# ── 3 number rows + 2:1 column ───────────────────────────────────────────
	var num_inner := VBoxContainer.new()
	num_inner.add_theme_constant_override("separation", 3)
	num_inner.size_flags_horizontal = SIZE_EXPAND_FILL
	num_outer.add_child(num_inner)

	var col_keys : Array[String] = ["col_3", "col_2", "col_1"]
	var row_nums : Array[Array]  = [
		[3,6,9,12,15,18,21,24,27,30,33,36],
		[2,5,8,11,14,17,20,23,26,29,32,35],
		[1,4,7,10,13,16,19,22,25,28,31,34],
	]

	for ri in 3:
		var col_key : String = col_keys[ri]
		var nums    : Array  = row_nums[ri]

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 3)
		hbox.size_flags_vertical = SIZE_EXPAND_FILL
		num_inner.add_child(hbox)

		# Number cells
		for num : int in nums:
			var key  := "n_%d" % num
			var sb   : StyleBoxFlat = _sb_num_red if num in RED_NUMS else _sb_num_black
			var nbtn := _make_num_btn(key, str(num), sb)
			nbtn.pressed.connect(_on_bet_placed.bind(key))
			hbox.add_child(nbtn)
			bet_btns[key] = nbtn

		# Column 2:1 button — inside the overlay area; overlay routes clicks via _reg_plain
		var cbtn := _make_outside_btn(col_key, "2:1")
		cbtn.custom_minimum_size = Vector2(40, 52)
		cbtn.size_flags_vertical = SIZE_EXPAND_FILL
		cbtn.mouse_filter        = MOUSE_FILTER_IGNORE   # overlay handles clicks
		cbtn.pressed.connect(_on_bet_placed.bind(col_key))
		hbox.add_child(cbtn)
		bet_btns[col_key] = cbtn

	# Dozen row
	var dozen_hbox := HBoxContainer.new()
	dozen_hbox.add_theme_constant_override("separation", 3)
	board_container.add_child(dozen_hbox)

	# Spacer aligns with the zero column (fixed 36 px, no expand)
	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(36, 0)
	dozen_hbox.add_child(sp2)

	var dozen_keys   : Array[String] = ["dozen_1", "dozen_2", "dozen_3"]
	var dozen_labels : Array[String] = ["1st 12",  "2nd 12",  "3rd 12"]
	for di in 3:
		var dbtn := _make_outside_btn(dozen_keys[di], dozen_labels[di])
		dbtn.size_flags_horizontal = SIZE_EXPAND_FILL
		dbtn.pressed.connect(_on_bet_placed.bind(dozen_keys[di]))
		dozen_hbox.add_child(dbtn)
		bet_btns[dozen_keys[di]] = dbtn

	var sp3 := Control.new()
	sp3.custom_minimum_size = Vector2(40, 0)
	dozen_hbox.add_child(sp3)

	# Outside bets row
	var out_hbox := HBoxContainer.new()
	out_hbox.add_theme_constant_override("separation", 3)
	board_container.add_child(out_hbox)

	var sp4 := Control.new()
	sp4.custom_minimum_size = Vector2(36, 0)
	out_hbox.add_child(sp4)

	var out_keys   : Array[String] = ["low",  "even", "red",   "black", "odd", "high"]
	var out_labels : Array[String] = ["1-18", "Even", "Red",   "Black", "Odd", "19-36"]
	for oi in out_keys.size():
		var obtn := _make_outside_btn(out_keys[oi], out_labels[oi])
		obtn.size_flags_horizontal = SIZE_EXPAND_FILL
		# Colour Red/Black buttons to match their meaning
		if out_keys[oi] == "red":
			for s in ["normal", "pressed", "focus", "disabled"]:
				obtn.add_theme_stylebox_override(s, _sb_num_red)
			obtn.add_theme_stylebox_override("hover", _sb_num_hover)
		elif out_keys[oi] == "black":
			for s in ["normal", "pressed", "focus", "disabled"]:
				obtn.add_theme_stylebox_override(s, _sb_num_black)
			obtn.add_theme_stylebox_override("hover", _sb_num_hover)
		obtn.pressed.connect(_on_bet_placed.bind(out_keys[oi]))
		out_hbox.add_child(obtn)
		bet_btns[out_keys[oi]] = obtn

	var sp5 := Control.new()
	sp5.custom_minimum_size = Vector2(40, 0)
	out_hbox.add_child(sp5)


func _make_num_btn(key: String, label: String, sb: StyleBoxFlat) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(36, 52)   # fixed height fits number + bet amount on two lines
	btn.size_flags_horizontal = SIZE_EXPAND_FILL
	btn.size_flags_vertical   = SIZE_SHRINK_CENTER
	btn.mouse_filter          = MOUSE_FILTER_IGNORE   # chip overlay handles all number-cell input
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color",          Color(0.973, 0.973, 0.973, 1))
	btn.add_theme_color_override("font_hover_color",    Color(0.973, 0.847, 0.188, 1))
	btn.add_theme_color_override("font_pressed_color",  Color(0.973, 0.847, 0.188, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.502, 0.502, 0.502, 1))
	for s in ["normal", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, sb)
	btn.add_theme_stylebox_override("hover", _sb_num_hover)
	return btn


func _make_outside_btn(key: String, label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 52)   # fixed height fits label + bet amount on two lines
	btn.size_flags_vertical = SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color",          Color(0.973, 0.973, 0.973, 1))
	btn.add_theme_color_override("font_hover_color",    Color(0.973, 0.847, 0.188, 1))
	btn.add_theme_color_override("font_pressed_color",  Color(0.973, 0.847, 0.188, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.502, 0.502, 0.502, 1))
	for s in ["normal", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, _sb_outside)
	btn.add_theme_stylebox_override("hover", _sb_outside_h)
	return btn


# ── Bet placement ─────────────────────────────────────────────────────────────

func _on_bet_placed(key: String) -> void:
	if state != State.IDLE:
		return
	if GameState.bankroll < selected_chip:
		bet_total_label.text = "No funds"
		return

	var cur : float = bets.get(key, 0.0)
	bets[key] = cur + selected_chip
	GameState.bankroll -= selected_chip
	_refresh_btn_label(key)
	_update_hud()
	_update_bet_total()


func _refresh_btn_label(key: String) -> void:
	# Number, split, and corner bets are visualised by the chip overlay — no button text needed
	if key.begins_with("n_") or key.begins_with("sp|") or key.begins_with("co|"):
		chip_overlay.queue_redraw()
		return
	if not bet_btns.has(key):
		return
	var btn : Button = bet_btns[key]
	var amount : float = bets.get(key, 0.0)
	var base_text := _base_label(key)
	if amount > 0:
		btn.text = base_text + "\n$" + _fmt(amount)
	else:
		btn.text = base_text


func _base_label(key: String) -> String:
	if key.begins_with("sp|") or key.begins_with("co|"):
		return key   # never displayed as button text
	if key.begins_with("n_"):
		return key.substr(2)  # "n_7" → "7", "n_00" → "00"
	match key:
		"col_1": return "2:1"
		"col_2": return "2:1"
		"col_3": return "2:1"
		"dozen_1": return "1st 12"
		"dozen_2": return "2nd 12"
		"dozen_3": return "3rd 12"
		"low":   return "1-18"
		"even":  return "Even"
		"red":   return "Red"
		"black": return "Black"
		"odd":   return "Odd"
		"high":  return "19-36"
	return key


func _on_clear_bets() -> void:
	if state != State.IDLE:
		return
	for key in bets:
		GameState.bankroll += bets[key]
	bets.clear()
	for key in bet_btns:
		(bet_btns[key] as Button).text = _base_label(key)
	chip_overlay.queue_redraw()
	_update_hud()
	_update_bet_total()


func _on_rebet() -> void:
	if state != State.IDLE or last_bets.is_empty():
		return
	# Clear any current bets first
	for key in bets:
		GameState.bankroll += bets[key]
	bets.clear()
	for key in bet_btns:
		(bet_btns[key] as Button).text = _base_label(key)

	# Place last round's bets
	var total_needed := 0.0
	for v in last_bets.values():
		total_needed += v
	if total_needed > GameState.bankroll:
		bet_total_label.text = "No funds"
		_update_hud()
		return

	for key in last_bets:
		bets[key] = last_bets[key]
		GameState.bankroll -= last_bets[key]
		_refresh_btn_label(key)
	chip_overlay.queue_redraw()
	_update_hud()
	_update_bet_total()


func _update_bet_total() -> void:
	var total := 0.0
	for v in bets.values():
		total += v
	if total > 0:
		bet_total_label.text = "Bets: $%s" % _fmt(total)
	else:
		bet_total_label.text = "No bets placed"


# ── Show wheel ────────────────────────────────────────────────────────────────

func _on_show_wheel() -> void:
	if state != State.IDLE:
		return
	var total := 0.0
	for v in bets.values():
		total += v
	if total <= 0:
		bet_total_label.text = "Place a bet first"
		return

	state = State.TRANSITION
	show_spin_btn.disabled = true
	clear_btn.disabled     = true
	_lock_board(true)

	# Board fades to 30% opacity in place; wheel slides up over it
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(board_view, "modulate:a", 0.25, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(wheel_view, "position:y", 0.0,  0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.chain().tween_callback(_start_spin)


# ── Spin ──────────────────────────────────────────────────────────────────────

func _start_spin() -> void:
	state = State.SPINNING
	result_label.text       = ""
	win_label.text          = ""
	result_label.modulate.a = 0.0
	win_label.modulate.a    = 0.0

	# Pick winning number (0-36 normal, -1 = 00)
	win_num = randi_range(0, 37)
	if win_num == 37:
		win_num = -1

	# Find wheel pocket index
	var pocket_num := win_num if win_num >= 0 else 37
	var pocket_idx := WHEEL_ORDER.find(pocket_num)

	# Wheel spin math (clockwise — decreasing angle)
	# land_r offset by +0.5 seg so the pocket CENTER (not edge) sits under the pointer
	var seg_angle := TAU / float(WHEEL_ORDER.size())
	var land_r    := -(float(pocket_idx) + 0.5) * seg_angle
	var start_r   := wheel_exact_rot
	var excess    := fposmod(start_r - land_r, TAU)
	var target_r  := start_r - excess - float(SPIN_REV) * TAU
	wheel_exact_rot = land_r

	# Ball spins counter-clockwise (opposite to wheel), lands at 12 o'clock pointer
	var ball_end   := -TAU * 0.25
	var ball_start := ball_end - float(SPIN_REV + 3) * TAU

	wheel_draw.ball_angle = ball_start
	wheel_draw.show_ball  = true
	wheel_draw.wheel_rot  = start_r
	wheel_draw.lit_num    = -2

	var spin_time := 7.0
	var tw := create_tween()
	tw.tween_method(_set_wheel_rot,  start_r,    target_r, spin_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_method(_set_ball_angle, ball_start, ball_end, spin_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(_on_spin_complete)


func _set_wheel_rot(v: float) -> void:
	wheel_draw.wheel_rot = v
	wheel_draw.queue_redraw()


func _set_ball_angle(v: float) -> void:
	wheel_draw.ball_angle = v
	wheel_draw.queue_redraw()


func _on_spin_complete() -> void:
	wheel_draw.wheel_rot  = wheel_exact_rot
	wheel_draw.ball_angle = -TAU * 0.25   # winning pocket always at 12 o'clock under pointer
	wheel_draw.lit_num    = win_num
	wheel_draw.queue_redraw()

	state = State.SHOW_RESULT

	# Calculate payout
	var payout := _calculate_payout()
	GameState.bankroll += payout
	if payout > 0:
		GameState.add_fame(TOWN_ID, payout)

	# Result label
	var num_str := "00" if win_num == -1 else str(win_num)
	var color   : Color
	if win_num == 0 or win_num == -1:
		color = Color(0.220, 0.659, 0.345, 1)
	elif win_num in RED_NUMS:
		color = Color(0.973, 0.376, 0.376, 1)
	else:
		color = Color(0.627, 0.627, 0.627, 1)
	result_label.add_theme_color_override("font_color", color)
	result_label.text       = num_str
	result_label.modulate.a = 1.0

	# Win label — show profit earned by winning bets, regardless of other losses.
	# e.g. bet Black + a red number, land on black → show black profit even though net is $0.
	var winning_profit := 0.0
	for key in bets:
		var wagered : float = bets[key]
		if _bet_wins(key, win_num):
			winning_profit += wagered * _payout_mult(key)
	if winning_profit > 0.0:
		win_label.text       = "+$%s" % _fmt(winning_profit)
		win_label.modulate.a = 1.0
	else:
		win_label.text = ""

	# Add to history
	spin_history.push_front(win_num)
	if spin_history.size() > 8:
		spin_history.pop_back()
	_refresh_history()

	# Return to board after delay
	await get_tree().create_timer(2.5).timeout
	_return_to_board()


func _calculate_payout() -> float:
	var total := 0.0
	for key in bets:
		var wagered : float = bets[key]
		if _bet_wins(key, win_num):
			total += wagered * (1.0 + _payout_mult(key))
	return total


func _bet_wins(key: String, num: int) -> bool:
	# Split / corner: win if ANY of the constituent cells would win
	if key.begins_with("sp|") or key.begins_with("co|"):
		var parts := key.split("|")
		for i in range(1, parts.size()):
			if _bet_wins(parts[i], num):
				return true
		return false
	if key == "n_0":   return num == 0
	if key == "n_00":  return num == -1
	if key.begins_with("n_"):
		return num == key.substr(2).to_int()
	var reds   := RED_NUMS
	var blacks := [2,4,6,8,10,11,13,15,17,20,22,24,26,28,29,31,33,35]
	match key:
		"red":    return num > 0 and num in reds
		"black":  return num > 0 and num in blacks
		"even":   return num > 0 and num % 2 == 0
		"odd":    return num > 0 and num % 2 == 1
		"low":    return num >= 1 and num <= 18
		"high":   return num >= 19 and num <= 36
		"dozen_1":return num >= 1 and num <= 12
		"dozen_2":return num >= 13 and num <= 24
		"dozen_3":return num >= 25 and num <= 36
		"col_1":  return num in [1,4,7,10,13,16,19,22,25,28,31,34]
		"col_2":  return num in [2,5,8,11,14,17,20,23,26,29,32,35]
		"col_3":  return num in [3,6,9,12,15,18,21,24,27,30,33,36]
	return false


func _payout_mult(key: String) -> float:
	if key.begins_with("sp|"): return 17.0   # split  — 2 numbers  17:1
	if key.begins_with("co|"): return 8.0    # corner — 4 numbers   8:1
	if key == "n_0" or key == "n_00" or key.begins_with("n_"):
		return 35.0
	match key:
		"col_1", "col_2", "col_3", "dozen_1", "dozen_2", "dozen_3":
			return 2.0
	return 1.0   # even money bets


# ── Return to board ───────────────────────────────────────────────────────────

func _return_to_board() -> void:
	state = State.RETURNING
	var vp_h := get_viewport_rect().size.y
	var tw   := create_tween()
	tw.set_parallel(true)
	tw.tween_property(wheel_view, "position:y", vp_h, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(board_view, "modulate:a",  1.0,  0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.chain().tween_callback(_on_board_returned)


func _on_board_returned() -> void:
	state = State.IDLE
	_highlight_winner()
	_update_hud()
	last_bets = bets.duplicate()
	bets.clear()
	_update_bet_total()
	for key in bet_btns:
		(bet_btns[key] as Button).text = _base_label(key)
	_set_idle_ui()
	wheel_draw.show_ball = false
	wheel_draw.lit_num   = -2
	wheel_draw.queue_redraw()
	chip_overlay.queue_redraw()
	# Hide result / win labels so nothing shows next time wheel slides up
	result_label.text      = ""
	win_label.text         = ""
	result_label.modulate.a = 0.0
	win_label.modulate.a    = 0.0


func _highlight_winner() -> void:
	# Flash the winning cell gold for a moment
	var key := "n_%d" % win_num if win_num >= 0 else "n_00"
	if not bet_btns.has(key):
		return
	var btn : Button = bet_btns[key]
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, _sb_highlight)
	var orig_key := key
	await get_tree().create_timer(1.5).timeout
	# Restore original style
	_restore_btn_style(orig_key)


func _restore_btn_style(key: String) -> void:
	if not bet_btns.has(key):
		return
	var btn : Button = bet_btns[key]
	var sb : StyleBoxFlat
	if key == "n_0" or key == "n_00":
		sb = _sb_num_green
	elif key.begins_with("n_"):
		var n := key.substr(2).to_int()
		sb = _sb_num_red if n in RED_NUMS else _sb_num_black
	elif key == "red":
		sb = _sb_num_red
	elif key == "black":
		sb = _sb_num_black
	else:
		sb = _sb_outside
	for s in ["normal", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, sb)
	btn.add_theme_stylebox_override("hover", _sb_num_hover if (key.begins_with("n_") or key == "red" or key == "black") else _sb_outside_h)


# ── History ───────────────────────────────────────────────────────────────────

func _refresh_history() -> void:
	for child in history_row.get_children():
		child.queue_free()
	for num : int in spin_history:
		var lbl := Label.new()
		lbl.text = "00" if num == -1 else str(num)
		lbl.custom_minimum_size = Vector2(28, 24)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.973, 0.973, 0.973, 1))
		var col : Color
		if num == 0 or num == -1:
			col = Color(0.063, 0.345, 0.125, 1)
		elif num in RED_NUMS:
			col = Color(0.502, 0.063, 0.063, 1)
		else:
			col = Color(0.094, 0.094, 0.094, 1)
		var sb := _flat(col, col.lightened(0.2), 4)
		lbl.add_theme_stylebox_override("normal", sb)
		# Newest first = left
		history_row.add_child(lbl)


# ── UI helpers ────────────────────────────────────────────────────────────────

func _set_idle_ui() -> void:
	show_spin_btn.disabled = false
	clear_btn.disabled     = false
	rebet_btn.disabled     = last_bets.is_empty()
	_lock_board(false)


func _lock_board(locked: bool) -> void:
	for key in bet_btns:
		(bet_btns[key] as Button).disabled = locked
	chip_overlay.locked = locked


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
