extends Control

const TOWN1   := "res://scenes/Towns/Town1.tscn"
const INFO    := "res://scenes/menus/Info.tscn"
const OPTIONS := "res://scenes/menus/Options.tscn"

@onready var _play_btn    : Button      = %PlayButton
@onready var _info_btn    : Button      = %InfoButton
@onready var _options_btn : Button      = %OptionsButton
@onready var _exit_btn    : Button      = %ExitButton
@onready var _logo        : TextureRect = $Logo
@onready var _confirm     : Control     = %ConfirmGroup
@onready var _yes_btn     : Button      = %YesButton
@onready var _no_btn      : Button      = %NoButton
@onready var _fade        : ColorRect        = $FadeRect
@onready var _music       : AudioStreamPlayer = %MusicPlayer

const MUSIC_VOL_DB  : float = -9.6   # ~50% amplitude, then another 30% quieter
const FADE_OUT_TIME : float = 2.5    # seconds before end to begin fade out
const FADE_IN_TIME  : float = 1.5    # fade in duration on loop restart

var _leaving     : bool = false
var _confirming  : bool = false
var _fading_out  : bool = false
var _menu_btns   : Array[Button]  = []
var _btn_home    : Array[Vector2] = []


func _ready() -> void:
	_play_btn.pressed.connect(func(): _go_to(TOWN1, true))
	_info_btn.pressed.connect(func(): _go_to(INFO))
	_options_btn.pressed.connect(func(): _go_to(OPTIONS))
	_exit_btn.pressed.connect(_on_exit)
	_yes_btn.pressed.connect(_on_yes)
	_no_btn.pressed.connect(_on_no)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.5)
	await get_tree().process_frame
	_menu_btns = [_play_btn, _info_btn, _options_btn, _exit_btn]
	for b in _menu_btns:
		_btn_home.append(b.position)
		_wire_hover(b)
	_wire_grow(_yes_btn)
	_wire_grow(_no_btn)
	_music.finished.connect(_on_music_finished)
	_start_music()


func _wire_hover(btn: Button) -> void:
	var rest_x : float = btn.position.x
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		var tw := create_tween().set_parallel(true) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(btn, "scale",      Vector2(1.12, 1.12), 0.15)
		tw.tween_property(btn, "position:x", rest_x + 35.0,       0.30)
	)
	btn.mouse_exited.connect(func():
		var tw := create_tween().set_parallel(true) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(btn, "scale",      Vector2(1.0, 1.0), 0.12)
		tw.tween_property(btn, "position:x", rest_x,            0.25)
	)


func _wire_grow(btn: Button) -> void:
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15)
	)
	btn.mouse_exited.connect(func():
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
	)


func _go_to(scene_path: String, zoom: bool = false) -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_fade, "color:a", 1.0, 0.5)
	if zoom:
		pivot_offset = size / 2.0
		tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.5) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(func(): get_tree().change_scene_to_file(scene_path))


func _on_exit() -> void:
	if _leaving or _confirming:
		return
	_confirming = true
	for b in _menu_btns:
		b.disabled = true
	var tw := create_tween().set_parallel(true) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_logo, "modulate:a", 0.0, 0.3)
	for i in _menu_btns.size():
		var b := _menu_btns[i]
		tw.tween_property(b, "position:y", _btn_home[i].y + 280.0, 0.45)
		tw.tween_property(b, "modulate:a", 0.0, 0.40)
	await tw.finished
	_confirm.visible = true
	var tw2 := create_tween()
	tw2.tween_property(_confirm, "modulate:a", 1.0, 0.3)


func _on_no() -> void:
	if _leaving:
		return
	var tw := create_tween()
	tw.tween_property(_confirm, "modulate:a", 0.0, 0.2)
	await tw.finished
	_confirm.visible = false
	var tw2 := create_tween().set_parallel(true) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw2.tween_property(_logo, "modulate:a", 1.0, 0.3)
	for i in _menu_btns.size():
		var b := _menu_btns[i]
		tw2.tween_property(b, "position:y", _btn_home[i].y, 0.45)
		tw2.tween_property(b, "modulate:a", 1.0, 0.40)
	await tw2.finished
	for b in _menu_btns:
		b.disabled = false
	_confirming = false


func _on_yes() -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.4)
	tw.tween_callback(func(): get_tree().quit())


# ── Music ─────────────────────────────────────────────────────────────────────

func _start_music() -> void:
	_fading_out = false
	_music.volume_db = -80.0
	_music.play()
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", MUSIC_VOL_DB, FADE_IN_TIME)


func _process(_delta: float) -> void:
	if not _music.playing or _fading_out:
		return
	var remaining := _music.stream.get_length() - _music.get_playback_position()
	if remaining <= FADE_OUT_TIME:
		_fading_out = true
		var tw := create_tween()
		tw.tween_property(_music, "volume_db", -80.0, remaining)


func _on_music_finished() -> void:
	_start_music()
