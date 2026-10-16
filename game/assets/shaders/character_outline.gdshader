shader_type spatial;
// Inverted-hull outline for characters (next_pass): a thin dark shell drawn back faces only.
render_mode unshaded, cull_front, shadows_disabled;

uniform vec3 outline_color : source_color = vec3(0.05, 0.03, 0.04);
uniform float width = 0.012;   // metres

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = outline_color;
}
