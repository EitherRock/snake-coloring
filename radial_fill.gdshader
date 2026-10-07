//shader_type canvas_item;
//
//uniform float fill_amount : hint_range(0.0, 1.0) = 0.0;
//uniform vec4 fill_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);
//uniform float radius : hint_range(0.0, 1.0) = 0.5;
//uniform float edge_softness : hint_range(0.0, 0.1) = 0.02;
//
//void fragment() {
	//vec2 centered_uv = UV - vec2(0.5);
	//float dist = length(centered_uv) / radius;
//
	//// Circle mask (so shader stays within a circular shape, not a square texture)
	//float circle_mask = 1.0 - smoothstep(1.0 - edge_softness, 1.0, dist);
//
	//// Radial fill mask — fills from center outward based on fill_amount
	//float fill_mask = 1.0 - smoothstep(fill_amount - edge_softness, fill_amount, dist);
//
	//float final_alpha = circle_mask * fill_mask * fill_color.a;
//
	//COLOR = vec4(fill_color.rgb, final_alpha);
//}
shader_type canvas_item;

#define MAX_COLORS 50

uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float edge_softness : hint_range(0.0, 0.1) = 0.02;

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

	COLOR = vec4(final_color.rgb, final_color.a * circle_mask);
}