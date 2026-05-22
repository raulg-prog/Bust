extends Control

const COLS         := 8
const ROWS         := 8
const NSYMS        := 7
const CELL_SIZE    := 64
const MIN_CLUSTER  := 5
const MIN_BET      := 10.0
const TOWN_ID      := 4
const METER_MAX    := 114

# Paytable: [symbol_tier 0=lowest..6=highest][size_bucket 0..8]
# Size buckets: 5, 6, 7, 8, 9-11, 12-14, 15-19, 20-24, 25+
# Values derived from Gems Bonanza official paytable at $100 bet (÷100)
# Paytable scaled to 98% RTP (cumulative ×3.758, verified via 500k-spin Monte Carlo ×2)
const PAYTABLE : Array = [
	[0.38,  0.57,  0.76,  1.31,  3.76,  7.52,  14.09,  37.6,  188.0],  # 0 Aquamarine
	[0.57,  0.76,  1.12,  1.88,  5.64,  9.40,  18.80,  56.4,  281.8],  # 1 Amethyst
	[0.76,  0.93,  1.50,  2.26,  7.52, 14.09,  28.18,  75.2,  375.7],  # 2 Topaz
	[0.93,  1.12,  1.50,  2.81,  9.40, 18.80,  37.58,  94.0,  563.8],  # 3 Sapphire
	[1.12,  1.88,  2.81,  4.69, 14.09, 28.18,  56.38, 188.0, 1127.6],  # 4 Emerald
	[1.88,  2.81,  4.69,  9.40, 28.18, 46.97,  93.96, 375.7, 1879.7],  # 5 Ruby
	[3.76,  5.64,  9.40, 18.80, 46.97, 93.96, 188.00, 751.4, 3758.1],  # 6 Diamond
]

const GEM_PATHS : Array[String] = [
	"res://Assets/Gems/Artboard 1Aquamarine.png",  # 0 lowest
	"res://Assets/Gems/Artboard 1Amethyst.png",
	"res://Assets/Gems/Artboard 1Topaz.png",
	"res://Assets/Gems/Artboard 1Sapphire.png",
	"res://Assets/Gems/Artboard 1Emerald.png",
	"res://Assets/Gems/Artboard 1Ruby.png",
	"res://Assets/Gems/Artboard 1Diamond.png",     # 6 highest
]

var _gem_textures : Array[Texture2D] = []

const COL_GOLD   := Color(0.973, 0.847, 0.188, 1)
const COL_GREEN  := Color(0.376, 0.973, 0.502, 1)
const COL_RED    := Color(0.973, 0.376, 0.376, 1)
const COL_BLUE   := Color(0.502, 0.753, 0.973, 1)
const COL_PANEL  := Color(0.063, 0.016, 0.125, 0.92)
const COL_BORDER := Color(0.314, 0.220, 0.565, 1)

enum State { IDLE, SPINNING }

var _state      : State = State.IDLE
var _fading     : bool  = false
var _bet        : float = 10.0
var _spin_win   : float = 0.0
var _meter      : int   = 0
var _gold_fever : bool  = false

# Grid data and visuals
var _grid        : Array[int] = []
var _slots       : Array      = []   # Panel nodes — slot backgrounds, fixed positions
var _gem_sprites : Array      = []   # TextureRect nodes — gems that move; null = empty

# UI refs
var _bet_input   : LineEdit
var _bal_lbl     : Label
var _win_lbl     : Label
var _spin_btn    : Button
var _meter_fill  : Panel
var _meter_bg    : Panel
var _meter_count : Label
var _grid_node   : Control
var _fade_rect   : ColorRect


func _ready() -> void:
	for path in GEM_PATHS:
		_gem_textures.append(load(path) as Texture2D)
	_fade_rect = find_child("FadeRect", true, false) as ColorRect
	var back   := find_child("BackBtn",  true, false) as Button
	if back:
		back.pressed.connect(_on_back)
	_build_layout()
	_build_grid_nodes()
	_randomize_grid()
	_spawn_all_gems(false)   # no animation on first load
	_update_hud()
	_fade_in()


