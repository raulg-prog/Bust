extends Control

const TOWN_ID   : int   = 1
const MIN_BET   : float = 10.0
const ROWS      : int   = 12
const BUCKETS   : int   = 13
const STEP_TIME : float = 0.11   # seconds per peg-to-peg arc

const BALL_SCENE = preload("res://scenes/games/plinko/Plinko_Ball.tscn")
const BALL_SCALE : float = 0.22

const MULTS : Array[float] = [
	170.0, 24.0, 8.1, 2.0, 0.7, 0.2, 0.2,
	0.2, 0.7, 2.0, 8.1, 24.0, 170.0
]

# Binomial weights C(12, k)  — sum = 4096 = 2^12
const WEIGHTS : Array[int] = [1, 12, 66, 220, 495, 792, 924, 792, 495, 220, 66, 12, 1]

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
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Towns/cascade.tscn"))
	_update_hud()


func _on_drop() -> void:
	var bet := bet_input.text.to_float()
	if bet < MIN_BET:
		result_lbl.text = "Minimum bet: $%s" % _fmt(MIN_BET)
		return
	if bet > GameState.bankroll:
		result_lbl.text = "Not enough funds."
		return
	GameState.bankroll -= bet
	_update_hud()

	var bucket := _weighted_bucket()
	var path   := _build_path(bucket)
	var ball   := BALL_SCENE.instantiate() as RigidBody2D
	ball.freeze   = true
	ball.scale    = Vector2(BALL_SCALE, BALL_SCALE)
	ball.position = path[0]
	board.add_child(ball)
	_animate_ball(ball, path, bucket, bet)


# True binomial distribution via weighted random selection.
func _weighted_bucket() -> int:
	var r   := randi() % 4096
	var cum := 0
	for i in range(BUCKETS):
		cum += WEIGHTS[i]
		if r < cum:
			return i
	return BUCKETS - 1


# Shuffle `bucket` right-steps and (ROWS-bucket) left-steps to get a valid
# path through the peg grid that lands exactly in `bucket`.
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
		var peg := board.peg_pos(row, col)
		col += steps[row]
		# Waypoint is the midpoint between this peg and the next destination.
		# Ball arcs through the gap between rows rather than landing on peg centres.
		var nxt := board.peg_pos(row + 1, col) if row < ROWS - 1 \
				else board.bucket_center(bucket)
		path.append(peg.lerp(nxt, 0.5))
	path.append(board.bucket_center(bucket))
	return path


func _animate_ball(ball: RigidBody2D, path: Array[Vector2], bucket: int, bet: float) -> void:
	var tw := create_tween()
	for i in range(1, path.size()):
		var fp := path[i - 1]
		var tp := path[i]
		# Parabolic arc: x moves linearly, y accelerates like gravity (t²).
		tw.tween_method(
			func(t: float) -> void:
				ball.position = Vector2(
					lerp(fp.x, tp.x, t),
					fp.y + (tp.y - fp.y) * t * t
				),
			0.0, 1.0, STEP_TIME
		)
	tw.tween_callback(_on_drop_complete.bind(ball, bucket, bet))


func _on_drop_complete(ball: RigidBody2D, bucket: int, bet: float) -> void:
	ball.queue_free()
	board.lit_bucket = bucket
	var mult   := MULTS[bucket]
	var payout := bet * mult
	var net    := payout - bet
	GameState.bankroll += payout
	if net > 0.0:
		GameState.add_fame(TOWN_ID, net)
	_update_hud()

	var mult_str := _fmt_mult(mult)
	if net > 0.0:
		result_lbl.add_theme_color_override("font_color", Color(0.376, 0.973, 0.502, 1))
		result_lbl.text = "%s  +$%s" % [mult_str, _fmt(net)]
	else:
		result_lbl.add_theme_color_override("font_color", Color(0.973, 0.376, 0.376, 1))
		result_lbl.text = "%s  -$%s" % [mult_str, _fmt(-net)]


func _update_hud() -> void:
	balance_lbl.text = "Balance:  $%s" % _fmt(GameState.bankroll)
	fame_lbl.text    = "%s / %s Fame" % [
		_fmt(GameState.town_fame[TOWN_ID]),
		_fmt(GameState.FAME_TARGETS[TOWN_ID])
	]


func _fmt_mult(m: float) -> String:
	if m == float(int(m)):
		return "%dx" % int(m)
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
