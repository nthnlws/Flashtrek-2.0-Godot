shader_type canvas_item;

// Define uniforms to receive parameters from your GDScript.
uniform vec2 u_rect_size;
uniform vec2 u_vertex_a;
uniform vec2 u_vertex_b;
uniform vec2 u_vertex_c;

// Customizable appearance parameters for the tractor beam.
uniform vec4 beam_color : source_color = vec4(0.2, 0.6, 1.0, 0.7);
uniform float pulse_speed : hint_range(0.1, 10.0) = 3.0;
// Removed noise_scale as it's now handled by the NoiseTexture2D's FastNoiseLite frequency and properties.
uniform float noise_strength : hint_range(0.0, 1.0) = 0.4;
uniform float edge_fade_width : hint_range(1.0, 100.0) = 30.0;

uniform sampler2D noise_texture; 
uniform float min_alpha_floor : hint_range(0.0, 1.0) = 0.1;

// (Retained from previous version, adjusted smoothstep parameters for correct fade)
float distance_to_infinite_line(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    vec2 ap = p - a;
    return abs(ap.x * ab.y - ap.y * ab.x) / length(ab);
}

void fragment() {
    vec2 p_in_rect = UV * u_rect_size;

    vec2 v0 = u_vertex_b - u_vertex_a;
    vec2 v1 = u_vertex_c - u_vertex_a;
    vec2 v2 = p_in_rect - u_vertex_a;

    float inv_den = 1.0 / (v0.x * v1.y - v1.x * v0.y);
    float u_bary = (v2.x * v1.y - v1.x * v2.y) * inv_den;
    float v_bary = (v0.x * v2.y - v2.x * v0.y) * inv_den;

    bool inside_triangle = (u_bary >= 0.0) && (v_bary >= 0.0) && (u_bary + v_bary <= 1.0);

    if (!inside_triangle) {
        COLOR = vec4(0.0);
        discard;
    }

    float d_line_ab = distance_to_infinite_line(p_in_rect, u_vertex_a, u_vertex_b);
    float d_line_bc = distance_to_infinite_line(p_in_rect, u_vertex_b, u_vertex_c);
    float d_line_ca = distance_to_infinite_line(p_in_rect, u_vertex_c, u_vertex_a);

    float min_dist_to_any_edge = min(d_line_ab, min(d_line_bc, d_line_ca));

    // Corrected smoothstep for fading out edges (0.0 at edge, 1.0 towards center)
    float edge_alpha_fade = smoothstep(0.0, edge_fade_width, min_dist_to_any_edge);

    // --- 3. Pulsy and Variation (Water surface-like effect) ---
    // Sample the NoiseTexture2D for smoother noise.
    // Adjust these UV coordinates to control the "scrolling" or "wavy" direction/speed.
    // The scale of the noise is now controlled by the NoiseTexture2D's FastNoiseLite settings.
    vec2 sampled_noise_uv = UV + vec2(TIME * 0.05, TIME * 0.03); // Simple scrolling
    // Sampling with texture() function. The .r accesses the red channel of the grayscale noise.
    float noise_val = texture(noise_texture, sampled_noise_uv).r;

    float wavy_effect = sin((p_in_rect.x * 0.1 + TIME * 2.0) + noise_val * 3.0) * 0.5 + 0.5;

    float overall_pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5);

    float final_light_variation = mix(1.0, wavy_effect * overall_pulse, noise_strength);

    // --- 4. Final Color Calculation ---
    vec4 final_color = beam_color;
    final_color.rgb *= final_light_variation;
    final_color.a *= final_light_variation;
    final_color.a *= edge_alpha_fade;
	final_color.a = max(min_alpha_floor, final_color.a);

    COLOR = final_color;
}