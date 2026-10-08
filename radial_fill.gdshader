shader_type canvas_item;

#define MAX_COLORS 5

uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float edge_softness : hint_range(0.0, 0.1) = 0.02;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform vec4 band_colors[MAX_COLORS];
uniform float band_amounts[MAX_COLORS]; // each 0.0–1.0, independent thickness per color

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv) / radius;

	float circle_mask = 1.0 - smoothstep(1.0 - edge_softness, 1.0, dist);
	
	// Walk through bands, stacking them from center outward
	float cumulative = 0.0;
	vec4 final_color = vec4(0.0);

	for (int i = 0; i < MAX_COLORS; i++) {
		float band_start = cumulative;
		float band_end = cumulative + band_amounts[i];

		float band_mask = smoothstep(band_start - edge_softness, band_start, dist)
						 - smoothstep(band_end - edge_softness, band_end, dist);

		final_color += band_colors[i] * band_mask;
		cumulative = band_end;
	}
	
	vec4 glow = glow_color * glow_intensity * circle_mask;
	vec4 combined = final_color + glow * (1.0 - final_color.a); // glow fills in where fill is transparent
	float final_alpha = max(final_color.a, glow.a * circle_mask);
	
	//COLOR = vec4(1.0, 0.0, 0.0, band_mask * circle_mask);
	COLOR = vec4(combined.rgb, final_alpha * circle_mask);
}