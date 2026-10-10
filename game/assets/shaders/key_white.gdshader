shader_type canvas_item;
// Portraits are generated on white: fade near-white pixels to transparent. `circle` > 0 also masks
// to a circle (HUD face; replaces clip_children, which errors on scene change in 4.7).
uniform float threshold = 0.9;
uniform float circle = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float m = min(c.r, min(c.g, c.b));
	c.a *= 1.0 - smoothstep(threshold, 0.985, m);
	if (circle > 0.0) {
		float d = distance(UV, vec2(0.5));
		c.a *= 1.0 - smoothstep(0.47, 0.5, d);
	}
	COLOR = c;
}