# ── LAYOUT ────────────────────────────────────────────────────────────────────

func _make_stylebox(bg: Color, border: Color = COL_BORDER, bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color            = bg
	sb.border_color        = border
	sb.border_width_left   = bw
	sb.border_width_right  = bw
	sb.border_width_top    = bw
	sb.border_width_bottom = bw
	return sb


func _build_layout() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	move_child(center, 1)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	center.add_child(hbox)

	hbox.add_child(_build_left_panel())
	hbox.add_child(_build_right_area())


func _build_left_panel() -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(210, 0)
	panel.add_theme_stylebox_override("panel", _make_stylebox(COL_PANEL))

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.add_theme_constant_override("margin_left",   14)
	mg.add_theme_constant_override("margin_right",  14)
	mg.add_theme_constant_override("margin_top",    18)
	mg.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	var title := Label.new()
	title.text                 = "GEMS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COL_GOLD)
	vbox.add_child(title)

	_add_divider(vbox)

	vbox.add_child(_small_label("BET AMOUNT"))
	_bet_input      = LineEdit.new()
	_bet_input.text = str(int(_bet))
	_bet_input.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_bet_input)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	vbox.add_child(hb)
	var half_btn := Button.new()
	half_btn.text                  = "1/2"
	half_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	half_btn.pressed.connect(_on_half)
	hb.add_child(half_btn)
	var dbl_btn := Button.new()
	dbl_btn.text                  = "2x"
	dbl_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dbl_btn.pressed.connect(_on_double)
	hb.add_child(dbl_btn)

	_add_divider(vbox)

	_spin_btn                     = Button.new()
	_spin_btn.text                = "SPIN"
	_spin_btn.custom_minimum_size = Vector2(0, 52)
	_spin_btn.add_theme_font_size_override("font_size", 18)
	_spin_btn.pressed.connect(_on_spin)
	vbox.add_child(_spin_btn)

	_add_divider(vbox)

	vbox.add_child(_small_label("BALANCE"))
	_bal_lbl = Label.new()
	_bal_lbl.add_theme_font_size_override("font_size", 14)
	_bal_lbl.add_theme_color_override("font_color", COL_GREEN)
	vbox.add_child(_bal_lbl)

	vbox.add_child(_small_label("WIN"))
	_win_lbl      = Label.new()
	_win_lbl.text = "$0"
	_win_lbl.add_theme_font_size_override("font_size", 14)
	_win_lbl.add_theme_color_override("font_color", COL_GOLD)
	vbox.add_child(_win_lbl)

	var exp := Control.new()
	exp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(exp)

	return panel


func _build_right_area() -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var meter_row := HBoxContainer.new()
	meter_row.add_theme_constant_override("separation", 10)
	vbox.add_child(meter_row)

	var gf_lbl := Label.new()
	gf_lbl.text = "GOLD FEVER"
	gf_lbl.add_theme_font_size_override("font_size", 11)
	gf_lbl.add_theme_color_override("font_color", COL_GOLD)
	meter_row.add_child(gf_lbl)

	_meter_bg                       = Panel.new()
	_meter_bg.custom_minimum_size   = Vector2(360, 14)
	_meter_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_meter_bg.add_theme_stylebox_override("panel", _make_stylebox(
		Color(0.063, 0.031, 0.016, 1), Color(0.659, 0.408, 0.125, 1), 1))
	meter_row.add_child(_meter_bg)

	_meter_fill          = Panel.new()
	_meter_fill.position = Vector2.ZERO
	_meter_fill.size     = Vector2(0, 14)
	_meter_fill.add_theme_stylebox_override("panel", _make_stylebox(COL_GOLD, COL_GOLD, 0))
	_meter_bg.add_child(_meter_fill)

	_meter_count      = Label.new()
	_meter_count.text = "0 / 114"
	_meter_count.add_theme_font_size_override("font_size", 10)
	_meter_count.add_theme_color_override("font_color", COL_GOLD)
	meter_row.add_child(_meter_count)

	_grid_node                       = Control.new()
	_grid_node.custom_minimum_size   = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	_grid_node.clip_contents         = true
	_grid_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(_grid_node)

	return vbox


