extends Control

const TOWN_ID   := 3
const MIN_BET   := 10.0
const MIN_MINES := 1

enum State { IDLE, PLAYING, GAME_OVER }

var state       : State = State.IDLE
var grid_size   : int   = 25
var mine_count  : int   = 3
var mine_pos    : Array = []   # Array[bool] — true = mine
var revealed    : int   = 0
var current_bet : float = 0.0

@onready var balance_label : Label         = %BalanceLabel
@onready var fame_label    : Label         = %FameLabel
@onready var bet_input     : LineEdit      = %BetInput
@onready var half_btn      : Button        = %HalfBtn
@onready var double_btn    : Button        = %TwoXBtn
@onready var safe_label    : Label         = %SafeLabel
@onready var mine_slider   : HSlider       = %MineSlider
@onready var mine_label    : Label         = %MineLabel
@onready var payout_label  : Label         = %PayoutLabel
@onready var next_label    : Label         = %NextLabel
@onready var action_btn    : Button        = %ActionButton
@onready var back_btn      : Button        = %BackButton
@onready var tile_grid     : GridContainer = %TileGrid
@onready var gs_btn_25     : Button        = %GS25
@onready var gs_btn_36     : Button        = %GS36
@onready var gs_btn_49     : Button        = %GS49
@onready var gs_btn_64     : Button        = %GS64

var tile_btns : Array[Button] = []

var _tex_safe : Texture2D
var _tex_mine : Texture2D

var _style_hidden : StyleBoxFlat
var _style_hover  : StyleBoxFlat
var _style_safe   : StyleBoxFlat
var _style_mine   : StyleBoxFlat

var _style_gs_sel   : StyleBoxFlat
var _style_gs_unsel : StyleBoxFlat
var _style_gs_hover : StyleBoxFlat


func _ready() -> void:
	randomize()
	_tex_safe = load("res://Assets/Lucky Lou/download1.png")
	_tex_mine = load("res://Assets/Tilt Tony/Tilt Tony no background.png")
	_build_styles()
	_build_grid()

	bet_input.text_changed.connect(_on_bet_changed)
	half_btn.pressed.connect(_on_half)
	double_btn.pressed.connect(_on_double)
	mine_slider.value_changed.connect(_on_mine_slider_changed)
	action_btn.pressed.connect(_on_action)
	back_btn.pressed.connect(_on_back)
	gs_btn_25.pressed.connect(_on_grid_size_selected.bind(25))
	gs_btn_36.pressed.connect(_on_grid_size_selected.bind(36))
	gs_btn_49.pressed.connect(_on_grid_size_selected.bind(49))
	gs_btn_64.pressed.connect(_on_grid_size_selected.bind(64))

	_apply_gs_styles()
	_update_hud()
	_update_mine_labels()
	_set_idle_ui()


# ── Styles ──────────────────────────────────────────────────────────────────

func _build_styles() -> void:
	_style_hidden = _make_flat(Color(0.094, 0.063, 0.031, 1), Color(0.659, 0.408, 0.125, 1))
	_style_hover  = _make_flat(Color(0.220, 0.157, 0.063, 1), Color(0.973, 0.847, 0.188, 1))
	_style_safe   = _make_flat(Color(0.063, 0.157, 0.094, 1), Color(0.220, 0.471, 0.282, 1))
	_style_mine   = _make_flat(Color(0.157, 0.047, 0.047, 1), Color(0.471, 0.188, 0.188, 1))

	_style_gs_sel   = _make_gs_flat(Color(0.659, 0.408, 0.125, 1), Color(0.973, 0.847, 0.188, 1))
	_style_gs_unsel = _make_gs_flat(Color(0.094, 0.063, 0.031, 1), Color(0.314, 0.220, 0.094, 1))
	_style_gs_hover = _make_gs_flat(Color(0.188, 0.125, 0.063, 1), Color(0.973, 0.847, 0.188, 1))


