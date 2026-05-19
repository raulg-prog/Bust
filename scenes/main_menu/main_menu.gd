extends Control

@onready var new_game_btn : Button = %NewGameButton
@onready var quit_btn     : Button = %QuitButton


func _ready() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	quit_btn.pressed.connect(_on_quit)


func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/Towns/Town1.tscn")


func _on_quit() -> void:
	get_tree().quit()
