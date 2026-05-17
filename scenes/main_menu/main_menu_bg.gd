extends Control

# ── Tile IDs ──────────────────────────────────────────────────────────────────
enum T {
	GRASS, TALL_GRASS, FLOWER,         # ground variants
	TREE, ROCK,                        # sprite overlays (grass drawn first)
	WATER, WATER_EDGE,                 # ocean / pond
	SAND, SAND_EDGE,                   # beach / cliff base
	PATH, PATH_EDGE,                   # gravel paths
	TOWN_FLOOR,                        # bright interior green
	BLDG_ROOF_R,                       # Pokémon-Center orange-red roof
	BLDG_ROOF_P,                       # purple house roof
	BLDG_ROOF_Y,                       # gold / ochre roof
	BLDG_WALL,                         # cream wall with windows
	CLIFF, CLIFF_BASE,                 # upper cliff cap / lower cliff face
}

const TILE_PX : float = 32.0   # 2× native 16 px
const MAP_W   : int   = 128
const MAP_H   : int   = 96

var tex      : Dictionary = {}
var map      : Array      = []
var scroll_x : float      = 400.0
var scroll_y : float      = 200.0
const SPD_X := 14.0
const SPD_Y :=  6.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_textures()
	randomize()
	_generate_map()


# ── Texture setup ─────────────────────────────────────────────────────────────

func _build_textures() -> void:
	const A := "res://Assets/Floor TIles/"
	# Asset-sourced ground tiles
	tex[T.GRASS]      = load(A + "Nature/Grass_16x16.png")
	tex[T.TALL_GRASS] = load(A + "Nature/Grass_Tall_16x16.png")
	tex[T.TREE]       = load(A + "Nature/Tree_Pine_2_16x16.png")
	tex[T.ROCK]       = load(A + "Nature/Rock_big_1_16x16.png")
	tex[T.PATH]       = load(A + "Path Tiles/Path_Gravel_Outer_16x16.png")
	tex[T.PATH_EDGE]  = load(A + "Path Tiles/Path_Gravel_Inner_16x16.png")
	# Programmatically generated tiles (matched to FR/LG reference palette)
	tex[T.FLOWER]      = _gen_flower()
	tex[T.WATER]       = _gen_water()
	tex[T.WATER_EDGE]  = _gen_water_edge()
	tex[T.SAND]        = _gen_sand()
	tex[T.SAND_EDGE]   = _gen_sand_edge()
	tex[T.TOWN_FLOOR]  = _gen_town_floor()
	tex[T.CLIFF]       = _gen_cliff()
	tex[T.CLIFF_BASE]  = _gen_cliff_base()
	tex[T.BLDG_ROOF_R] = _gen_roof(Color(0.93, 0.30, 0.22))   # Pokémon Center red
	tex[T.BLDG_ROOF_P] = _gen_roof(Color(0.58, 0.36, 0.72))   # purple house
	tex[T.BLDG_ROOF_Y] = _gen_roof(Color(0.94, 0.65, 0.14))   # gold / ochre
	tex[T.BLDG_WALL]   = _gen_wall()


# ── Render ────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	scroll_x = fmod(scroll_x + SPD_X * delta, MAP_W * TILE_PX)
	scroll_y = fmod(scroll_y + SPD_Y * delta, MAP_H * TILE_PX)
	queue_redraw()


func _draw() -> void:
	var cols : int   = int(size.x / TILE_PX) + 2
	var rows : int   = int(size.y / TILE_PX) + 2
	var ox   : float = fmod(scroll_x, TILE_PX)
	var oy   : float = fmod(scroll_y, TILE_PX)
	var btx  : int   = int(scroll_x / TILE_PX) % MAP_W
	var bty  : int   = int(scroll_y / TILE_PX) % MAP_H
	for r in rows:
		for c in cols:
			var tx : int   = (btx + c) % MAP_W
			var ty : int   = (bty + r) % MAP_H
			var t  : int   = map[ty][tx]
			var px : float = c * TILE_PX - ox
			var py : float = r * TILE_PX - oy
			var dr := Rect2(px, py, TILE_PX, TILE_PX)
			# Sprites with transparent regions need a ground drawn beneath them
			if t == T.TREE or t == T.ROCK:
				draw_texture_rect(tex[T.GRASS], dr, false)
			draw_texture_rect(tex[t], dr, false)


# ── Programmatic tile generators (FR/LG palette) ──────────────────────────────

func _img() -> Image:
	return Image.create(16, 16, false, Image.FORMAT_RGBA8)


