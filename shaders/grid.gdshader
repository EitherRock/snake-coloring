shader_type canvas_item;

uniform vec4 background_color : source_color = vec4(0.85, 0.85, 0.85, 1.0);
uniform vec4 minor_color : source_color = vec4(0.72, 0.72, 0.72, 1.0);
uniform vec4 major_color : source_color = vec4(0.55, 0.55, 0.55, 1.0);

uniform float minor_size = 32.0;   // size of the small squares, in pixels
uniform float major_every = 5.0;   // one big line every N small squares
uniform float minor_width = 1.0;
uniform float major_width = 2.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float grid_line(vec2 pos, float cell, float width) {
	// distance in pixels from this point to the nearest grid line
	vec2 d = abs(fract(pos / cell - 0.5) - 0.5) * cell;
	float dist = min(d.x, d.y);
	return 1.0 - smoothstep(width * 0.5 - 0.5, width * 0.5 + 0.5, dist);
}

void fragment() {
	vec4 col = background_color;
	col = mix(col, minor_color, grid_line(world_pos, minor_size, minor_width));
	col = mix(col, major_color, grid_line(world_pos, minor_size * major_every, major_width));
	COLOR = col;
}