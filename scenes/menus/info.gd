extends Control

const MAIN_MENU := "res://scenes/main_menu/MainMenu.tscn"

@onready var _back : Button    = %BackButton
@onready var _fade : ColorRect = $FadeRect


func _ready() -> void:
	_back.pressed.connect(_on_back)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()


func _on_back() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.3)
	tw.tween_callback(func(): get_tree().change_scene_to_file(MAIN_MENU))
