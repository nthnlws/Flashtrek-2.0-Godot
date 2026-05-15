shader_type canvas_item;
// --- Cloak Controls ---
uniform float cloak_alpha : hint_range(0.0, 1.0) = 1.0; 
uniform int direction : hint_enum("Up,Down,Left,Right") = 0;
// --- Speed Controls ---
uniform float noise_speed = 0.05;      
uniform float distortion_speed = 0.15; 
// --- Visual Style ---
uniform vec4 cloak_color : source_color = vec4(0.0, 1.0, 0.5, 1.0); 
uniform float distortion_strength : hint_range(0.05, 0.4) = 0.1;
uniform float edge_glow : hint_range(0.0, 2.0) = 0.8;
// --- Texture ---
uniform sampler2D noise_texture : repeat_enable;
// --- Region Clamp ---
uniform vec2 region_uv_min = vec2(48.0, 48.0);
const vec2 REGION_SIZE = vec2(48.0 / 336.0, 48.0 / 672.0);

void fragment() {
	// 0. Convert atlas UV → local UV (0.0 to 1.0)
	vec2 local_uv = (UV - region_uv_min) / REGION_SIZE;

	// 1. Directional Movement
	vec2 move_dir = vec2(0.0);
	if (direction == 0) move_dir = vec2(0.0, -1.0);
	else if (direction == 1) move_dir = vec2(0.0, 1.0);
	else if (direction == 2) move_dir = vec2(-1.0, 0.0);
	else if (direction == 3) move_dir = vec2(1.0, 0.0);

	// 2. Separate UVs (local space for noise)
	vec2 noise_uv = local_uv + (move_dir * TIME * noise_speed);
	vec2 dist_uv  = local_uv + (move_dir * TIME * distortion_speed);

	// 3. Sample Noise
	float noise_shimmer = texture(noise_texture, noise_uv).r;
	vec2  noise_distort = texture(noise_texture, dist_uv).gb;

	// 4. Distortion in local space
	float effect_weight = sin(cloak_alpha * PI);
	vec2 warped_local   = local_uv + ((noise_distort - 0.5) * distortion_strength * effect_weight);

	// 5. Remap warped local UV into atlas space and clamp to region
	vec2 global_uv = region_uv_min + (warped_local * REGION_SIZE);
	global_uv = clamp(global_uv, region_uv_min, region_uv_min + REGION_SIZE);
	vec4 sprite_tex = texture(TEXTURE, global_uv);

	// 6. Shimmer / Color Logic
	float shimmer_mask = noise_shimmer * effect_weight;
	vec3 final_rgb = mix(sprite_tex.rgb, cloak_color.rgb, shimmer_mask * edge_glow);

	// 7. Alpha Logic
	float alpha_fade = sprite_tex.a * cloak_alpha;
	float dissolve = smoothstep(0.0, 0.2, noise_shimmer + (cloak_alpha * 0.5));
	float final_a = alpha_fade * dissolve;
	float energy_ghost = sprite_tex.a * shimmer_mask * 0.5 * cloak_alpha;
	COLOR = vec4(final_rgb, clamp(final_a + energy_ghost, 0.0, sprite_tex.a));

	// 8. Hard cut-off for total invisibility
	if (cloak_alpha <= 0.0) {
		COLOR.a = 0.0;
	}
}