func _gen_water() -> ImageTexture:
	# Bright Pokémon ocean: deep blue base, two lighter diagonal wave bands, white foam
	var img   := _img()
	var deep  := Color(0.20, 0.44, 0.86)   # #3371DB
	var mid   := Color(0.36, 0.60, 0.93)   # #5C99ED
	var light := Color(0.62, 0.79, 0.97)   # #9EC9F7
	var foam  := Color(0.88, 0.94, 0.99)   # #E0F0FD
	for y in 16:
		for x in 16:
			var p := (x + y * 2) % 10
			img.set_pixel(x, y,
				foam  if p == 0 else
				light if p <= 2 else
				mid   if p <= 4 else
				deep)
	return ImageTexture.create_from_image(img)


func _gen_water_edge() -> ImageTexture:
	# Grass fading into ocean — matches the FR/LG shoreline look
	var img   := _img()
	var grass := Color(0.44, 0.74, 0.26)
	var shore := Color(0.50, 0.62, 0.34)   # olive transition
	var deep  := Color(0.20, 0.44, 0.86)
	var mid   := Color(0.36, 0.60, 0.93)
	var foam  := Color(0.88, 0.94, 0.99)
	for y in 16:
		for x in 16:
			if y < 3:
				img.set_pixel(x, y, grass)
			elif y < 5:
				img.set_pixel(x, y, shore)
			else:
				var p := (x + y * 2) % 10
				img.set_pixel(x, y, foam if p == 0 else (mid if p <= 4 else deep))
	return ImageTexture.create_from_image(img)


func _gen_sand() -> ImageTexture:
	# Warm sandy beach — the tan/beige of FR/LG coastal areas
	var img  := _img()
	var base := Color(0.80, 0.68, 0.40)   # #CCB066
	var dark := Color(0.72, 0.59, 0.33)   # small pebble specks
	var hi   := Color(0.88, 0.76, 0.50)   # highlight
	for y in 16:
		for x in 16:
			var p := (x * 7 + y * 3) % 17
			img.set_pixel(x, y,
				dark if p == 0 else
				hi   if p == 1 else
				base)
	return ImageTexture.create_from_image(img)


func _gen_sand_edge() -> ImageTexture:
	# Cliff base meets sand — darker, with small rock fragments
	var img   := _img()
	var cliff := Color(0.65, 0.48, 0.26)
	var sand  := Color(0.80, 0.68, 0.40)
	var dark  := Color(0.48, 0.34, 0.16)
	for y in 16:
		for x in 16:
			if y < 5:
				img.set_pixel(x, y, cliff if (x + y) % 3 != 0 else dark)
			elif y < 8:
				img.set_pixel(x, y, dark if (x * 3 + y) % 7 == 0 else cliff)
			else:
				img.set_pixel(x, y, sand)
	return ImageTexture.create_from_image(img)


func _gen_cliff() -> ImageTexture:
	# Upper cliff cap — warm layered tan/brown matching FR/LG mountain borders
	var img  := _img()
	var top  := Color(0.74, 0.57, 0.33)   # #BC9254  light tan cap
	var face := Color(0.65, 0.47, 0.25)   # #A67840  main face
	var dark := Color(0.47, 0.32, 0.15)   # #785026  shadow recesses
	var hi   := Color(0.82, 0.66, 0.42)   # #D0A86B  highlight edge
	for y in 16:
		for x in 16:
			if y < 2:
				img.set_pixel(x, y, hi)
			elif y < 5:
				# Top cap — alternating light/dark to suggest rock texture
				img.set_pixel(x, y, dark if (x + y) % 4 == 0 else top)
			elif y > 13:
				img.set_pixel(x, y, dark)
			else:
				var p := (x * 5 + y * 3) % 11
				img.set_pixel(x, y,
					hi   if p < 2 else
					dark if p < 4 else
					face if p < 8 else
					top)
	return ImageTexture.create_from_image(img)


func _gen_cliff_base() -> ImageTexture:
	# Lower cliff face — darker brown, heavy shadow at bottom
	var img  := _img()
	var face := Color(0.58, 0.40, 0.20)
	var dark := Color(0.40, 0.26, 0.10)
	var hi   := Color(0.68, 0.50, 0.28)
	for y in 16:
		for x in 16:
			if y > 12:
				img.set_pixel(x, y, dark)
			else:
				var p := (x * 3 + y * 7) % 9
				img.set_pixel(x, y,
					hi   if p < 2 else
					dark if p < 4 else
					face)
	return ImageTexture.create_from_image(img)