func _add_divider(parent: Control) -> void:
	var div := Panel.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.add_theme_stylebox_override("panel", _make_stylebox(COL_BORDER, COL_BORDER, 0))
	parent.add_child(div)


func _small_label(txt: String) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", COL_BLUE)
	return lbl


# ── GRID NODES ────────────────────────────────────────────────────────────────

func _build_grid_nodes() -> void:
	_slots.resize(64)
	_gem_sprites.resize(64)
	_gem_sprites.fill(null)
	var sb := _make_stylebox(Color(0.016, 0.008, 0.047, 1), Color(0.157, 0.094, 0.220, 1), 1)
	for i in 64:
		var slot      := Panel.new()
		slot.position  = Vector2((i % COLS) * CELL_SIZE, (i / COLS) * CELL_SIZE)
		slot.size      = Vector2(CELL_SIZE, CELL_SIZE)
		slot.add_theme_stylebox_override("panel", sb)
		_grid_node.add_child(slot)
		_slots[i] = slot


# ── GEM SPRITE HELPERS ────────────────────────────────────────────────────────

func _gem_xy(idx: int) -> Vector2:
	return Vector2((idx % COLS) * CELL_SIZE + 8.0, (idx / COLS) * CELL_SIZE + 8.0)


func _make_gem_sprite(sym: int, pos: Vector2) -> TextureRect:
	var tex         := TextureRect.new()
	tex.texture      = _gem_textures[sym]
	tex.position     = pos
	tex.size         = Vector2(48, 48)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_grid_node.add_child(tex)
	return tex


func _clear_all_gems() -> void:
	for i in 64:
		if _gem_sprites[i]:
			(_gem_sprites[i] as TextureRect).queue_free()
			_gem_sprites[i] = null


# Spawn all gems instantly (no_anim=true) or set up for drop-in animation
func _spawn_all_gems(animate: bool) -> void:
	_clear_all_gems()
	for i in 64:
		if _grid[i] == -1:
			continue
		var dest := _gem_xy(i)
		var start_y : float = dest.y if not animate else dest.y - float(ROWS) * CELL_SIZE
		var sprite := _make_gem_sprite(_grid[i], Vector2(dest.x, start_y))
		_gem_sprites[i] = sprite


# ── GRID DATA ─────────────────────────────────────────────────────────────────

func _randomize_grid() -> void:
	_grid.resize(64)
	for i in 64:
		_grid[i] = randi() % NSYMS


# ── SPIN START ANIMATION ──────────────────────────────────────────────────────

func _animate_drop_in(callback: Callable) -> void:
	_spawn_all_gems(true)   # gems start above grid
	var tw := create_tween()
	tw.set_parallel(true)
	for i in 64:
		var sprite := _gem_sprites[i] as TextureRect
		if not sprite:
			continue
		var dest_y : float = _gem_xy(i).y
		var col    : int   = i % COLS
		var delay  : float = col * 0.05
		tw.tween_property(sprite, "position:y", dest_y, 0.55)\
			.set_delay(delay)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_QUAD)
	tw.set_parallel(false)
	tw.tween_callback(callback)


# ── CLUSTER DETECTION ─────────────────────────────────────────────────────────

func _find_clusters() -> Array:
	var visited : Array[bool] = []
	visited.resize(64)
	visited.fill(false)
	var clusters : Array = []
	for i in 64:
		if visited[i] or _grid[i] == -1:
			continue
		var sym   := _grid[i]
		var open  := [i]
		var group : Array[int] = []
		while open.size() > 0:
			var idx : int = open.pop_back()
			if visited[idx]:
				continue
			visited[idx] = true
			if _grid[idx] != sym:
				continue
			group.append(idx)
			for nb : int in _neighbours(idx):
				if not visited[nb] and _grid[nb] == sym:
					open.append(nb)
		if group.size() >= MIN_CLUSTER:
			clusters.append(group)
	return clusters


