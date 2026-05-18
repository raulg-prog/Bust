@tool
class_name PlinkoBoard
extends Control

signal ball_landed(ball: Node2D, bucket: int)

const ROWS       : int   = 12
const BUCKETS    : int   = 13
const TOP_Y      : float = 40.0
const ROW_H      : float = 30.0
const BUCKET_TOP : float = 400.0
const BUCKET_H   : float = 50.0
const PEG_R      : float = 6.0

const MULTS : Array[float] = [
	170.0, 24.0, 8.1, 2.0, 0.7, 0.2, 0.2,
	0.2, 0.7, 2.0, 8.1, 24.0, 170.0
]

# Purple gradient — darkest at edges, lightest at centre
const BUCKET_COLORS : Array[Color] = [
	Color(0.627, 0.157, 0.847, 1.0),  # 170x — deep purple
	Color(0.690, 0.220, 0.847, 1.0),  # 24x
	Color(0.753, 0.314, 0.847, 1.0),  # 8.1x
	Color(0.816, 0.408, 0.878, 1.0),  # 2.0x
	Color(0.847, 0.471, 0.878, 1.0),  # 0.7x
	Color(0.878, 0.502, 0.910, 1.0),  # 0.2x
	Color(0.878, 0.533, 0.910, 1.0),  # 0.2x — centre
	Color(0.878, 0.502, 0.910, 1.0),  # 0.2x
	Color(0.847, 0.471, 0.878, 1.0),  # 0.7x
	Color(0.816, 0.408, 0.878, 1.0),  # 2.0x
	Color(0.753, 0.314, 0.847, 1.0),  # 8.1x
	Color(0.690, 0.220, 0.847, 1.0),  # 24x
	Color(0.627, 0.157, 0.847, 1.0),  # 170x — deep purple
]

const PEG_TEX = preload("res://Assets/Plinko/Asset 1 peg.png")

const COL_EDGE := Color(0.000, 0.000, 0.000, 0.600)
const COL_LBL  := Color(0.973, 0.973, 0.973, 1.0)

var lit_bucket : int = -1:
	set(v): lit_bucket = v; queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	await get_tree().process_frame
	_build_peg_colliders()
	_build_landing_zone()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
		if Engine.is_editor_hint() and size.x > 0.0:
			_build_peg_colliders()


func _build_peg_colliders() -> void:
	if size.x <= 0.0:
		return
	var old : Array = []
	for child in get_children():
		if child is StaticBody2D:
			old.append(child)
	for body in old:
		body.free()
	var peg_mat := PhysicsMaterial.new()
	peg_mat.bounce   = 0.12
	peg_mat.friction = 0.05
	for row in range(ROWS):
		for col in range(row + 1):
			var sb   := StaticBody2D.new()
			sb.position = peg_pos(row, col)
			sb.physics_material_override = peg_mat
			var cs   := CollisionShape2D.new()
			var circ := CircleShape2D.new()
			circ.radius = PEG_R
			cs.shape = circ
			sb.add_child(cs)
			add_child(sb)


# Invisible sensor strip at the bucket entry line — fires ball_landed when a ball crosses it.
func _build_landing_zone() -> void:
	var area := Area2D.new()
	area.position = Vector2(size.x * 0.5, BUCKET_TOP + 5.0)
	var cs   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x, 10.0)
	cs.shape  = rect
	area.add_child(cs)
	area.body_entered.connect(_on_landing_body_entered)
	add_child(area)


func _on_landing_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		ball_landed.emit(body, bucket_at(body.position.x))


func bucket_at(x: float) -> int:
	return clamp(int(x / _ps()), 0, BUCKETS - 1)


func _draw() -> void:
	var ps := _ps()
	var pd := PEG_R * 2.0
	for row in range(2, ROWS):
		for col in range(row + 1):
			var pp := peg_pos(row, col)
			draw_texture_rect(PEG_TEX, Rect2(pp - Vector2(PEG_R, PEG_R), Vector2(pd, pd)), false)
	var font := ThemeDB.fallback_font
	for i in range(BUCKETS):
		var bx  := float(i) * ps
		var col : Color = BUCKET_COLORS[i]
		if i == lit_bucket:
			col = col.lightened(0.25)
		draw_rect(Rect2(bx, BUCKET_TOP, ps, BUCKET_H), col)
		draw_rect(Rect2(bx, BUCKET_TOP, ps, BUCKET_H), COL_EDGE, false, 1.0)
		draw_string(font,
				Vector2(bx, BUCKET_TOP + 32.0),
				_fmt_mult(MULTS[i]),
				HORIZONTAL_ALIGNMENT_CENTER, ps, 10, COL_LBL)


func peg_pos(row: int, col: int) -> Vector2:
	var ps := _ps()
	return Vector2(
		size.x * 0.5 + (float(col) - float(row) * 0.5) * ps,
		TOP_Y + float(row) * ROW_H
	)


func bucket_center(idx: int) -> Vector2:
	var ps := _ps()
	return Vector2((float(idx) + 0.5) * ps, BUCKET_TOP + BUCKET_H * 0.5)


func spawn_pos() -> Vector2:
	return Vector2(size.x * 0.5, TOP_Y - ROW_H)


func _ps() -> float:
	return size.x / float(BUCKETS)


func _fmt_mult(m: float) -> String:
	if m == float(int(m)):
		return "%dx" % int(m)
	else:
		return "%.1fx" % m