func _gen_town_floor() -> ImageTexture:
	# FR/LG interior town ground — bright teal-green with faint grid lines
	var img  := _img()
	var base := Color(0.47, 0.79, 0.47)   # #78C978  the iconic town colour
	var line := Color(0.41, 0.71, 0.41)   # subtle tile grid
	for y in 16:
		for x in 16:
			img.set_pixel(x, y, line if (x == 0 or y == 0) else base)
	return ImageTexture.create_from_image(img)


func _gen_flower() -> ImageTexture:
	# Grass tile with red flowers — scattered throughout FR/LG maps
	var img   := _img()
	var grass := Color(0.44, 0.74, 0.26)
	var dark  := Color(0.35, 0.59, 0.19)   # grass speck
	var red   := Color(0.92, 0.22, 0.18)   # #EB3830 flower
	var yell  := Color(0.98, 0.86, 0.22)   # yellow centre
	var stem  := Color(0.32, 0.56, 0.17)
	img.fill(grass)
	# Grass speckle base
	for y in 16:
		for x in 16:
			if (x * 5 + y * 7) % 13 == 0:
				img.set_pixel(x, y, dark)
	# Three red flowers with yellow centres
	for pos in [Vector2i(3, 4), Vector2i(10, 3), Vector2i(7, 11)]:
		img.set_pixel(pos.x, pos.y - 1, stem)
		# 3×3 petals
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var fx : int = pos.x + dx
				var fy : int = pos.y + dy
				if fx >= 0 and fx < 16 and fy >= 0 and fy < 16:
					img.set_pixel(fx, fy, red if (dx != 0 or dy != 0) else yell)
	return ImageTexture.create_from_image(img)


func _gen_roof(c: Color) -> ImageTexture:
	# Pokémon-style roof tile with highlight ridge and shadow edge
	var img  := _img()
	var hi   := c.lightened(0.22)
	var shad := c.darkened(0.38)
	for y in 16:
		for x in 16:
			if y == 0:
				img.set_pixel(x, y, hi)
			elif y == 1 or y == 2:
				img.set_pixel(x, y, hi if x % 4 < 2 else c)
			elif y >= 14:
				img.set_pixel(x, y, shad)
			else:
				img.set_pixel(x, y, c)
	# Central ridge
	for y in range(1, 14):
		img.set_pixel(8, y, hi)
	return ImageTexture.create_from_image(img)


func _gen_wall() -> ImageTexture:
	# Cream building wall, two blue-framed windows, shadow at base
	var img   := _img()
	var wall  := Color(0.95, 0.93, 0.86)   # #F2EDB8  cream
	var win   := Color(0.53, 0.72, 0.88)   # #87B8E0  window glass
	var frame := Color(0.48, 0.44, 0.36)   # #7A7058  window frame
	var shad  := Color(0.76, 0.73, 0.63)   # base shadow
	img.fill(wall)
	for x in 16:
		img.set_pixel(x, 14, shad)
		img.set_pixel(x, 15, shad)
	# Left window
	for y in range(2, 10):
		for x in range(1, 7):
			img.set_pixel(x, y,
				frame if (y == 2 or y == 9 or x == 1 or x == 6) else win)
	# Right window
	for y in range(2, 10):
		for x in range(9, 15):
			img.set_pixel(x, y,
				frame if (y == 2 or y == 9 or x == 9 or x == 14) else win)
	return ImageTexture.create_from_image(img)


# ── Map generation ─────────────────────────────────────────────────────────────

func _generate_map() -> void:
	map.clear()
	for y in MAP_H:
		var row : Array[int] = []
		for x in MAP_W:
			var r := randf()
			row.append(
				T.TALL_GRASS if r < 0.12 else
				T.FLOWER     if r < 0.20 else
				T.GRASS)
		map.append(row)

	# Two-layer cliff border: cap on outside, base just inside
	for y in MAP_H:
		for x in MAP_W:
			var d := mini(mini(x, MAP_W - 1 - x), mini(y, MAP_H - 1 - y))
			if d < 2:
				map[y][x] = T.CLIFF_BASE
			elif d < 4:
				map[y][x] = T.CLIFF

	# Sandy beach ring just inside the cliffs (2 tiles)
	for y in MAP_H:
		for x in MAP_W:
			var d := mini(mini(x, MAP_W - 1 - x), mini(y, MAP_H - 1 - y))
			if d == 4:
				map[y][x] = T.SAND_EDGE
			elif d == 5:
				map[y][x] = T.SAND

	# Dense forest clusters
	for _i in 18:
		_forest(randi_range(8, MAP_W - 9), randi_range(8, MAP_H - 9), randi_range(4, 10))

	# Towns with teal floors and coloured buildings
	_town(12,  9, 24, 20)
	_town(80,  7, 22, 17)
	_town(44, 58, 28, 20)
	_town(95, 62, 20, 16)
	_town(20, 72, 20, 14)

	# Connecting gravel paths
	_path_h(32,  7, MAP_W - 8, 2)
	_path_h(64,  7, MAP_W - 8, 2)
	_path_v(54,  7, MAP_H - 8, 2)
	_path_v(38,  7, MAP_H - 8, 2)
	_path_v(90,  7, MAP_H - 8, 2)

	# Water features (ponds and small lakes — blue pops against green)
	_pond(28, 22, 10, 7)
	_pond(56, 14, 7, 5)
	_pond(98, 28, 11, 8)
	_pond(18, 50, 9, 6)
	_pond(70, 40, 14, 10)
	_pond(42, 78, 8, 6)

	# Scattered rocks on open grass / flowers
	for _i in 28:
		var rx := randi_range(7, MAP_W - 8)
		var ry := randi_range(7, MAP_H - 8)
		if _is_open(map[ry][rx]):
			map[ry][rx] = T.ROCK


