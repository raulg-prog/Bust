extends Control

@onready var _play_btn : Button = %PlayButton
@onready var _exit_btn : Button = %ExitButton


func _ready() -> void:
	_play_btn.pressed.connect(_on_play)
	_exit_btn.pressed.connect(_on_exit)
	_wire_hover(_play_btn)
	_wire_hover(_exit_btn)


func _wire_hover(btn: Button) -> void:
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.15)
	)
	btn.mouse_exited.connect(func():
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
	)


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/Towns/Town1.tscn")


func _on_exit() -> void:
	get_tree().quit()
