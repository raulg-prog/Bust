extends Node2D

const TOWN_NAME   := "Cascade"
const TOWN_ID     := 1
const TOWN1_SCENE := "res://scenes/Towns/Town1.tscn"

# GBA colours
const COL_GOLD   := Color(0.973, 0.847, 0.188, 1)
const COL_GREEN  := Color(0.376, 0.973, 0.502, 1)
const COL_RED    := Color(0.973, 0.376, 0.376, 1)
const COL_BLUE   := Color(0.502, 0.753, 0.973, 1)
const COL_YELLOW := Color(0.973, 0.973, 0.439, 1)
const COL_PANEL  := Color(0.063, 0.031, 0.125, 0.90)
const COL_BORDER := Color(0.314, 0.220, 0.565, 1)

var _hud          : CanvasLayer
var _bankroll_lbl : Label
var _fame_fill    : Panel
var _fade_rect    : ColorRect
var _pause_panel  : Panel
var _pause_br_lbl : Label
var _paused       : bool = false
var _fading       : bool = false


func _ready() -> void:
	_wire_doors()
	_build_hud()
	_fade_in()
	if GameState.ensure_minimum():
		_show_centre_popup("Safety net: $100 added!", COL_YELLOW, 2.5)
	if GameState.last_fame_earned > 0.0:
		var earned := GameState.last_fame_earned
		GameState.last_fame_earned = 0.0
		_show_centre_popup("+" + _fmt(earned) + " Fame  *", COL_BLUE, 2.2)


func _wire_doors() -> void:
	var wheel_door := find_child("WheelDoor", true, false)
	if wheel_door:
		wheel_door.body_entered.connect(_on_wheel_door_entered)

	var plinko_door := find_child("PlinkoDoor", true, false)
	if plinko_door:
		plinko_door.body_entered.connect(_on_plinko_door_entered)

	var town1_exit := find_child("Town1Exit", true, false)
	if town1_exit:
		town1_exit.body_entered.connect(_on_town1_exit_entered)


# ─── HUD BUILDER ─────────────────────────────────────────────────────────────

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hud)
	_build_info_panel()
	_build_fade_rect()
	_build_pause_panel()
	_show_town_name_card()


func _make_stylebox(bg: Color, border: Color = COL_BORDER, bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color            = bg
	sb.border_color        = border
	sb.border_width_left   = bw
	sb.border_width_right  = bw
	sb.border_width_top    = bw
	sb.border_width_bottom = bw
	return sb


func _build_info_panel() -> void:
	var panel := Panel.new()
	panel.size     = Vector2(224, 76)
	panel.position = Vector2(12, 12)
	panel.add_theme_stylebox_override("panel", _make_stylebox(COL_PANEL))
	_hud.add_child(panel)

	var town_lbl := Label.new()
	town_lbl.text     = TOWN_NAME
	town_lbl.position = Vector2(10, 6)
	town_lbl.add_theme_font_size_override("font_size", 14)
	town_lbl.add_theme_color_override("font_color", COL_GOLD)
	panel.add_child(town_lbl)

	_bankroll_lbl          = Label.new()
	_bankroll_lbl.position = Vector2(10, 26)
	_bankroll_lbl.add_theme_font_size_override("font_size", 14)
	_bankroll_lbl.add_theme_color_override("font_color", COL_GREEN)
	panel.add_child(_bankroll_lbl)

	var fame_caption := Label.new()
	fame_caption.text     = "FAME"
	fame_caption.position = Vector2(10, 52)
	fame_caption.add_theme_font_size_override("font_size", 10)
	fame_caption.add_theme_color_override("font_color", COL_BLUE)
	panel.add_child(fame_caption)

	var bar_bg := Panel.new()
	bar_bg.position = Vector2(48, 55)
	bar_bg.size     = Vector2(164, 10)
	bar_bg.add_theme_stylebox_override("panel", _make_stylebox(
		Color(0.094, 0.094, 0.157, 1), Color(0.2, 0.2, 0.35, 1), 1))
	panel.add_child(bar_bg)

	_fame_fill          = Panel.new()
	_fame_fill.position = Vector2(0, 0)
	_fame_fill.size     = Vector2(0, 10)
	_fame_fill.add_theme_stylebox_override("panel", _make_stylebox(COL_BLUE, COL_BLUE, 0))
	bar_bg.add_child(_fame_fill)


func _build_fade_rect() -> void:
	_fade_rect              = ColorRect.new()
	_fade_rect.color        = Color(0, 0, 0, 1)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.add_child(_fade_rect)


func _build_pause_panel() -> void:
	_pause_panel          = Panel.new()
	_pause_panel.size     = Vector2(280, 210)
	_pause_panel.position = Vector2(640 - 140, 360 - 105)
	_pause_panel.visible  = false
	_pause_panel.add_theme_stylebox_override("panel",
		_make_stylebox(Color(0.047, 0.024, 0.094, 0.96)))
	_hud.add_child(_pause_panel)

	var title := Label.new()
	title.text                 = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size                 = Vector2(280, 40)
	title.position             = Vector2(0, 16)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", COL_GOLD)
	_pause_panel.add_child(title)

	_pause_br_lbl                      = Label.new()
	_pause_br_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_br_lbl.size                 = Vector2(280, 28)
	_pause_br_lbl.position             = Vector2(0, 62)
	_pause_br_lbl.add_theme_font_size_override("font_size", 13)
	_pause_br_lbl.add_theme_color_override("font_color", COL_GREEN)
	_pause_panel.add_child(_pause_br_lbl)

	var fame_lbl := Label.new()
	fame_lbl.name                 = "PauseFame"
	fame_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fame_lbl.size                 = Vector2(280, 24)
	fame_lbl.position             = Vector2(0, 88)
	fame_lbl.add_theme_font_size_override("font_size", 11)
	fame_lbl.add_theme_color_override("font_color", COL_BLUE)
	_pause_panel.add_child(fame_lbl)

	_add_pause_btn("Resume",       Vector2(40, 122), _toggle_pause)
	_add_pause_btn("Quit to Menu", Vector2(40, 164),
		func(): _fade_out_to("res://scenes/main_menu/MainMenu.tscn"))


func _add_pause_btn(txt: String, pos: Vector2, cb: Callable) -> void:
	var btn     := Button.new()
	btn.text     = txt
	btn.size     = Vector2(200, 34)
	btn.position = pos
	btn.pressed.connect(cb)
	_pause_panel.add_child(btn)


func _show_town_name_card() -> void:
	var card := Label.new()
	card.text                 = TOWN_NAME
	card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.size                 = Vector2(300, 52)
	card.position             = Vector2(640 - 150, 56)
	card.modulate.a           = 0.0
	card.add_theme_font_size_override("font_size", 38)
	card.add_theme_color_override("font_color", COL_GOLD)
	_hud.add_child(card)

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(card, "modulate:a", 1.0, 0.5)
	tw.tween_interval(1.6)
	tw.tween_property(card, "modulate:a", 0.0, 0.7)
	tw.tween_callback(card.queue_free)


func _show_centre_popup(text: String, colour: Color, duration: float) -> void:
	var lbl := Label.new()
	lbl.text                 = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size                 = Vector2(380, 40)
	lbl.position             = Vector2(640 - 190, 120)
	lbl.modulate.a           = 0.0
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", colour)
	_hud.add_child(lbl)

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.35)
	tw.tween_interval(duration)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)


