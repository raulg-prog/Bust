@tool
extends EditorScript

# ── CONFIG ────────────────────────────────────────────────────────────────────
const SPINS    := 500_000
const TARGET_RTP := 98.0
const COLS     := 8
const ROWS     := 8
const NSYMS    := 7
const MIN_CLUS := 5

const PAYTABLE : Array = [
	[0.38,  0.57,  0.76,  1.31,  3.76,  7.52,  14.09,  37.6,  188.0],  # 0 Aquamarine
	[0.57,  0.76,  1.12,  1.88,  5.64,  9.40,  18.80,  56.4,  281.8],  # 1 Amethyst
	[0.76,  0.93,  1.50,  2.26,  7.52, 14.09,  28.18,  75.2,  375.7],  # 2 Topaz
	[0.93,  1.12,  1.50,  2.81,  9.40, 18.80,  37.58,  94.0,  563.8],  # 3 Sapphire
	[1.12,  1.88,  2.81,  4.69, 14.09, 28.18,  56.38, 188.0, 1127.6],  # 4 Emerald
	[1.88,  2.81,  4.69,  9.40, 28.18, 46.97,  93.96, 375.7, 1879.7],  # 5 Ruby
	[3.76,  5.64,  9.40, 18.80, 46.97, 93.96, 188.00, 751.4, 3758.1],  # 6 Diamond
]

const SIZE_BUCKETS : Array[int] = [5, 6, 7, 8, 9, 12, 15, 20, 25]


func _run() -> void:
	print("=== GEMS RTP SIMULATION — %d spins ===" % SPINS)

	var total_paid  : float = 0.0
	var zero_spins  : int   = 0
	var tumble_total: int   = 0
	var max_tumbles : int   = 0

	var grid : Array[int] = []
	grid.resize(64)

	for _s in SPINS:
		# Fill grid
		for i in 64:
			grid[i] = randi() % NSYMS

		var spin_pay  : float = 0.0
		var tumbles   : int   = 0

		while true:
			var clusters := _find_clusters(grid)
			if clusters.is_empty():
				break
			tumbles += 1
			for cluster : Array in clusters:
				var sym  : int   = grid[cluster[0]]
				var sz   : int   = cluster.size()
				spin_pay += _payout_mult(sym, sz)
				for idx : int in cluster:
					grid[idx] = -1
			_tumble(grid)

		total_paid  += spin_pay
		tumble_total += tumbles
		if tumbles > max_tumbles:
			max_tumbles = tumbles
		if spin_pay == 0.0:
			zero_spins += 1

	var rtp         : float = total_paid / float(SPINS) * 100.0
	var avg_tumbles : float = float(tumble_total) / float(SPINS)
	var hit_rate    : float = float(SPINS - zero_spins) / float(SPINS) * 100.0

	print("RTP:          %.2f%%" % rtp)
	print("Hit rate:     %.2f%% of spins pay anything" % hit_rate)
	print("Avg tumbles:  %.3f per spin" % avg_tumbles)
	print("Max tumbles:  %d" % max_tumbles)
	print("")
	print("To reach %.1f%% RTP, multiply all PAYTABLE values by: %.4f" % [TARGET_RTP, TARGET_RTP / rtp])


# ── CLUSTER DETECTION ─────────────────────────────────────────────────────────

func _find_clusters(grid: Array[int]) -> Array:
	var visited : Array[bool] = []
	visited.resize(64)
	visited.fill(false)
	var clusters : Array = []
	for i in 64:
		if visited[i] or grid[i] == -1:
			continue
		var sym   := grid[i]
		var open  := [i]
		var group : Array[int] = []
		while open.size() > 0:
			var idx : int = open.pop_back()
			if visited[idx]:
				continue
			visited[idx] = true
			if grid[idx] != sym:
				continue
			group.append(idx)
			for nb : int in _neighbours(idx):
				if not visited[nb] and grid[nb] == sym:
					open.append(nb)
		if group.size() >= MIN_CLUS:
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
	var tier := 0
	for b in range(SIZE_BUCKETS.size() - 1, -1, -1):
		if size >= SIZE_BUCKETS[b]:
			tier = b
			break
	return PAYTABLE[sym][tier]


# ── TUMBLE ────────────────────────────────────────────────────────────────────

func _tumble(grid: Array[int]) -> void:
	for c in COLS:
		var write := ROWS - 1
		for r in range(ROWS - 1, -1, -1):
			var idx := r * COLS + c
			if grid[idx] != -1:
				if write != r:
					grid[write * COLS + c] = grid[idx]
					grid[idx] = -1
				write -= 1
		for r in range(write, -1, -1):
			grid[r * COLS + c] = randi() % NSYMS
