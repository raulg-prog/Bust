extends Control

const CARD_SHEET     = preload("res://Assets/Cards/1.2 Poker cards.png")
const MINI_SHEET     = preload("res://Assets/Cards/minicards.png")
const CARD_SHADER    = preload("res://scenes/games/hilo/card_contrast.gdshader")

# Full card atlas constants
const CARD_W      := 46
const CARD_H      := 62
const COL_STRIDE  := 48
const ROW_STRIDE  := 64
const BACK_Y      := 257

# Mini card atlas constants (for history strip)
const MINI_W          := 15
const MINI_H          := 22
const MINI_COL_STRIDE := 32
const MINI_ROW_STRIDE := 32
const MINI_OFFSET_X   := 17
const MINI_OFFSET_Y   := 7
const MINI_DISPLAY_W  := 30   # 2× upscale
const MINI_DISPLAY_H  := 44

const SUITS      := 4
const MAX_SKIPS  := 10
const TOWN_ID    := 0
const MIN_BET    := 10.0

enum State { IDLE, ACTIVE }

var state: State         = State.IDLE
var current_card: int    = 0
var current_suit: int    = 0
var current_bet: float   = 0.0
var multiplier: float    = 1.0
var skips_used: int      = 0
var card_history: Array[Vector2i] = []  # x=value, y=suit

@onready var balance_label: Label             = %BalanceLabel
@onready var fame_label: Label                = %FameLabel
@onready var history_container: HBoxContainer = %HistoryContainer
@onready var mult_value: Label                = %MultValue
@onready var card_sprite: TextureRect         = %CardSprite
@onready var higher_odds: Label               = %HigherOddsLabel
@onready var lower_odds: Label                = %LowerOddsLabel
@onready var higher_btn: Button               = %HigherButton
@onready var lower_btn: Button                = %LowerButton
@onready var skip_btn: Button                 = %SkipButton
@onready var result_label: Label              = %ResultLabel
@onready var bet_input: LineEdit              = %BetInput
@onready var bet_btn: Button                  = %BetButton


func _ready() -> void:
	higher_btn.pressed.connect(func(): _guess(1))
	lower_btn.pressed.connect(func(): _guess(-1))
	skip_btn.pressed.connect(_on_skip)
	bet_btn.pressed.connect(_on_bet_btn)
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Towns/Town1.tscn"))
	_apply_state(State.IDLE)
	card_sprite.texture = _back_tex()
	_update_hud()


func _on_bet_btn() -> void:
	if state == State.IDLE:
		_start_round()
	else:
		_cashout()


func _start_round() -> void:
	var bet := bet_input.text.to_float()
	if bet < MIN_BET:
		result_label.text = "Minimum bet: $%s" % _fmt(MIN_BET)
		return
	if bet > GameState.bankroll:
		result_label.text = "Not enough funds."
		return
	current_bet = bet
	multiplier  = 1.0
	skips_used  = 0
	result_label.text = ""
	card_history.clear()
	_draw_card()
	card_history.append(Vector2i(current_card, current_suit))
	_update_history()
	_apply_state(State.ACTIVE)


func _on_skip() -> void:
	skips_used += 1
	skip_btn.text = "SKIP (%d/%d)" % [skips_used, MAX_SKIPS]
	if skips_used >= MAX_SKIPS:
		skip_btn.disabled = true
	_draw_card()
	if card_history.size() > 0:
		card_history[card_history.size() - 1] = Vector2i(current_card, current_suit)
	_update_history()


func _cashout() -> void:
	var profit := current_bet * (multiplier - 1.0)
	GameState.bankroll += profit
	GameState.add_fame(TOWN_ID, profit)
	result_label.text = "Cashed out: +$%s  (%.2fx)" % [_fmt(profit), multiplier]
	_apply_state(State.IDLE)
	_update_hud()


