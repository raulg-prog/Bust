extends Control

const SPIN_FRAME_COUNT := 16   # one full rotation: edge→H peak→edge→T peak→edge
const HEADS_FRAME_IDX  := 16   # heads landing face (frame 16)
const TAILS_FRAME_IDX  := 17   # tails landing face (frame 17)
const TOTAL_FRAMES     := 18   # total frames in coin_spin.png
const HEADS_PEAK_FRAME := 4    # frame where heads is widest during spin
const TAILS_PEAK_FRAME := 12   # frame where tails is widest during spin
const TOWN_ID          := 0
const MIN_BET          := 10.0

var COIN_STRIP: Texture2D

enum State { IDLE, FLIPPING, ACTIVE }

var state:         State = State.IDLE
var selected_side: int   = -1   # 0 = heads, 1 = tails
var current_bet:   float = 0.0
var multiplier:    float = 1.0
var last_landed_heads: bool = true

var _fw: int   # frame width (strip width / TOTAL_FRAMES)
var _fh: int   # frame height

@onready var balance_label: Label       = %BalanceLabel
@onready var fame_label:    Label       = %FameLabel
@onready var coin_sprite:   TextureRect = %CoinSprite
@onready var mult_value:    Label       = %MultValue
@onready var heads_btn:     Button      = %HeadsButton
@onready var tails_btn:     Button      = %TailsButton
@onready var flip_btn:      Button      = %FlipButton
@onready var cashout_btn:   Button      = %CashOutButton
@onready var result_label:  Label       = %ResultLabel
@onready var bet_input:     LineEdit    = %BetInput


func _ready() -> void:
	COIN_STRIP = load("res://Assets/Coin/coin_spin.png")

	if COIN_STRIP:
		_fw = COIN_STRIP.get_width() / TOTAL_FRAMES
		_fh = COIN_STRIP.get_height()

	heads_btn.pressed.connect(func(): _select(0))
	tails_btn.pressed.connect(func(): _select(1))
	flip_btn.pressed.connect(_on_flip)
	cashout_btn.pressed.connect(_on_cashout)

	_apply_state(State.IDLE)
	_update_hud()


func _select(side: int) -> void:
	if state == State.FLIPPING:
		return
	selected_side = side
	_refresh_selection()
	flip_btn.disabled = false


func _refresh_selection() -> void:
	var gold := Color(1.0, 0.878, 0.2, 1)
	var blue := Color(0.5, 0.78,  1.0, 1)
	var dim  := Color(1.0, 1.0,   1.0, 0.3)
	match selected_side:
		0:
			heads_btn.modulate = gold
			tails_btn.modulate = dim
		1:
			heads_btn.modulate = dim
			tails_btn.modulate = blue
		_:
			heads_btn.modulate = gold
			tails_btn.modulate = blue


func _on_flip() -> void:
	if state == State.IDLE:
		var bet := bet_input.text.to_float()
		if bet < MIN_BET:
			result_label.text = "Minimum bet: $%s" % _fmt(MIN_BET)
			return
		if bet > GameState.bankroll:
			result_label.text = "Not enough funds."
			return
		current_bet       = bet
		multiplier        = 1.0
		result_label.text = ""

	var lands_heads := randf() < 0.5
	_apply_state(State.FLIPPING)
	_animate(lands_heads)


func _animate(lands_heads: bool) -> void:
	var tween      := create_tween()
	var peak_frame := HEADS_PEAK_FRAME if lands_heads else TAILS_PEAK_FRAME
	var face_frame := HEADS_FRAME_IDX  if lands_heads else TAILS_FRAME_IDX

	# Fast: 3 full rotation cycles, starting from the half opposite the current face.
	# If heads is showing → start at frame 8 (tails half) so tails appears first.
	# If tails is showing → start at frame 0 (heads half) so heads appears first.
	var start_frame := 8 if last_landed_heads else 0
	for _c in range(3):
		for i in range(SPIN_FRAME_COUNT):
			tween.tween_callback(_show_strip_frame.bind((start_frame + i) % SPIN_FRAME_COUNT))
			tween.tween_interval(0.055)

	# Slow approach from frame 0 up to the peak of the winning face.
	# Last fast frame is always frame (start_frame - 1) % 16, which is near-edge,
	# so continuing from 0 (edge) flows naturally: edge → winning face expanding → peak.
	for f in range(peak_frame + 1):
		tween.tween_callback(_show_strip_frame.bind(f))
		tween.tween_interval(0.13)

	# Brief pause at peak width, then snap to the full landing face
	tween.tween_interval(0.30)
	tween.tween_callback(_show_strip_frame.bind(face_frame))
	tween.tween_interval(0.4)
	tween.tween_callback(_on_flip_done.bind(lands_heads))


func _show_strip_frame(frame_idx: int) -> void:
	if not COIN_STRIP:
		return
	var atlas           := AtlasTexture.new()
	atlas.atlas          = COIN_STRIP
	atlas.region         = Rect2(frame_idx * _fw, 0, _fw, _fh)
	coin_sprite.texture  = atlas


func _on_flip_done(landed_heads: bool) -> void:
	last_landed_heads = landed_heads
	var won := (landed_heads and selected_side == 0) or \
			   (not landed_heads and selected_side == 1)
	if won:
		multiplier        *= 2.0
		mult_value.text    = "%.2fx" % multiplier
		cashout_btn.text   = "CASH OUT  $%s" % _fmt(current_bet * multiplier)
		result_label.text  = "Correct!  Running: %.2fx" % multiplier
		_apply_state(State.ACTIVE)
	else:
		GameState.bankroll -= current_bet
		result_label.text   = "-$%s  (%.2fx streak lost)" % [_fmt(current_bet), multiplier]
		_apply_state(State.IDLE)
		_update_hud()


func _on_cashout() -> void:
	var profit        := current_bet * (multiplier - 1.0)
	GameState.bankroll += profit
	GameState.add_fame(TOWN_ID, profit)
	result_label.text  = "Cashed out: +$%s  (%.2fx)" % [_fmt(profit), multiplier]
	_apply_state(State.IDLE)
	_update_hud()


func _apply_state(new_state: State) -> void:
	state = new_state
	var idle     := new_state == State.IDLE
	var flipping := new_state == State.FLIPPING

	bet_input.editable    = idle
	heads_btn.disabled    = flipping
	tails_btn.disabled    = flipping
	flip_btn.disabled     = flipping or selected_side == -1
	cashout_btn.disabled  = idle or flipping

	if idle:
		mult_value.text    = "1.00x"
		cashout_btn.text   = "CASH OUT"
		_show_strip_frame(HEADS_FRAME_IDX if last_landed_heads else TAILS_FRAME_IDX)

	_refresh_selection()
	flip_btn.modulate = Color(1.0, 0.85, 0.2, 1) if not flipping else Color(0.55, 0.55, 0.55, 1)


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
