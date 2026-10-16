shader_type spatial;
// Rim light for characters (next_pass on their own materials): an additive fresnel edge so
// dark trousers and demon hides separate from the night-market floor. Readability, not lighting.
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;

uniform vec3 rim_color : source_color = vec3(1.0, 0.78, 0.5);
uniform float strength = 0.16;
uniform float power = 4.0;
uniform float lift = 0.35;   // fade the rim out toward the feet so it doesn't glow on the floor line

void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), power);
	// upward-facing surfaces catch more of the rim (lantern light from above)
	vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	float up = clamp(wn.y * 0.5 + 0.5 + lift, 0.0, 1.0);
	ALBEDO = rim_color * f * strength * up;
}
