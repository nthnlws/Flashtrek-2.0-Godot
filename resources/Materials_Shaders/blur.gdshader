shader_type canvas_item;

// This is a filter, so we use the default blend mode.
// The "blend_add" mode has been removed.

// --- UNIFORMS for Customization ---
uniform vec2 focus_center = vec2(0.5, 0.5); // The point that will be perfectly sharp.
uniform float focus_radius : hint_range(0.0, 1.0, 0.01) = 0.2; // The radius of the sharp area (0 to 1).
uniform float focus_falloff : hint_range(0.0, 1.0, 0.01) = 0.4; // How gradually the blur fades in.

uniform float max_strength : hint_range(0.0, 0.5, 0.01) = 0.1; // The maximum blur strength at the screen edge.
uniform int quality : hint_range(1, 30) = 10; // Number of samples. Higher is smoother but slower.

void fragment() {
	// 1. Calculate the distance of the current pixel (UV) from the focus_center.
	float dist = distance(UV, focus_center);

	// 2. Use smoothstep to create a "blur factor" from 0.0 (sharp) to 1.0 (fully blurred).
	// This factor will be 0.0 inside the focus_radius, and smoothly transition to 1.0
	// over the distance defined by focus_falloff.
	float blur_factor = smoothstep(focus_radius, focus_radius + focus_falloff, dist);


	// 3. The actual blur strength for this pixel depends on how far it is from the center.
	float current_strength = max_strength * blur_factor;

	// --- The Radial Blur Loop (same as before, but using current_strength) ---
	vec4 color = vec4(0.0);
	float float_quality = float(quality);

	for (int i = 0; i < quality; i++) {
		float offset = float(i) / float_quality * current_strength;
		vec2 sample_uv = mix(focus_center, UV, 1.0 - offset);
		color += texture(TEXTURE, sample_uv);
	}

	color /= float_quality;

	// 4. The final color is a mix between the original sharp pixel and the blurred result,
	// controlled by our blur_factor. This ensures the center remains perfectly sharp.
	COLOR = mix(texture(TEXTURE, UV), color, blur_factor);
}