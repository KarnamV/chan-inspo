shader_type spatial;
// Stylized flagstone floor in world space (no texture, no tiling seams). Running-bond stones with
// per-stone colour + facet tilt (low-poly look), dark grout, a few darker stones.
// Grout edges are filtered with screen-space derivatives so they don't shimmer at a distance;
// stones get soft grime blotches, worn lighter centres, and darken toward the room walls.
render_mode diffuse_burley;

uniform vec3 stone_a : source_color = vec3(0.40, 0.33, 0.32);
uniform vec3 stone_b : source_color = vec3(0.29, 0.24, 0.25);
uniform vec3 grout : source_color = vec3(0.09, 0.06, 0.06);
uniform float tile = 1.3;        // metres per stone
uniform float grout_w = 0.05;
uniform float dim = 1.0;         // < 1 for the street outside the room
uniform float room_half = 0.0;   // > 0: darken toward walls at this half-size (metres)

varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

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
	float aa = max(fwidth(e), 0.002);   // one pixel, in metres
	float g = 1.0 - smoothstep(grout_w * 0.5 - aa, grout_w * 0.5 + aa, e);
	c = mix(c * 0.8, c, smoothstep(grout_w, grout_w * 3.5 + aa, e));
	// worn centres (feet polish the middle) and grime blotches (fade out where they'd alias)
	float detail = clamp(1.0 - aa * 40.0, 0.0, 1.0);
	float worn = smoothstep(0.15, 0.5, min(f.x, 1.0 - f.x) * 2.0) * smoothstep(0.15, 0.5, min(f.y, 1.0 - f.y) * 2.0);
	c *= 1.0 + 0.08 * worn * detail;
	float grime = vnoise(wpos.xz * 0.9 + h * 13.0) * vnoise(wpos.xz * 3.1);
	c *= 1.0 - 0.28 * smoothstep(0.25, 0.6, grime) * detail;
	c = mix(c, grout, g);
	if (room_half > 0.0) {
		float edge = max(abs(wpos.x), abs(wpos.z)) / room_half;
		c *= mix(1.0, 0.72, smoothstep(0.62, 1.0, edge));
	}
	ALBEDO = c * dim;
	ROUGHNESS = mix(mix(0.78, 0.9, grime), 0.98, g) - 0.08 * worn * detail;
	vec2 tilt = (vec2(hash(cell + 1.7), hash(cell + 9.2)) - 0.5) * 0.35 * (1.0 - g);
	NORMAL_MAP = normalize(vec3(tilt, 1.0)) * 0.5 + 0.5;
}
