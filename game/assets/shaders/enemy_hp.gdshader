shader_type spatial;
// Tiny billboard health bar over a demon. `ratio` is per instance (no material copies).
render_mode unshaded, cull_disabled, depth_test_disabled, shadows_disabled;

instance uniform float ratio = 1.0;
instance uniform float chip = 1.0;   // trails ratio so a hit shows as a chunk
uniform vec3 fill : source_color = vec3(0.92, 0.22, 0.18);

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 px = vec2(0.02, 0.18);   // border
	bool border = UV.x < px.x || UV.x > 1.0 - px.x || UV.y < px.y || UV.y > 1.0 - px.y;
	float x = (UV.x - px.x) / (1.0 - 2.0 * px.x);
	vec3 c = vec3(0.08, 0.04, 0.04);
	if (x <= chip) c = vec3(1.0, 0.85, 0.55);
	if (x <= ratio) c = fill * (UV.y < 0.45 ? 1.15 : 0.9);
	ALBEDO = border ? vec3(0.0) : c;
	ALPHA = 0.95;
}