func _make_flat(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left   = 2
	s.border_width_top    = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	return s


func _make_gs_flat(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left   = 2
	s.border_width_top    = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	s.content_margin_left   = 6.0
	s.content_margin_top    = 6.0
	s.content_margin_right  = 6.0
	s.content_margin_bottom = 6.0
	s.corner_radius_top_left     = 4
	s.corner_radius_top_right    = 4
	s.corner_radius_bottom_left  = 4
	s.corner_radius_bottom_right = 4
	return s


# ── Grid size selector ───────────────────────────────────────────────────────

func _on_grid_size_selected(size: int) -> void:
	if state != State.IDLE:
		return
	grid_size  = size
	mine_count = clampi(mine_count, MIN_MINES, grid_size - 1)
	mine_slider.max_value = float(grid_size - 1)
	mine_slider.value     = float(mine_count)
	_apply_gs_styles()
	_build_grid()
	_update_mine_labels()
	_update_payout_display()


func _apply_gs_styles() -> void:
	_style_one_gs(gs_btn_25, 25)
	_style_one_gs(gs_btn_36, 36)
	_style_one_gs(gs_btn_49, 49)
	_style_one_gs(gs_btn_64, 64)


func _style_one_gs(btn: Button, size: int) -> void:
	var sel := (size == grid_size)
	btn.add_theme_stylebox_override("normal",   _style_gs_sel   if sel else _style_gs_unsel)
	btn.add_theme_stylebox_override("hover",    _style_gs_hover)
	btn.add_theme_stylebox_override("pressed",  _style_gs_sel)
	btn.add_theme_stylebox_override("focus",    _style_gs_sel   if sel else _style_gs_unsel)
	btn.add_theme_stylebox_override("disabled", _style_gs_sel   if sel else _style_gs_unsel)
	var fc := Color(0.973, 0.847, 0.188, 1) if sel else Color(0.627, 0.502, 0.376, 1)
	btn.add_theme_color_override("font_color",          fc)
	btn.add_theme_color_override("font_disabled_color", fc)


func _lock_gs_buttons(locked: bool) -> void:
	gs_btn_25.disabled = locked
	gs_btn_36.disabled = locked
	gs_btn_49.disabled = locked
	gs_btn_64.disabled = locked


# ── Tile grid ────────────────────────────────────────────────────────────────

func _build_grid() -> void:
	for child in tile_grid.get_children():
		child.queue_free()
	tile_btns.clear()

	var cols := int(sqrt(float(grid_size)))
	tile_grid.columns = cols

	var tile_size : int
	match grid_size:
		25: tile_size = 76
		36: tile_size = 68
		49: tile_size = 60
		_:  tile_size = 52   # 64

	for i in grid_size:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(tile_size, tile_size)
		btn.add_theme_font_size_override("font_size", 28)
		btn.add_theme_color_override("font_color",          Color(0.973, 0.847, 0.188, 1))
		btn.add_theme_color_override("font_hover_color",    Color(0.973, 0.973, 0.973, 1))
		btn.add_theme_color_override("font_pressed_color",  Color(0.973, 0.847, 0.188, 1))
		btn.add_theme_color_override("font_disabled_color", Color(0.627, 0.502, 0.376, 1))
		_reset_tile_style(btn)
		btn.disabled = true
		btn.pressed.connect(_on_tile_pressed.bind(i))
		tile_grid.add_child(btn)
		tile_btns.append(btn)


func _reset_tile_style(btn: Button) -> void:
	btn.text         = ""
	btn.icon         = null
	btn.expand_icon  = false
	btn.add_theme_stylebox_override("normal",   _style_hidden)
	btn.add_theme_stylebox_override("hover",    _style_hover)
	btn.add_theme_stylebox_override("pressed",  _style_hidden)
	btn.add_theme_stylebox_override("focus",    _style_hidden)
	btn.add_theme_stylebox_override("disabled", _style_hidden)


# ── Bet controls ─────────────────────────────────────────────────────────────

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


func _on_mine_slider_changed(value: float) -> void:
	mine_count = int(value)
	_update_mine_labels()
	_update_payout_display()


# ── Game flow ────────────────────────────────────────────────────────────────

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
	revealed    = 0
	state       = State.PLAYING

	mine_pos.clear()
	mine_pos.resize(grid_size)
	mine_pos.fill(false)
	var order := range(grid_size)
	order.shuffle()
	for i in mine_count:
		mine_pos[order[i]] = true

	for btn in tile_btns:
		_reset_tile_style(btn)
		btn.disabled = false

	bet_input.editable    = false
	half_btn.disabled     = true
	double_btn.disabled   = true
	mine_slider.editable  = false
	_lock_gs_buttons(true)

	_set_playing_ui()
	_update_payout_display()


func _on_tile_pressed(idx: int) -> void:
	if state != State.PLAYING:
		return
	var btn := tile_btns[idx]
	btn.disabled = true

	if mine_pos[idx]:
		_reveal_tile(btn, true)
		_on_mine_hit()
	else:
		revealed += 1
		_reveal_tile(btn, false)
		if grid_size - mine_count - revealed == 0:
			_cash_out()
			_reveal_all()
		else:
			_update_payout_display()
			_set_playing_ui()


func _reveal_tile(btn: Button, is_mine: bool) -> void:
	btn.text        = ""
	btn.expand_icon = true
	if is_mine:
		btn.icon = _tex_mine
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(s, _style_mine)
	else:
		btn.icon = _tex_safe
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(s, _style_safe)


func _reveal_all() -> void:
	for i in grid_size:
		tile_btns[i].disabled = true
		_reveal_tile(tile_btns[i], mine_pos[i])


func _on_mine_hit() -> void:
	state = State.GAME_OVER
	_reveal_all()
	GameState.bankroll -= current_bet

	payout_label.add_theme_color_override("font_color", Color(0.973, 0.376, 0.376, 1))
	payout_label.text = "-$%s" % _fmt(current_bet)
	next_label.text   = ""
	_set_game_over_ui()
	_update_hud()


func _cash_out() -> void:
	if revealed == 0:
		return
	state = State.GAME_OVER

	var mult   := _multiplier(revealed)
	var profit := current_bet * (mult - 1.0)
	GameState.bankroll += profit
	GameState.add_fame(TOWN_ID, profit)

	for btn in tile_btns:
		btn.disabled = true

	payout_label.add_theme_color_override("font_color", Color(0.376, 0.973, 0.502, 1))
	payout_label.text = "+$%s" % _fmt(profit)
	next_label.text   = ""
	_set_game_over_ui()
	_update_hud()


func _reset_game() -> void:
	state    = State.IDLE
	revealed = 0

	for btn in tile_btns:
		btn.disabled = true
		_reset_tile_style(btn)
		btn.add_theme_color_override("font_color",          Color(0.973, 0.847, 0.188, 1))
		btn.add_theme_color_override("font_disabled_color", Color(0.627, 0.502, 0.376, 1))

	bet_input.editable   = true
	half_btn.disabled    = false
	double_btn.disabled  = false
	mine_slider.editable = true
	_lock_gs_buttons(false)

	_set_idle_ui()
	_update_payout_display()


# ── Math ─────────────────────────────────────────────────────────────────────

func _multiplier(k: int) -> float:
	var s      := float(grid_size - mine_count)
	var result := 1.0
	for i in k:
		result *= float(grid_size - i) / (s - float(i))
	return result


# ── UI state helpers ─────────────────────────────────────────────────────────

func _set_idle_ui() -> void:
	action_btn.text     = "Start"
	action_btn.disabled = false
	next_label.text     = ""
	payout_label.add_theme_color_override("font_color", Color(0.973, 0.847, 0.188, 1))
	payout_label.text   = "$--"


func _set_playing_ui() -> void:
	action_btn.text     = "Cash Out"
	action_btn.disabled = (revealed == 0)


func _set_game_over_ui() -> void:
	action_btn.text     = "New Game"
	action_btn.disabled = false


func _update_payout_display() -> void:
	if state == State.IDLE:
		payout_label.add_theme_color_override("font_color", Color(0.973, 0.847, 0.188, 1))
		payout_label.text = "$--"
		next_label.text   = ""
		return
	if revealed == 0:
		payout_label.add_theme_color_override("font_color", Color(0.973, 0.847, 0.188, 1))
		payout_label.text = "$--"
		next_label.text   = "Next: %.4fx" % _multiplier(1)
		return
	payout_label.add_theme_color_override("font_color", Color(0.973, 0.847, 0.188, 1))
	payout_label.text = "$%s" % _fmt(current_bet * _multiplier(revealed))
	next_label.text   = "Next: %.4fx" % _multiplier(revealed + 1)


func _update_mine_labels() -> void:
	safe_label.text = "Safe  %d" % (grid_size - mine_count)
	mine_label.text = "%d  Mines" % mine_count


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
