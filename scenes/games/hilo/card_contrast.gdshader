shader_type canvas_item;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float mx  = max(col.r, max(col.g, col.b));
	float mn  = min(col.r, min(col.g, col.b));
	float sat = mx > 0.001 ? (mx - mn) / mx : 0.0;
	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	// Only pull unsaturated dark pixels toward black; leaves reds and whites alone
	float pull = (1.0 - sat) * (1.0 - lum) * 0.5;
	col.rgb = max(col.rgb - pull, vec3(0.0));
	COLOR = col;
}
