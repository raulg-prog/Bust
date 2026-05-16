extends Control

const TOWN_ID := 0
const MIN_BET := 10.0

enum State { IDLE, ACTIVE }

var state: State = State.IDLE
var current_bet: float = 0.0
var multiplier: float = 1.0

@onready var coin_label: Label = $Center/GameArea/CoinPanel/CoinLabel
@onready var mult_value: Label = $Center/GameArea/MultiplierRow/MultValue
@onready var payout_value: Label = $Center/GameArea/PayoutRow/PayoutValue
@onready var bet_input: LineEdit = $Center/GameArea/BetRow/BetInput
@onready var bankroll_label: Label = $Center/GameArea/BankrollRow/BankrollLabel
@onready var fame_label: Label = $Center/GameArea/FameBar/FameValue
@onready var heads_btn: Button = $Center/GameArea/ChoiceRow/HeadsButton
@onready var tails_btn: Button = $Center/GameArea/ChoiceRow/TailsButton
@onready var cashout_btn: Button = $Center/GameArea/ChoiceRow/CashOutButton
@onready var result_label: Label = $Center/GameArea/ResultLabel


func _ready() -> void:
	heads_btn.pressed.connect(func(): _flip(true))
	tails_btn.pressed.connect(func(): _flip(false))
	cashout_btn.pressed.connect(_on_cashout)
	_apply_state(State.IDLE)
	_update_hud()


func _flip(chose_heads: bool) -> void:
	if state == State.IDLE:
		var bet := bet_input.text.to_float()
		if bet < MIN_BET:
			result_label.text = "Minimum bet: $%s" % _fmt(MIN_BET)
			return
		if bet > GameState.bankroll:
			result_label.text = "Not enough funds."
			return
		current_bet = bet
		multiplier = 1.0
		result_label.text = ""
		_apply_state(State.ACTIVE)

	var is_heads := randf() < 0.5
	coin_label.text = "HEADS" if is_heads else "TAILS"

	if is_heads == chose_heads:
		multiplier *= 2.0
		cashout_btn.disabled = false
		mult_value.text = "%.2fx" % multiplier
		payout_value.text = "$%s" % _fmt(current_bet * multiplier)
		result_label.text = "Correct!  Running: %.2fx" % multiplier
	else:
		GameState.bankroll -= current_bet
		result_label.text = "-$%s  (%.2fx streak lost)" % [_fmt(current_bet), multiplier]
		_apply_state(State.IDLE)
		_update_hud()


func _on_cashout() -> void:
	var profit := current_bet * (multiplier - 1.0)
	GameState.bankroll += profit
	GameState.add_fame(TOWN_ID, profit)
	result_label.text = "Cashed out: +$%s  (%.2fx)" % [_fmt(profit), multiplier]
	_apply_state(State.IDLE)
	_update_hud()


func _apply_state(new_state: State) -> void:
	state = new_state
	var active := new_state == State.ACTIVE
	bet_input.editable = not active
	cashout_btn.disabled = true
	if not active:
		coin_label.text = "?"
		mult_value.text = "1.00x"
		payout_value.text = "$0"


func _update_hud() -> void:
	bankroll_label.text = "$%s" % _fmt(GameState.bankroll)
	fame_label.text = "%s / %s" % [
		_fmt(GameState.town_fame[TOWN_ID]),
		_fmt(GameState.FAME_TARGETS[TOWN_ID])
	]


func _fmt(val: float) -> String:
	var s := "%.0f" % val
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0 and s[i] != "-":
			result = "," + result
		result = s[i] + result
		count += 1
	return result
