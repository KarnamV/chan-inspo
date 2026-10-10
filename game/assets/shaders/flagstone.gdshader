shader_type spatial;
// Stylized flagstone floor in world space (no texture, no tiling seams). Running-bond stones with
// per-stone colour + facet tilt (low-poly look), dark grout, a few darker stones.
render_mode diffuse_burley;

uniform vec3 stone_a : source_color = vec3(0.40, 0.33, 0.32);
uniform vec3 stone_b : source_color = vec3(0.29, 0.24, 0.25);
uniform vec3 grout : source_color = vec3(0.09, 0.06, 0.06);
uniform float tile = 1.3;        // metres per stone
uniform float grout_w = 0.05;
uniform float dim = 1.0;         // < 1 for the street outside the room

varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz / vec2(tile * 1.4, tile);
	p.x += mod(floor(p.y), 2.0) * 0.5;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float h = hash(cell);
	vec3 c = mix(stone_a, stone_b, h) * (0.88 + 0.24 * hash(cell + 7.3));
	c = mix(c, c * 0.62, step(0.92, hash(cell + 3.1)));
	vec2 d = min(f, 1.0 - f) * vec2(tile * 1.4, tile);
	float e = min(d.x, d.y);
	float g = 1.0 - smoothstep(grout_w * 0.5, grout_w, e);
	c = mix(c * 0.78, c, smoothstep(grout_w, grout_w * 3.5, e));
	c = mix(c, grout, g);
	ALBEDO = c * dim;
	ROUGHNESS = mix(0.82, 0.98, g);
	vec2 tilt = (vec2(hash(cell + 1.7), hash(cell + 9.2)) - 0.5) * 0.35 * (1.0 - g);
	NORMAL_MAP = normalize(vec3(tilt, 1.0)) * 0.5 + 0.5;
}