func _forest(cx: int, cy: int, rad: int) -> void:
	for y in range(cy - rad, cy + rad + 1):
		for x in range(cx - rad, cx + rad + 1):
			if not _in(x, y) or x < 6 or x >= MAP_W - 6 or y < 6 or y >= MAP_H - 6:
				continue
			var d := sqrt(float((x - cx) * (x - cx) + (y - cy) * (y - cy)))
			if d < float(rad) * randf_range(0.65, 1.0):
				map[y][x] = T.TREE


func _town(tx: int, ty: int, tw: int, th: int) -> void:
	for y in range(ty, ty + th):
		for x in range(tx, tx + tw):
			if _in(x, y): map[y][x] = T.TOWN_FLOOR

	var my := ty + th / 2
	for x in range(tx, tx + tw):
		if _in(x, my):     map[my][x]     = T.PATH
		if _in(x, my + 1): map[my + 1][x] = T.PATH

	var roofs := [T.BLDG_ROOF_R, T.BLDG_ROOF_P, T.BLDG_ROOF_Y]
	for by in [ty + 1, ty + th - 4]:
		var bx := tx + 1
		var ri := randi_range(0, 2)
		while bx <= tx + tw - 6:
			if _in(bx + 4, by + 2):
				for rx in range(bx, bx + 5):
					if _in(rx, by): map[by][rx] = roofs[ri % 3]
				for wy in range(by + 1, by + 3):
					for wx in range(bx, bx + 5):
						if _in(wx, wy): map[wy][wx] = T.BLDG_WALL
			bx += 7
			ri  += 1

	for x in range(tx - 1, tx + tw + 1):
		if _in(x, ty - 1):     map[ty - 1][x]     = T.PATH_EDGE
		if _in(x, ty + th):    map[ty + th][x]     = T.PATH_EDGE
	for y in range(ty, ty + th):
		if _in(tx - 1, y):     map[y][tx - 1]      = T.PATH_EDGE
		if _in(tx + tw, y):    map[y][tx + tw]      = T.PATH_EDGE


func _pond(wx: int, wy: int, ww: int, wh: int) -> void:
	for y in range(wy, wy + wh):
		for x in range(wx, wx + ww):
			if not _in(x, y): continue
			var edge := (x == wx or x == wx + ww - 1 or y == wy or y == wy + wh - 1)
			map[y][x] = T.WATER_EDGE if edge else T.WATER


func _path_h(row: int, x1: int, x2: int, thick: int) -> void:
	for t in range(-thick, thick + 1):
		var ry := row + t
		if ry < 0 or ry >= MAP_H: continue
		for x in range(x1, x2):
			if _in(x, ry) and _passable(map[ry][x]):
				map[ry][x] = T.PATH if t == 0 else T.PATH_EDGE


func _path_v(col: int, y1: int, y2: int, thick: int) -> void:
	for t in range(-thick, thick + 1):
		var cx := col + t
		if cx < 0 or cx >= MAP_W: continue
		for y in range(y1, y2):
			if _in(cx, y) and _passable(map[y][cx]):
				map[y][cx] = T.PATH if t == 0 else T.PATH_EDGE


func _in(x: int, y: int) -> bool:
	return x >= 0 and x < MAP_W and y >= 0 and y < MAP_H


func _passable(t: int) -> bool:
	return t == T.GRASS or t == T.TALL_GRASS or t == T.FLOWER or t == T.ROCK


func _is_open(t: int) -> bool:
	return t == T.GRASS or t == T.TALL_GRASS or t == T.FLOWER
