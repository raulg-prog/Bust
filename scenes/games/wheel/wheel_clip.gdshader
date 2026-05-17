shader_type canvas_item;

void fragment() {
	// Correct for the 517x515 source not being perfectly square
	vec2 uv  = UV - vec2(0.5);
	uv.x    *= 517.0 / 515.0;
	float d  = length(uv);

	vec4 col = texture(TEXTURE, UV);

	// Smooth circular clip — keeps full black rim, fades out over ~4px
	float aa   = 0.007;
	float clip = 0.490;
	col.a     *= 1.0 - smoothstep(clip - aa, clip + aa, d);

	COLOR = col;
}
