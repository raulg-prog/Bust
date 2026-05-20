extends Control

const TOWN_ID := 3
const MIN_BET := 10.0
const ROWS    := 9

# Difficulty table — index matches OptionButton order
const DIFF_NAMES : Array[String] = ["Easy", "Medium", "Hard", "Expert", "Master"]
const DIFF_COLS  : Array[int]    = [4,      3,        2,      3,        4      ]
const DIFF_TRAPS : Array[int]    = [1,      1,        1,      2,        3      ]

enum State { IDLE, PLAYING, GAME_OVER }

var state       : State = State.IDLE
var difficulty  : int   = 0   # index into DIFF_* arrays
var current_row : int   = 0
var current_bet : float = 0.0
var bomb_cols   : Array = []  # Array[Array[int]] — bomb col indices per row

@onready var balance_label : Label         = %BalanceLabel
@onready var fame_label    : Label         = %FameLabel
@onready var bet_input     : LineEdit      = %BetInput
@onready var half_btn      : Button        = %HalfBtn
@onready var double_btn    : Button        = %TwoXBtn
@onready var risk_option   : OptionButton  = %RiskOption
@onready var payout_label  : Label         = %PayoutLabel
@onready var next_label    : Label         = %NextLabel
@onready var action_btn    : Button        = %ActionButton
@onready var back_btn      : Button        = %BackButton
@onready var tile_grid     : VBoxContainer = %TileGrid

var tile_rows : Array = []   # Array[Array[Button]] — tile_rows[row][col], row 0 = bottom

var _style_hidden : StyleBoxFlat
var _style_active : StyleBoxFlat
var _style_hover  : StyleBoxFlat
var _style_safe   : StyleBoxFlat
var _style_bomb   : StyleBoxFlat
var _style_grey   : StyleBoxFlat
var _sb_popup     : StyleBoxFlat

var _tex_safe : Texture2D
var _tex_bomb : Texture2D


func _ready() -> void:
	randomize()
	_tex_safe = load("res://Assets/Lucky Lou/download1.png")
	_tex_bomb = load("res://Assets/Tilt Tony/Tilt Tony no background.png")
	_build_styles()

	# Populate difficulty dropdown
	for name in DIFF_NAMES:
		risk_option.add_item(name)
	risk_option.selected = difficulty
	_style_popup()

	_build_grid()

	bet_input.text_changed.connect(_on_bet_changed)
	half_btn.pressed.connect(_on_half)
	double_btn.pressed.connect(_on_double)
	risk_option.item_selected.connect(_on_difficulty_selected)
	action_btn.pressed.connect(_on_action)
	back_btn.pressed.connect(_on_back)

	_update_hud()
	_set_idle_ui()


# ── Styles ────────────────────────────────────────────────────────────────────

func _build_styles() -> void:
	_style_hidden = _make_flat(Color(0.094, 0.063, 0.031, 1), Color(0.659, 0.408, 0.125, 1))
	_style_active = _make_flat(Color(0.188, 0.125, 0.047, 1), Color(0.973, 0.847, 0.188, 1))
	_style_hover  = _make_flat(Color(0.220, 0.157, 0.063, 1), Color(0.973, 0.847, 0.188, 1))
	_style_safe   = _make_flat(Color(0.063, 0.157, 0.094, 1), Color(0.220, 0.471, 0.282, 1))
	_style_bomb   = _make_flat(Color(0.157, 0.047, 0.047, 1), Color(0.471, 0.188, 0.188, 1))
	_style_grey   = _make_flat(Color(0.071, 0.071, 0.071, 1), Color(0.157, 0.157, 0.157, 1))
	_sb_popup     = _make_flat(Color(0.125, 0.094, 0.047, 1), Color(0.659, 0.408, 0.125, 1))


