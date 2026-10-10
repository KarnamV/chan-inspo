shader_type spatial;
// Night-market wall in world space: stone footing, red lacquered planks, dark posts every 3 m,
// gold trim band, dark top beam. Works on any axis-aligned wall box.

uniform vec3 lacquer : source_color = vec3(0.52, 0.09, 0.06);
uniform vec3 post : source_color = vec3(0.14, 0.06, 0.05);
uniform vec3 footing : source_color = vec3(0.30, 0.26, 0.25);
uniform vec3 trim : source_color = vec3(0.86, 0.62, 0.26);

varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float u = wpos.x + wpos.z;
	float y = wpos.y;
	float pl = fract(u / 0.32);
	vec3 c = lacquer * (0.9 + 0.18 * hash(vec2(floor(u / 0.32), 0.0)));
	c *= 0.82 + 0.18 * smoothstep(0.0, 0.1, pl) * smoothstep(1.0, 0.9, pl);
	float rough = 0.4;
	float is_post = step(fract(u / 3.0 + 0.5), 0.06);
	c = mix(c, post, is_post);
	c = mix(c, trim, step(abs(y - 1.85), 0.045));
	c = mix(c, post, step(2.18, y));
	float foot = step(y, 0.42);
	vec2 brick = floor(vec2(u / 0.55 + mod(floor(y / 0.21), 2.0) * 0.5, y / 0.21));
	vec3 stone = footing * (0.85 + 0.3 * hash(brick));
	c = mix(c, stone, foot);
	rough = mix(rough, 0.95, max(foot, is_post));
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = 0.6;
}
