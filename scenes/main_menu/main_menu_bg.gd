extends Control

const TOWN_SCENE := preload("res://scenes/Towns/Town1.tscn")
const ZOOM       := Vector2(2.5, 2.5)
const PAN_SPEED  := Vector2(35.0, 14.0)   # world-px per second

# At zoom=2.5 a 1280×720 viewport shows 512×288 of the 1280×640 world.
# Camera centre must stay inside these bounds to never show void.
const CAM_MIN := Vector2(256.0, 144.0)
const CAM_MAX := Vector2(1024.0, 496.0)

var _cam : Camera2D
var _vel : Vector2 = PAN_SPEED


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# SubViewportContainer fills the Control and stretches the viewport to fit
	var svc := SubViewportContainer.new()
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.stretch      = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)

	var vp := SubViewport.new()
	vp.handle_input_locally = false
	vp.size = Vector2i(1280, 720)
	svc.add_child(vp)

	# Instance Town1 — this triggers town1.gd _ready() immediately
	var town := TOWN_SCENE.instantiate()
	vp.add_child(town)

	# Disable the player and explicitly kill its Camera2D so it can't stay current
	var player := town.find_child("Player", true, false)
	if player:
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.visible      = false
		var player_cam := player.find_child("Camera2D", true, false) as Camera2D
		if player_cam:
			player_cam.enabled = false

	# Hide the HUD that town1.gd builds (title card, fame bar, fade rect)
	for child in town.get_children():
		if child is CanvasLayer:
			child.visible = false

	# Our panning camera — make_current() forces it to take over the viewport
	_cam          = Camera2D.new()
	_cam.zoom     = ZOOM
	_cam.position = Vector2(256.0, 144.0)   # start top-left of visible range
	vp.add_child(_cam)
	_cam.make_current()


func _process(delta: float) -> void:
	var p := _cam.position + _vel * delta
	if p.x < CAM_MIN.x or p.x > CAM_MAX.x:
		_vel.x = -_vel.x
		p.x    = clamp(p.x, CAM_MIN.x, CAM_MAX.x)
	if p.y < CAM_MIN.y or p.y > CAM_MAX.y:
		_vel.y = -_vel.y
		p.y    = clamp(p.y, CAM_MIN.y, CAM_MAX.y)
	_cam.position = p