func _make_flat(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color            = bg
	s.border_color        = border
	s.border_width_left   = 2
	s.border_width_top    = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	return s


func _style_popup() -> void:
	var popup := risk_option.get_popup()
	popup.add_theme_stylebox_override("panel",        _sb_popup)
	popup.add_theme_stylebox_override("hover",        _make_flat(Color(0.220, 0.157, 0.063, 1), Color(0.973, 0.847, 0.188, 1)))
	popup.add_theme_color_override("font_color",       Color(0.973, 0.847, 0.188, 1))
	popup.add_theme_color_override("font_hover_color", Color(0.973, 0.973, 0.973, 1))
	popup.add_theme_font_size_override("font_size",    15)


# ── Difficulty helpers ────────────────────────────────────────────────────────

func _cols()  -> int: return DIFF_COLS[difficulty]
func _traps() -> int: return DIFF_TRAPS[difficulty]
func _safe()  -> int: return _cols() - _traps()


func _multiplier(rows_cleared: int) -> float:
	if rows_cleared == 0:
		return 1.0
	return pow(float(_cols()) / float(_safe()), float(rows_cleared))


func _on_difficulty_selected(idx: int) -> void:
	if state != State.IDLE:
		return
	difficulty = idx
	_build_grid()
	_update_payout_display()


# ── Grid ──────────────────────────────────────────────────────────────────────

func _build_grid() -> void:
	for child in tile_grid.get_children():
		child.queue_free()
	tile_rows.clear()

	var cols := _cols()

	for row in ROWS:
		var row_arr : Array[Button] = []
		for col in cols:
			var btn := Button.new()
			btn.size_flags_horizontal     = 3
			btn.size_flags_vertical       = 3
			btn.custom_minimum_size       = Vector2(0, 52)
			btn.icon_alignment            = HORIZONTAL_ALIGNMENT_CENTER
			btn.vertical_icon_alignment   = VERTICAL_ALIGNMENT_CENTER
			btn.add_theme_font_size_override("font_size", 14)
			btn.add_theme_color_override("font_color",          Color(0.973, 0.847, 0.188, 1))
			btn.add_theme_color_override("font_hover_color",    Color(0.973, 0.973, 0.973, 1))
			btn.add_theme_color_override("font_pressed_color",  Color(0.973, 0.847, 0.188, 1))
			btn.add_theme_color_override("font_disabled_color", Color(0.627, 0.502, 0.376, 1))
			_set_tile_hidden(btn)
			btn.disabled = true
			btn.pressed.connect(_on_tile_pressed.bind(row, col))
			row_arr.append(btn)
		tile_rows.append(row_arr)

	# VBoxContainer: add top row first (ROWS-1), bottom row last (0)
	for row in range(ROWS - 1, -1, -1):
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		hbox.size_flags_horizontal = 3
		hbox.size_flags_vertical   = 3
		for col in cols:
			hbox.add_child(tile_rows[row][col])
		tile_grid.add_child(hbox)


# ── Tile helpers ──────────────────────────────────────────────────────────────

func _set_tile_hidden(btn: Button) -> void:
	btn.text        = ""
	btn.icon        = null
	btn.expand_icon = false
	btn.add_theme_stylebox_override("normal",   _style_hidden)
	btn.add_theme_stylebox_override("hover",    _style_hover)
	btn.add_theme_stylebox_override("pressed",  _style_hidden)
	btn.add_theme_stylebox_override("focus",    _style_hidden)
	btn.add_theme_stylebox_override("disabled", _style_hidden)


func _set_tile_grey(btn: Button) -> void:
	btn.text        = ""
	btn.icon        = null
	btn.expand_icon = false
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, _style_grey)


func _set_tile_active(btn: Button) -> void:
	btn.text        = ""
	btn.icon        = null
	btn.expand_icon = false
	btn.add_theme_stylebox_override("normal",   _style_active)
	btn.add_theme_stylebox_override("hover",    _style_hover)
	btn.add_theme_stylebox_override("pressed",  _style_active)
	btn.add_theme_stylebox_override("focus",    _style_active)
	btn.add_theme_stylebox_override("disabled", _style_active)


func _set_tile_safe(btn: Button) -> void:
	btn.text                    = ""
	btn.icon                    = _tex_safe
	btn.expand_icon             = true
	btn.icon_alignment          = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, _style_safe)


func _set_tile_bomb(btn: Button) -> void:
	btn.text                    = ""
	btn.icon                    = _tex_bomb
	btn.expand_icon             = true
	btn.icon_alignment          = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, _style_bomb)


# ── Bet controls ──────────────────────────────────────────────────────────────

func _on_bet_changed(_text: String) -> void:
	if state == State.IDLE:
		_update_payout_display()


func _on_half() -> void:
	var bet := bet_input.text.to_float()
	if bet > 0.0:
		bet_input.text = "%.0f" % maxf(MIN_BET, bet * 0.5)
		_update_payout_display()


func _on_double() -> void:
	var bet := bet_input.text.to_float()
	if bet > 0.0:
		bet_input.text = "%.0f" % (bet * 2.0)
		_update_payout_display()


# ── Game flow ─────────────────────────────────────────────────────────────────

func _on_action() -> void:
	match state:
		State.IDLE:      _start_game()
		State.PLAYING:   _cash_out()
		State.GAME_OVER: _reset_game()


