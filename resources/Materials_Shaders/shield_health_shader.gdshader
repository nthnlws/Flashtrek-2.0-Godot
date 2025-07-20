shader_type canvas_item;

uniform vec4 color: source_color = vec4(0.36, 0.527, 0.837, 1.0);


// Uniforms for health cutoff
uniform float health_ratio : hint_range(0.0, 1.0) = 1.0;
// Center is assumed to be at (0.5, 0.5).
float circle(vec2 position_uv, float radius, float feather) {
	return smoothstep(radius, radius + feather, length(position_uv - vec2(0.5)));
}

void fragment() {
	// --- 1. Health Cutoff Logic (Unchanged) ---
	if (UV.x > health_ratio) {
		discard;
	}

	// --- 2. Shield Rendering Logic ---
	float outer = circle(UV, 0.455, 0.045);
	float fade_effect = sin(TIME * 0.5) * 0.052;
	float inner = 1.0 - circle(UV, 0.357, 0.13 - fade_effect);

	COLOR.rgb = color.rgb;
	float combined_mask_effect = outer + inner;
	COLOR.a = color.a * max(0.0, color.a - combined_mask_effect);

	if (COLOR.a < 0.01) {
		discard;
	}
}