extends Control

@onready var _video : VideoStreamPlayer = $VideoPlayer
@onready var _label : Label             = $ClickLabel
@onready var _fade  : ColorRect         = $FadeRect

var _leaving : bool = false


func _ready() -> void:
	# Fade in from black
	var tw_in := create_tween()
	tw_in.tween_property(_fade, "color:a", 0.0, 0.5)

	_video.play()
	_video.finished.connect(_go_to_menu)

	# Label appears after 2 seconds
	var tw_lbl := create_tween()
	tw_lbl.tween_interval(2.0)
	tw_lbl.tween_property(_label, "modulate:a", 1.0, 0.6)


func _input(event: InputEvent) -> void:
	if _leaving:
		return
	var clicked : bool = event is InputEventMouseButton and event.pressed
	var keyed   : bool = event is InputEventKey and event.pressed and not event.echo
	if clicked or keyed:
		_go_to_menu()


func _go_to_menu() -> void:
	if _leaving:
		return
	_leaving = true
	_video.stop()
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.4)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn"))
