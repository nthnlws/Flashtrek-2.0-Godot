shader_type canvas_item;

// --- Particle Shape and Count ---
uniform int star_count = 200;
uniform int arms = 100;
uniform float particle_size = 1.5;

// --- Color Gradient ---
uniform bool use_white_color = false;
uniform vec4 color_a : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform vec4 color_b : source_color = vec4(0.53, 0.81, 0.92, 1.0);
uniform float gradient_speed = 5.3;

// --- Animation Physics ---
uniform float world_scale = 400.0;
uniform float theta = 80.0;
uniform float centerArea = 85.0;
uniform float scale_x = 0.01;
uniform float stretch = 1.4;
uniform float speed = 20;
uniform float modTime = 20.0;

uniform vec2 rect_size;

void fragment() {
vec2 world_pos = (UV - 0.5) * rect_size;
float pixel_dist = length(world_pos);

float min_dist = 9999.0;
vec4 closest_color = vec4(0.0);

float time_offset = 13.0 + (TIME * speed);
float tan_theta = tan(radians(theta));
float scale_stretch = scale_x * stretch;
float center_scale = centerArea * scale_x;

// Safety check to prevent divide-by-zero crashes
if (scale_stretch <= 0.0 || modTime <= 0.0) {
    COLOR = vec4(0.0);
} else {
    for (int j = 1; j <= arms; j++) {
        vec2 seed_input = vec2(2.0 - float(j), float(j) * 37.0);
        float current_seed = fract(sin(dot(seed_input, vec2(12.9898, 78.233))) * 46751.5453);
        float alpha = current_seed * TAU;
        vec2 arm_dir = vec2(cos(alpha), sin(alpha));
        
        // 1. Broad Phase: Is pixel near this arm's line?
        float dot_prod = dot(world_pos, arm_dir);
        if (dot_prod < 0.0) continue; 
        
        vec2 proj = dot_prod * arm_dir;
        float dist_to_line = length(world_pos - proj);
        if (dist_to_line > particle_size + 1.0) continue; 
        
        // 2. Narrow Phase
        float progress_j_base = time_offset + (float(arms) / float(j)) * 10.0;
        float r = pixel_dist / world_scale; 
        float z_approx = (r - center_scale) / tan_theta;
        float z_mod_approx = z_approx / scale_x;
        
        // DYNAMIC WRAP CALCULATION:
        // Calculate exactly which "wraps" are actively visible over this pixel 
        // right now, no matter how high TIME gets.
        float base_offset = progress_j_base - z_mod_approx;
        int n_start = int(floor(base_offset / modTime));
        int n_end   = int(ceil((base_offset + float(star_count) * scale_stretch) / modTime));
        
        // Loop over only the active wraps (usually this only loops 1 or 2 times!)
        int loop_limit = 0;
        for (int n = n_start; n <= n_end; n++) {
            if (loop_limit++ > 40) break; // GPU safety fallback
            
            float target_V = z_mod_approx + float(n) * modTime;
            float float_i = (target_V - progress_j_base) / scale_stretch;
            int i = int(round(float_i));
            
            if (i >= 0 && i < star_count) {
                float base_prog = progress_j_base + float(i) * scale_stretch;
                float exact_z_mod = mod(base_prog, modTime);
                float exact_H = center_scale + exact_z_mod * scale_x * tan_theta;
                vec2 exact_pos = exact_H * world_scale * arm_dir;
                
                float d = length(world_pos - exact_pos);
                if (d < min_dist) {
                    min_dist = d;
                    
                    if (use_white_color) {
                        closest_color = vec4(1.0);
                    } else {
                        float normalized_progress = exact_z_mod / modTime;
                        float mix_factor = clamp(normalized_progress * gradient_speed, 0.0, 1.0);
                        closest_color = mix(color_a, color_b, mix_factor);
                    }
                }
            }
        }
    }

    // 3. Render pixel
    if (min_dist <= particle_size) {
        // Smooth anti-aliased edges
        float alpha = smoothstep(particle_size, max(0.0, particle_size - 1.0), min_dist);
        COLOR = closest_color;
        COLOR.a *= alpha;
    } else {
        COLOR = vec4(0.0);
    }
}

}