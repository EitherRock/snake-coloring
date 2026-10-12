shader_type canvas_item;

#define MAX_BANDS 50  // must match MAX_BANDS in Region.gd

uniform sampler2D region_mask : filter_linear;  // alpha = 1 inside this region
uniform vec2 mask_size = vec2(1024.0, 1024.0);  // mask size in pixels
uniform vec2 fill_origin = vec2(0.5, 0.5);      // where the fill starts, in UV (0-1)
uniform float max_distance = 500.0;             // distance (px) from origin to farthest pixel in the region
uniform float edge_softness : hint_range(0.0, 0.1) = 0.01;

uniform vec4 band_colors[MAX_BANDS];
uniform float band_amounts[MAX_BANDS];

uniform float glow_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	float mask = texture(region_mask, UV).a;

	// 0.0 at the origin, 1.0 at the farthest point of the region
	float dist = length((UV - fill_origin) * mask_size) / max_distance;

	// Stack bands outward from the origin (same logic as before)
	float cumulative = 0.0;
	vec4 fill = vec4(0.0);
	for (int i = 0; i < MAX_BANDS; i++) {
		float band_start = cumulative;
		float band_end = cumulative + band_amounts[i];
		float band_mask = smoothstep(band_start - edge_softness, band_start, dist)
						- smoothstep(band_end - edge_softness, band_end, dist);
		fill += band_colors[i] * band_mask;
		cumulative = band_end;
	}

	// Glow works even when the region is empty
	float fill_a = clamp(fill.a, 0.0, 1.0);
	float glow_a = glow_intensity * glow_color.a;
	vec3 rgb = mix(fill.rgb, glow_color.rgb, glow_intensity * 0.6);
	float alpha = max(fill_a, glow_a * 0.8);

	COLOR = vec4(rgb, alpha * mask);
}