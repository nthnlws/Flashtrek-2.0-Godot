shader_type canvas_item;
render_mode unshaded;

// --- Uniforms ---
// New color uniforms for the gradient
uniform vec4 high_health_color : source_color = vec4(0.0, 1.0, 0.0, 1.0); // Green
uniform vec4 mid_health_color : source_color = vec4(1.0, 0.65, 0.0, 1.0); // Orange
uniform vec4 low_health_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);  // Red
uniform float mid_health_threshold : hint_range(0.0, 1.0) = 0.6; // The point where color changes from green

uniform vec4 empty_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);  // Dark Grey/Black for empty
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // White
uniform float outline_width : hint_range(0.0, 5.0) = 1.0;
uniform float health_ratio : hint_range(0.0, 1.0) = 1.0;

uniform int fill_direction = 2;

// Uniforms for AtlasTexture region handling
uniform vec2 region_uv_offset = vec2(0.0, 0.0);
uniform vec2 region_uv_size = vec2(1.0, 1.0);
uniform vec2 content_bounds_in_region_uv_pos = vec2(0.0, 0.0);
uniform vec2 content_bounds_in_region_uv_size = vec2(1.0, 1.0);

void fragment() {
    vec2 full_texture_uv = UV;

    // 1. Normalize UVs to be 0-1 within the specified AtlasTexture REGION
    vec2 uv_in_atlas_region;
    if (region_uv_size.x <= 0.00001 || region_uv_size.y <= 0.00001) {
        uv_in_atlas_region = vec2(2.0, 2.0);
    } else {
        uv_in_atlas_region = (full_texture_uv - region_uv_offset) / region_uv_size;
    }

    // --- Atlas Region Culling ---
    if (uv_in_atlas_region.x < 0.0 || uv_in_atlas_region.x > 1.0 ||
        uv_in_atlas_region.y < 0.0 || uv_in_atlas_region.y > 1.0) {
        discard;
    }

    // --- Masking based on Texture Alpha ---
    float mask_alpha = texture(TEXTURE, full_texture_uv).a;
    if (mask_alpha < 0.1) {
        discard;
    }

    // 2. Normalize UVs to be 0-1 within the CONTENT BOUNDS
    vec2 local_uv_for_fill;
    if (content_bounds_in_region_uv_size.x <= 0.00001 || content_bounds_in_region_uv_size.y <= 0.00001) {
        local_uv_for_fill = vec2(2.0, 2.0);
    } else {
        local_uv_for_fill = (uv_in_atlas_region - content_bounds_in_region_uv_pos) / content_bounds_in_region_uv_size;
    }

    // --- Health Fill Logic (using local_uv_for_fill) ---
    float current_uv_check_value;
    if (fill_direction == 0) { current_uv_check_value = 1.0 - local_uv_for_fill.y; }
    else if (fill_direction == 1) { current_uv_check_value = local_uv_for_fill.y; }
    else if (fill_direction == 2) { current_uv_check_value = local_uv_for_fill.x; }
    else { current_uv_check_value = 1.0 - local_uv_for_fill.x; }

    vec4 final_color_fill;
    if (local_uv_for_fill.x >= 0.0 && local_uv_for_fill.x <= 1.0 &&
        local_uv_for_fill.y >= 0.0 && local_uv_for_fill.y <= 1.0) {
        if (current_uv_check_value <= health_ratio) {
            
            // --- COLOR LOGIC ---
            vec4 current_health_color;
            if (health_ratio > mid_health_threshold) {
                // Above the threshold, the color is solid green.
                current_health_color = high_health_color;
            } else {
                // Below the threshold, fade from Orange (at the threshold) to Red (at 0).
                // We need to remap the health_ratio from the range [0.0, mid_health_threshold]
                // to a new range of [0.0, 1.0] to use in the mix() function.
                float transition_progress = health_ratio / mid_health_threshold;
                
                // mix() blends from the first color to the second based on the third argument.
                // When transition_progress is 0 (health is 0), we get low_health_color (Red).
                // When transition_progress is 1 (health is at the threshold), we get mid_health_color (Orange).
                current_health_color = mix(low_health_color, mid_health_color, transition_progress);
            }
            final_color_fill = current_health_color;
            
        } else {
            final_color_fill = empty_color;
        }
    } else {
        final_color_fill = empty_color;
    }

    // --- Outline Logic ---
    float outline_effect = 0.0;
    if (outline_width > 0.0) {
        vec2 base_pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
        float w = outline_width * base_pixel_size.x;
        float h = outline_width * base_pixel_size.y;
        float max_neighbor_alpha_diff = 0.0;
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv + vec2(w, 0.0)).a);
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv - vec2(w, 0.0)).a);
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv + vec2(0.0, h)).a);
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv - vec2(0.0, h)).a);
        float diag_w = w * 0.707; float diag_h = h * 0.707;
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv + vec2(diag_w, diag_h)).a);
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv - vec2(diag_w, diag_h)).a);
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv + vec2(diag_w, -diag_h)).a);
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv - vec2(diag_w, -diag_h)).a);
        if (max_neighbor_alpha_diff > 0.5) {
            outline_effect = 1.0;
        }
    }

    // --- Combine Fill and Outline (Unchanged) ---
    if (outline_effect > 0.5) {
        COLOR = mix(final_color_fill, outline_color, outline_color.a);
    } else {
        COLOR = final_color_fill;
    }
    COLOR.a *= mask_alpha;
}