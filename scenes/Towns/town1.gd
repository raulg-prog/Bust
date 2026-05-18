@tool
extends Node2D

const MAP_W   : int = 20
const MAP_H   : int = 18
const TILE_SZ : int = 64
const WORLD_W : int = MAP_W * TILE_SZ   # 1280
const WORLD_H : int = MAP_H * TILE_SZ   # 1152

@onready var ground : TileMapLayer = $Ground


func _ready() -> void:
	_fill_grass()
	if not Engine.is_editor_hint():
		_setup_camera()
		$Buildings/HiLoBuilding/Door.body_entered.connect(_on_hilo_door_entered)
		$Buildings/CoinFlipBuilding/Door.body_entered.connect(_on_coinflip_door_entered)


func _fill_grass() -> void:
	var rng := RandomNumberGenerator.new()
	if Engine.is_editor_hint():
		rng.seed = 12345   # fixed seed — stable view while editing
	else:
		rng.randomize()    # truly random each play
	var variants : Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(1, 1),
	]
	for y in range(MAP_H):
		for x in range(MAP_W):
			ground.set_cell(Vector2i(x, y), 0, variants[rng.randi() % 4])


func _setup_camera() -> void:
	var cam : Camera2D = $Player.get_node("Camera2D")
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