func _start_game() -> void:
	var bet := bet_input.text.to_float()
	if bet < MIN_BET:
		payout_label.add_theme_color_override("font_color", Color(0.973, 0.973, 0.439, 1))
		payout_label.text = "Min $%s" % _fmt(MIN_BET)
		return
	if bet > GameState.bankroll:
		payout_label.add_theme_color_override("font_color", Color(0.973, 0.973, 0.439, 1))
		payout_label.text = "No funds"
		return

	current_bet = bet
	current_row = 0
	state       = State.PLAYING

	_generate_bombs()

	for row in ROWS:
		for col in _cols():
			_set_tile_hidden(tile_rows[row][col])
			tile_rows[row][col].disabled = true

	_activate_row(current_row)

	bet_input.editable    = false
	half_btn.disabled     = true
	double_btn.disabled   = true
	risk_option.disabled  = true

	_set_playing_ui()
	_update_payout_display()


func _generate_bombs() -> void:
	bomb_cols.clear()
	var traps := _traps()
	var cols  := _cols()
	for row in ROWS:
		var order := range(cols)
		order.shuffle()
		bomb_cols.append(order.slice(0, traps))


func _activate_row(row: int) -> void:
	for col in _cols():
		_set_tile_active(tile_rows[row][col])
		tile_rows[row][col].disabled = false


func _on_tile_pressed(row: int, col: int) -> void:
	if state != State.PLAYING or row != current_row:
		return

	for c in _cols():
		tile_rows[row][c].disabled = true

	if col in bomb_cols[row]:
		_set_tile_bomb(tile_rows[row][col])
		_on_bomb_hit()
	else:
		for c in _cols():
			if c == col:
				_set_tile_safe(tile_rows[row][c])
			else:
				_set_tile_grey(tile_rows[row][c])
		current_row += 1
		if current_row >= ROWS:
			_cash_out()
		else:
			_activate_row(current_row)
			_set_playing_ui()
			_update_payout_display()


func _reveal_row(row: int) -> void:
	for col in _cols():
		var btn : Button = tile_rows[row][col]
		btn.disabled = true
		if col in bomb_cols[row]:
			_set_tile_bomb(btn)
		else:
			_set_tile_safe(btn)


func _reveal_all() -> void:
	for row in ROWS:
		_reveal_row(row)


func _on_bomb_hit() -> void:
	state = State.GAME_OVER
	_reveal_all()

	GameState.bankroll -= current_bet

	payout_label.add_theme_color_override("font_color", Color(0.973, 0.376, 0.376, 1))
	payout_label.text = "-$%s" % _fmt(current_bet)
	next_label.text   = ""
	_set_game_over_ui()
	_update_hud()


func _cash_out() -> void:
	if current_row == 0:
		return
	state = State.GAME_OVER

	var mult   := _multiplier(current_row)
	var profit := current_bet * (mult - 1.0)
	GameState.bankroll += profit
	GameState.add_fame(TOWN_ID, profit)

	_reveal_all()


	payout_label.add_theme_color_override("font_color", Color(0.376, 0.973, 0.502, 1))
	payout_label.text = "+$%s" % _fmt(profit)
	next_label.text   = ""
	_set_game_over_ui()
	_update_hud()


func _reset_game() -> void:
	state       = State.IDLE
	current_row = 0

	for row in ROWS:
		for col in _cols():
			tile_rows[row][col].disabled = true
			_set_tile_hidden(tile_rows[row][col])
			tile_rows[row][col].add_theme_color_override("font_color",          Color(0.973, 0.847, 0.188, 1))
			tile_rows[row][col].add_theme_color_override("font_disabled_color", Color(0.627, 0.502, 0.376, 1))

	bet_input.editable   = true
	half_btn.disabled    = false
	double_btn.disabled  = false
	risk_option.disabled = false

	_set_idle_ui()
	_update_payout_display()


# ── UI state helpers ──────────────────────────────────────────────────────────

func _set_idle_ui() -> void:
	action_btn.text     = "Start"
	action_btn.disabled = false
	payout_label.add_theme_color_override("font_color", Color(0.973, 0.847, 0.188, 1))
	payout_label.text   = "$--"
	next_label.text     = "Next: %.4fx" % _multiplier(1)


func _set_playing_ui() -> void:
	action_btn.text     = "Cash Out"
	action_btn.disabled = (current_row == 0)


func _set_game_over_ui() -> void:
	action_btn.text     = "New Game"
	action_btn.disabled = false


func _update_payout_display() -> void:
	if state == State.IDLE or current_row == 0:
		payout_label.add_theme_color_override("font_color", Color(0.973, 0.847, 0.188, 1))
		payout_label.text = "$--"
		next_label.text   = "Next: %.4fx" % _multiplier(1)
		return
	payout_label.add_theme_color_override("font_color", Color(0.973, 0.847, 0.188, 1))
	payout_label.text = "$%s" % _fmt(current_bet * _multiplier(current_row))
	next_label.text   = "Next: %.4fx" % _multiplier(current_row + 1) if current_row < ROWS else ""


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