func _neighbours(i: int) -> Array[int]:
	var r   := i / COLS
	var c   := i % COLS
	var out : Array[int] = []
	if r > 0:        out.append(i - COLS)
	if r < ROWS - 1: out.append(i + COLS)
	if c > 0:        out.append(i - 1)
	if c < COLS - 1: out.append(i + 1)
	return out


# ── PAYOUT ────────────────────────────────────────────────────────────────────

func _payout_mult(sym: int, size: int) -> float:
	var buckets : Array[int] = [5, 6, 7, 8, 9, 12, 15, 20, 25]
	var tier := 0
	for b in range(buckets.size() - 1, -1, -1):
		if size >= buckets[b]:
			tier = b
			break
	return PAYTABLE[sym][tier]


# ── SPIN FLOW ─────────────────────────────────────────────────────────────────

func _on_spin() -> void:
	if _state != State.IDLE or _fading:
		return
	var raw := _bet_input.text.strip_edges()
	if not raw.is_valid_float():
		_win_lbl.text = "Invalid bet"
		return
	var bet_val := float(raw)
	if bet_val < MIN_BET:
		_win_lbl.text = "Min $" + str(int(MIN_BET))
		return
	if bet_val > GameState.bankroll:
		_win_lbl.text = "Not enough"
		return

	_bet        = bet_val
	_spin_win   = 0.0
	_meter      = 0
	_gold_fever = false
	GameState.bankroll -= _bet
	_state             = State.SPINNING
	_spin_btn.disabled = true
	_win_lbl.text      = "$0"
	_update_hud()
	_update_meter_bar()

	_randomize_grid()
	_animate_drop_in(_run_tumble_chain)


func _run_tumble_chain() -> void:
	var clusters := _find_clusters()
	if clusters.is_empty():
		_finish_spin()
		return

	var sym_count := 0
	for cluster : Array in clusters:
		var sym  : int   = _grid[cluster[0]]
		var sz   : int   = cluster.size()
		_spin_win += _bet * _payout_mult(sym, sz)
		sym_count  += sz
		for idx : int in cluster:
			_grid[idx] = -1

	_meter += sym_count
	if _meter >= METER_MAX and not _gold_fever:
		_gold_fever = true

	_update_meter_bar()
	_win_lbl.text = "$" + _fmt(_spin_win)

	_animate_remove(clusters, func() -> void:
		_animate_tumble(func() -> void:
			var tw := create_tween()
			tw.tween_interval(0.18)
			tw.tween_callback(_run_tumble_chain)
		)
	)


# ── REMOVE ANIMATION ──────────────────────────────────────────────────────────

func _animate_remove(clusters: Array, callback: Callable) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	for cluster : Array in clusters:
		for idx : int in cluster:
			if _gem_sprites[idx]:
				tw.tween_property(_gem_sprites[idx], "modulate:a", 0.0, 0.25)
	tw.set_parallel(false)
	tw.tween_callback(func() -> void:
		for cluster : Array in clusters:
			for idx : int in cluster:
				if _gem_sprites[idx]:
					(_gem_sprites[idx] as TextureRect).queue_free()
					_gem_sprites[idx] = null
		callback.call()
	)


# ── TUMBLE ANIMATION ──────────────────────────────────────────────────────────

func _do_tumble_tracked() -> Dictionary:
	var slides   : Array = []
	var new_gems : Array = []
	for c in COLS:
		var write := ROWS - 1
		for r in range(ROWS - 1, -1, -1):
			var idx := r * COLS + c
			if _grid[idx] != -1:
				if write != r:
					slides.append({ from_idx = idx, to_idx = write * COLS + c })
					_grid[write * COLS + c] = _grid[idx]
					_grid[idx] = -1
				write -= 1
		for r in range(write, -1, -1):
			var sym := randi() % NSYMS
			_grid[r * COLS + c] = sym
			new_gems.append({ to_idx = r * COLS + c, sym = sym })
	return { slides = slides, new_gems = new_gems }


