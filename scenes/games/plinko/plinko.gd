extends Control

const TOWN_ID   : int   = 1
const MIN_BET   : float = 10.0
const ROWS      : int   = 12
const BUCKETS   : int   = 13
const STEP_TIME : float = 0.13

const MULTS : Array[float] = [
	500.0, 25.0, 7.0, 2.0, 0.5, 0.2, 0.1,
	0.2, 0.5, 2.0, 7.0, 25.0, 500.0
]
# Binomial weights C(12, k) — sum = 4096 = 2^12
const WEIGHTS : Array[int] = [1, 12, 66, 220, 495, 792, 924, 792, 495, 220, 66, 12, 1]

enum State { IDLE, DROPPING }
var state : State = State.IDLE

@onready var board       : PlinkoBoard = %Board
@onready var balance_lbl : Label       = %BalanceLabel
@onready var fame_lbl    : Label       = %FameLabel
@onready var result_lbl  : Label       = %ResultLabel
@onready var bet_input   : LineEdit    = %BetInput
@onready var drop_btn    : Button      = %DropButton
@onready var back_btn    : Button      = %BackButton


func _ready() -> void:
	randomize()
	drop_btn.pressed.connect(_on_drop)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn"))
	_update_hud()


func _on_drop() -> void:
	if state != State.IDLE:
		return
	var bet := bet_input.text.to_float()
	if bet < MIN_BET:
		result_lbl.text = "Minimum bet: $%s" % _fmt(MIN_BET)
		return
	if bet > GameState.bankroll:
		result_lbl.text = "Not enough funds."
		return
	GameState.bankroll -= bet
	_update_hud()
	result_lbl.text = ""
	result_lbl.remove_theme_color_override("font_color")
	var bucket := _weighted_bucket()
	var path   := _build_path(bucket)
	state             = State.DROPPING
	drop_btn.disabled = true
	board.lit_bucket  = -1
	board.ball_pos    = path[0]
	_animate(path, bucket, bet)


# Weighted random bucket index matching binomial(12, 0.5) distribution.
func _weighted_bucket() -> int:
	var r   := randi() % 4096
	var cum := 0
	for i in range(BUCKETS):
		cum += WEIGHTS[i]
		if r < cum:
			return i
	return BUCKETS - 1


# Build a path of Vector2 waypoints through the peg grid that lands in `bucket`.
# `bucket` rights and (ROWS - bucket) lefts are shuffled to produce a natural-looking path.
func _build_path(bucket: int) -> Array[Vector2]:
	var steps : Array[int] = []
	for _i in range(bucket):
		steps.append(1)
	for _i in range(ROWS - bucket):
		steps.append(0)
	steps.shuffle()

	var path : Array[Vector2] = []
	path.append(board.spawn_pos())
	var col := 0
	for row in range(ROWS):
		path.append(board.peg_pos(row, col))
		col += steps[row]
	path.append(board.bucket_center(bucket))
	return path


func _animate(path: Array[Vector2], bucket: int, bet: float) -> void:
	var tw := create_tween()
	for i in range(1, path.size()):
		tw.tween_property(board, "ball_pos", path[i], STEP_TIME)
	tw.tween_callback(_on_drop_complete.bind(bucket, bet))


func _on_drop_complete(bucket: int, bet: float) -> void:
	var mult   := MULTS[bucket]
	var payout := bet * mult
	var net    := payout - bet
	GameState.bankroll += payout
	if net > 0.0:
		GameState.add_fame(TOWN_ID, net)
	_update_hud()
	board.lit_bucket = bucket

	var mult_str := _fmt_mult(mult)
	if net > 0.0:
		result_lbl.add_theme_color_override("font_color", Color(0.376, 0.973, 0.502, 1))
		result_lbl.text = "%s  +$%s" % [mult_str, _fmt(net)]
	else:
		result_lbl.add_theme_color_override("font_color", Color(0.973, 0.376, 0.376, 1))
		result_lbl.text = "%s  -$%s" % [mult_str, _fmt(-net)]

	state             = State.IDLE
	drop_btn.disabled = false


func _update_hud() -> void:
	balance_lbl.text = "Balance:  $%s" % _fmt(GameState.bankroll)
	fame_lbl.text    = "%s / %s Fame" % [
		_fmt(GameState.town_fame[TOWN_ID]),
		_fmt(GameState.FAME_TARGETS[TOWN_ID])
	]


func _fmt_mult(m: float) -> String:
	if m >= 10.0:
		return "%dx" % int(m)
	elif m >= 1.0:
		return "%.0fx" % m
	else:
		return "%.1fx" % m


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