# ─── TRANSITIONS ─────────────────────────────────────────────────────────────

func _fade_in() -> void:
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade_rect, "color:a", 0.0, 0.4)


func _fade_out_to(scene_path: String) -> void:
	if _fading:
		return
	_fading = true
	if _paused:
		get_tree().paused = false
		_paused           = false
		_pause_panel.visible = false
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade_rect, "color:a", 1.0, 0.3)
	tw.tween_callback(func(): get_tree().call_deferred("change_scene_to_file", scene_path))


# ─── PAUSE ───────────────────────────────────────────────────────────────────

func _toggle_pause() -> void:
	if _fading:
		return
	_paused           = !_paused
	get_tree().paused = _paused
	_pause_panel.visible = _paused
	if _paused:
		_pause_br_lbl.text = "Bankroll:  $" + _fmt(GameState.bankroll)
		var fl := _pause_panel.find_child("PauseFame") as Label
		if fl:
			var fame   := GameState.town_fame[TOWN_ID]
			var target := GameState.FAME_TARGETS[TOWN_ID]
			fl.text = "Fame:  %s / %s" % [_fmt(fame), _fmt(target)]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo and event.is_action_pressed("ui_cancel"):
		_toggle_pause()


# ─── PROCESS ─────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if _fading:
		return
	_update_hud()


func _update_hud() -> void:
	if _bankroll_lbl:
		var br := GameState.bankroll
		_bankroll_lbl.text = "$" + _fmt(br)
		var col := COL_RED if br < 200.0 else COL_GREEN
		_bankroll_lbl.add_theme_color_override("font_color", col)
	if _fame_fill:
		var progress : float = clamp(
			GameState.town_fame[TOWN_ID] / GameState.FAME_TARGETS[TOWN_ID], 0.0, 1.0)
		_fame_fill.size.x = 164.0 * progress


# ─── DOORS ───────────────────────────────────────────────────────────────────

func _on_wheel_door_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_fade_out_to("res://scenes/games/wheel/Wheel.tscn")


func _on_plinko_door_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_fade_out_to("res://scenes/games/plinko/Plinko.tscn")


func _on_town1_exit_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_fade_out_to(TOWN1_SCENE)


# ─── HELPERS ─────────────────────────────────────────────────────────────────

func _fmt(val: float) -> String:
	if val >= 1_000_000.0:
		return "%.1fM" % (val / 1_000_000.0)
	if val >= 1_000.0:
		return "%.1fK" % (val / 1_000.0)
	return str(int(val))
