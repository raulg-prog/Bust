@tool
extends Node2D

const MAP_W   : int = 40
const MAP_H   : int = 36
const TILE_SZ : int = 32
const WORLD_W : int = MAP_W * TILE_SZ   # 1280
const WORLD_H : int = MAP_H * TILE_SZ   # 1152


func _ready() -> void:
	if not Engine.is_editor_hint():
		_setup_camera()
		var hilo_door := find_child("HiLoBuilding", true, false)
		if hilo_door:
			hilo_door.get_node("Door").body_entered.connect(_on_hilo_door_entered)
		var coinflip_door := find_child("CoinFlipBuilding", true, false)
		if coinflip_door:
			coinflip_door.get_node("Door").body_entered.connect(_on_coinflip_door_entered)


func _setup_camera() -> void:
	var cam := find_child("Camera2D", true, false) as Camera2D
	if cam:
		cam.limit_left   = 0
		cam.limit_top    = 0
		cam.limit_right  = WORLD_W
		cam.limit_bottom = WORLD_H


func _on_hilo_door_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/games/hilo/HiLo.tscn")


func _on_coinflip_door_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/games/coinflip/CoinFlip.tscn")