func _guess(direction: int) -> void:
	var new_card := randi_range(1, 13)
	var new_suit := randi_range(0, SUITS - 1)
	var won      := new_card >= current_card if direction == 1 else new_card <= current_card

	card_sprite.texture = _card_tex(new_card, new_suit)
	card_history.append(Vector2i(new_card, new_suit))
	_update_history()

	if won:
		var step_mult := 1.0 / _p_win(current_card, direction)
		multiplier    *= step_mult
		current_card   = new_card
		current_suit   = new_suit
		_update_mult_display()
		_update_odds()
		result_label.text = "Correct!  Running: %.2fx" % multiplier
	else:
		GameState.bankroll -= current_bet
		result_label.text = "-$%s  (%.2fx streak lost)" % [_fmt(current_bet), multiplier]
		_apply_state(State.IDLE)
		_update_hud()


func _p_win(card: int, direction: int) -> float:
	return float(14 - card) / 13.0 if direction == 1 else float(card) / 13.0


func _draw_card() -> void:
	current_card = randi_range(1, 13)
	current_suit = randi_range(0, SUITS - 1)
	card_sprite.texture = _card_tex(current_card, current_suit)
	_update_odds()


func _card_tex(value: int, suit: int) -> AtlasTexture:
	var atlas   := AtlasTexture.new()
	atlas.atlas  = CARD_SHEET
	atlas.region = Rect2(1 + (value - 1) * COL_STRIDE, 1 + suit * ROW_STRIDE, CARD_W, CARD_H)
	return atlas


func _back_tex() -> AtlasTexture:
	var atlas   := AtlasTexture.new()
	atlas.atlas  = CARD_SHEET
	atlas.region = Rect2(1, BACK_Y, CARD_W, CARD_H)
	return atlas


func _mini_card_tex(value: int, suit: int) -> AtlasTexture:
	var atlas   := AtlasTexture.new()
	atlas.atlas  = MINI_SHEET
	atlas.region = Rect2(
		MINI_OFFSET_X + (value - 1) * MINI_COL_STRIDE,
		MINI_OFFSET_Y + suit * MINI_ROW_STRIDE,
		MINI_W, MINI_H
	)
	return atlas


func _update_history() -> void:
	for child in history_container.get_children():
		child.queue_free()
	for entry in card_history:
		var rect := TextureRect.new()
		rect.texture              = _mini_card_tex(entry.x, entry.y)
		rect.stretch_mode         = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size  = Vector2(MINI_DISPLAY_W, MINI_DISPLAY_H)
		rect.texture_filter       = CanvasItem.TEXTURE_FILTER_NEAREST
		var mat := ShaderMaterial.new()
		mat.shader = CARD_SHADER
		rect.material = mat
		history_container.add_child(rect)


func _update_odds() -> void:
	var p_h := _p_win(current_card, 1)
	var p_l := _p_win(current_card, -1)
	higher_odds.text = "%.1f%%  •  %.2fx" % [p_h * 100.0, 1.0 / p_h]
	lower_odds.text  = "%.1f%%  •  %.2fx" % [p_l * 100.0, 1.0 / p_l]


func _update_mult_display() -> void:
	mult_value.text = "%.2fx" % multiplier
	bet_btn.text    = "CASH OUT  $%s" % _fmt(current_bet * multiplier)


func _apply_state(new_state: State) -> void:
	state = new_state
	var active         := new_state == State.ACTIVE
	bet_input.editable  = not active
	higher_btn.disabled = not active
	lower_btn.disabled  = not active
	skip_btn.disabled   = not active
	if active:
		bet_btn.text     = "CASH OUT  $%s" % _fmt(current_bet * multiplier)
		bet_btn.modulate = Color(0.973, 0.816, 0.188, 1)
	else:
		bet_btn.text     = "BET"
		bet_btn.modulate = Color(1.0, 1.0, 1.0, 1)
		mult_value.text  = "1.00x"
		skip_btn.text    = "SKIP (0/%d)" % MAX_SKIPS
		higher_odds.text = ""
		lower_odds.text  = ""


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