func _animate_tumble(callback: Callable) -> void:
	var moves := _do_tumble_tracked()

	# Relocate sprite references to match new data positions (bottom-to-top safe)
	for slide in moves.slides:
		var fi : int    = slide.from_idx
		var ti : int    = slide.to_idx
		_gem_sprites[ti] = _gem_sprites[fi]
		_gem_sprites[fi] = null

	var tw := create_tween()
	tw.set_parallel(true)

	# Slide existing gems down to new row
	for slide in moves.slides:
		var sprite = _gem_sprites[slide.to_idx]
		if sprite:
			tw.tween_property(sprite, "position:y", _gem_xy(slide.to_idx).y, 0.32)\
				.set_ease(Tween.EASE_IN)\
				.set_trans(Tween.TRANS_QUAD)

	# Drop new gems in from above, staggered by column
	for entry in moves.new_gems:
		var ti      : int   = entry.to_idx
		var sym     : int   = entry.sym
		var dest    := _gem_xy(ti)
		var col     : int   = ti % COLS
		var start_y : float = dest.y - float(ROWS) * CELL_SIZE
		var sprite  := _make_gem_sprite(sym, Vector2(dest.x, start_y))
		_gem_sprites[ti] = sprite
		tw.tween_property(sprite, "position:y", dest.y, 0.42)\
			.set_delay(col * 0.03)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_QUAD)

	tw.set_parallel(false)
	tw.tween_callback(callback)


# ── FINISH ────────────────────────────────────────────────────────────────────

func _finish_spin() -> void:
	if _gold_fever:
		_spin_win *= 2.0
	if _spin_win > 0.0:
		GameState.bankroll += _spin_win
		GameState.add_fame(TOWN_ID, _spin_win * 0.1)
		var label := "+$" + _fmt(_spin_win)
		if _gold_fever:
			label += "  [GOLD FEVER 2x]"
		_win_lbl.text = label
	else:
		_win_lbl.text = "$0"
	_meter      = 0
	_gold_fever = false
	_update_meter_bar()
	_state             = State.IDLE
	_spin_btn.disabled = false
	_update_hud()


# ── METER ─────────────────────────────────────────────────────────────────────

func _update_meter_bar() -> void:
	if not _meter_bg or not _meter_fill or not _meter_count:
		return
	var bar_w := _meter_bg.size.x
	if bar_w <= 0.0:
		bar_w = _meter_bg.custom_minimum_size.x
	var pct : float = clamp(float(_meter) / float(METER_MAX), 0.0, 1.0)
	_meter_fill.size.x = bar_w * pct
	_meter_count.text  = str(_meter) + " / " + str(METER_MAX)


# ── HUD ───────────────────────────────────────────────────────────────────────

func _update_hud() -> void:
	if _bal_lbl:
		var br := GameState.bankroll
		_bal_lbl.text = "$" + _fmt(br)
		_bal_lbl.add_theme_color_override("font_color",
			COL_RED if br < 200.0 else COL_GREEN)


# ── BET HELPERS ───────────────────────────────────────────────────────────────

func _on_half() -> void:
	_bet            = max(MIN_BET, floor(_bet * 0.5))
	_bet_input.text = str(int(_bet))


func _on_double() -> void:
	_bet            = min(GameState.bankroll, _bet * 2.0)
	_bet_input.text = str(int(_bet))


# ── TRANSITIONS ───────────────────────────────────────────────────────────────

func _fade_in() -> void:
	if not _fade_rect:
		return
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade_rect, "color:a", 0.0, 0.4)


func _on_back() -> void:
	if _fading or _state != State.IDLE:
		return
	_fading = true
	if not _fade_rect:
		get_tree().call_deferred("change_scene_to_file",
			"res://scenes/main_menu/MainMenu.tscn")
		return
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade_rect, "color:a", 1.0, 0.3)
	tw.tween_callback(func() -> void:
		get_tree().call_deferred("change_scene_to_file",
			"res://scenes/main_menu/MainMenu.tscn"))


# ── HELPERS ───────────────────────────────────────────────────────────────────

func _fmt(val: float) -> String:
	if val >= 1_000_000.0:
		return "%.1fM" % (val / 1_000_000.0)
	if val >= 1_000.0:
		return "%.1fK" % (val / 1_000.0)
	return str(int(val))
