shader_type canvas_item;

// --- Cloak Controls ---
uniform float cloak_alpha : hint_range(0.0, 1.0) = 1.0; 
uniform int direction : hint_enum("Up,Down,Left,Right") = 0;

// --- Speed Controls ---
uniform float noise_speed = 0.05;      
uniform float distortion_speed = 0.15; 

// --- Visual Style ---
uniform vec4 cloak_color : source_color = vec4(0.0, 1.0, 0.5, 1.0); 
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;
uniform float edge_glow : hint_range(0.0, 2.0) = 0.8;

// --- Texture ---
uniform sampler2D noise_texture : repeat_enable;

void fragment() {
	// 1. Directional Movement
	vec2 move_dir = vec2(0.0);
	if (direction == 0) move_dir = vec2(0.0, -1.0);
	else if (direction == 1) move_dir = vec2(0.0, 1.0);
	else if (direction == 2) move_dir = vec2(-1.0, 0.0);
	else if (direction == 3) move_dir = vec2(1.0, 0.0);
	
	// 2. Separate UVs
	vec2 noise_uv = UV + (move_dir * TIME * noise_speed);
	vec2 dist_uv = UV + (move_dir * TIME * distortion_speed);
	
	// 3. Sample Noise
	float noise_shimmer = texture(noise_texture, noise_uv).r;
	vec2 noise_distort = texture(noise_texture, dist_uv).gb;
	
	// 4. Distortion Logic
	// Distortion is strongest at 0.5 alpha and zero at 1.0 or 0.0
	float effect_weight = sin(cloak_alpha * PI); 
	vec2 warped_uv = UV + ((noise_distort - 0.5) * distortion_strength * effect_weight);
	vec4 sprite_tex = texture(TEXTURE, warped_uv);
	
	// 5. Shimmer / Color Logic
	// The green shimmer only appears during the transition
	float shimmer_mask = noise_shimmer * effect_weight;
	vec3 final_rgb = mix(sprite_tex.rgb, cloak_color.rgb, shimmer_mask * edge_glow);
	
	// 6. Alpha Logic (The Fix)
	// First, define the base fade
	float alpha_fade = sprite_tex.a * cloak_alpha;
	
	// Second, define the "dissolve" during transition
	float dissolve = smoothstep(0.0, 0.2, noise_shimmer + (cloak_alpha * 0.5));
	
	// Combine them
	float final_a = alpha_fade * dissolve;
	
	// Add the shimmer/ghost, but ensure it is ALSO killed by cloak_alpha
	float energy_ghost = sprite_tex.a * shimmer_mask * 0.5 * cloak_alpha;
	
	// Final Alpha: Clamp and hard-force zero if cloak_alpha is zero
	COLOR = vec4(final_rgb, clamp(final_a + energy_ghost, 0.0, sprite_tex.a));
	
	// Hard cut-off to ensure performance and total invisibility
	if (cloak_alpha <= 0.0) {
		COLOR.a = 0.0;
	}
}