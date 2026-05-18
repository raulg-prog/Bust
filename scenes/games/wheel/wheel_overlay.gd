extends Control

func _draw() -> void:
	var cx := size.x * 0.5
	# Downward-pointing gold triangle at 12 o'clock — marks the landing position.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(cx - 13.0, -12.0),
			Vector2(cx + 13.0, -12.0),
			Vector2(cx,          8.0),
		]),
		Color(0.973, 0.847, 0.188, 1.0)
	)
	# Thin dark outline so the pointer is visible over light segments.
	draw_polyline(
		PackedVector2Array([
			Vector2(cx - 13.0, -12.0),
			Vector2(cx + 13.0, -12.0),
			Vector2(cx,          8.0),
			Vector2(cx - 13.0, -12.0),
		]),
		Color(0.06, 0.04, 0.16, 1.0),
		1.5
	)
