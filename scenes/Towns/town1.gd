@tool
extends Node2D

const MAP_W   : int = 20
const MAP_H   : int = 18
const TILE_SZ : int = 64
const WORLD_W : int = MAP_W * TILE_SZ   # 1280
const WORLD_H : int = MAP_H * TILE_SZ   # 1152

@onready var ground : TileMapLayer = $Ground
@onready var decor  : TileMapLayer = $Decor

const SRC_SIDEWALK := 1
const SRC_ROAD     := 2


func _ready() -> void:
	_fill_grass()
	_fill_roads()
	if not Engine.is_editor_hint():
		_setup_camera()
		$Buildings/HiLoBuild/HiLoBuilding/Door.body_entered.connect(_on_hilo_door_entered)
		$Buildings/CoinFlipBuild/CoinFlipBuilding/Door.body_entered.connect(_on_coinflip_door_entered)


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


func _fill_roads() -> void:
	var sw := Vector2i(0, 0)
	var rd := Vector2i(0, 0)

	# Main horizontal road — rows 9-10 (player spawns at row 9)
	for x in range(MAP_W):
		decor.set_cell(Vector2i(x, 9),  SRC_ROAD, rd)
		decor.set_cell(Vector2i(x, 10), SRC_ROAD, rd)

	# Sidewalks bordering the road
	for x in range(MAP_W):
		decor.set_cell(Vector2i(x, 8),  SRC_SIDEWALK, sw)
		decor.set_cell(Vector2i(x, 11), SRC_SIDEWALK, sw)

	# Sidewalk path up to HiLo building (centre col ~4, rows 4–8)
	for y in range(4, 9):
		for x in range(3, 6):
			decor.set_cell(Vector2i(x, y), SRC_SIDEWALK, sw)

	# Sidewalk path up to CoinFlip building (centre col ~15, rows 6–8)
	for y in range(6, 9):
		for x in range(14, 17):
			decor.set_cell(Vector2i(x, y), SRC_SIDEWALK, sw)


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
