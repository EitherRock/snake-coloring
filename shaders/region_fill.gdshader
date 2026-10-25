shader_type canvas_item;

#define MAX_BANDS 10  // keep equal to MAX_BANDS in Region.gd

uniform sampler2D region_mask : filter_linear;
uniform vec2 mask_size = vec2(1024.0, 1024.0);  // size of this region's box in pixels
uniform vec2 fill_origin = vec2(0.5, 0.5);      // UV within the box
uniform float max_distance = 500.0;
uniform float edge_softness : hint_range(0.0, 0.1) = 0.01;

uniform int pattern : hint_range(0, 5) = 0;     // 0 radial, 1 linear, 2 spiral, 3 checker
uniform vec2 linear_dir = vec2(1.0, 0.0);       // direction the linear fill travels
uniform float spiral_turns = 3.0;
uniform float checker_size = 32.0;              // cell size in pixels (set per region from script)

uniform vec4 band_colors[MAX_BANDS];
uniform float band_amounts[MAX_BANDS];

uniform float glow_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Turns a pixel into a fill position from 0 to 1
float fill_position(vec2 uv) {
	vec2 pos = uv * mask_size;
	vec2 rel = pos - fill_origin * mask_size;
	float t = 0.0;

	if (pattern == 1) {
		vec2 dir = normalize(linear_dir);
		float p1 = dot(vec2(mask_size.x, 0.0), dir);
		float p2 = dot(vec2(0.0, mask_size.y), dir);
		float p3 = dot(mask_size, dir);
		float lo = min(min(0.0, p1), min(p2, p3));
		float hi = max(max(0.0, p1), max(p2, p3));
		t = (dot(pos, dir) - lo) / max(hi - lo, 0.0001);
	} else if (pattern == 2) {
		float r = length(rel) / max_distance;
		float ang = atan(rel.y, rel.x) / TAU + 0.5;
		t = fract(ang + r * spiral_turns);
	} else if (pattern == 3) {
		vec2 cells = ceil(mask_size / checker_size);
		vec2 c = floor(pos / checker_size);
		float parity = mod(c.x + c.y, 2.0);
		float order = (c.y * cells.x + c.x) / (cells.x * cells.y);
		t = 0.5 * parity + 0.5 * order;
	} else if (pattern == 4) {
		// Clock: sweeps clockwise from 12 o'clock around the fill origin
		t = fract(atan(rel.y, rel.x) / TAU + 0.25);
	} else if (pattern == 5) {
		// Diamond: Manhattan distance, normalized to the farthest corner of the box
		vec2 far = max(fill_origin, vec2(1.0) - fill_origin) * mask_size;
		t = (abs(rel.x) + abs(rel.y)) / max(far.x + far.y, 0.0001);
	} else {
		t = length(rel) / max_distance;
	}
	return clamp(t, 0.0, 1.0);
}

void fragment() {
	float mask = texture(region_mask, UV).a;
	if (mask <= 0.0) {
		discard;
	}

	// The small scale keeps the last band fully covering the far edge once the region is full
	float t = fill_position(UV) * (1.0 - edge_softness);

	float cumulative = 0.0;
	vec4 fill = vec4(0.0);
	for (int i = 0; i < MAX_BANDS; i++) {
		float band_start = cumulative;
		float band_end = cumulative + band_amounts[i];
		float band_mask = smoothstep(band_start - edge_softness, band_start, t)
						- smoothstep(band_end - edge_softness, band_end, t);
		fill += band_colors[i] * band_mask;
		cumulative = band_end;
	}

	float fill_a = clamp(fill.a, 0.0, 1.0);
	float glow_a = glow_intensity * glow_color.a;
	vec3 rgb = mix(fill.rgb, glow_color.rgb, glow_intensity * 0.6);
	float alpha = max(fill_a, glow_a * 0.8);

	COLOR = vec4(rgb, alpha * mask);
}