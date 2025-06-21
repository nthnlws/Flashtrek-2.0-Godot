shader_type canvas_item;
render_mode unshaded;

// --- Uniforms ---
uniform vec4 health_color : source_color = vec4(0.0, 1.0, 0.0, 1.0); // Green
uniform vec4 empty_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);  // Dark Grey/Black for empty
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // White
uniform float outline_width : hint_range(0.0, 5.0) = 1.0;
uniform float health_ratio : hint_range(0.0, 1.0) = 1.0;

uniform int fill_direction = 2;

// Uniforms for AtlasTexture region handling
uniform vec2 region_uv_offset = vec2(0.0, 0.0); // Default to full texture if not set
uniform vec2 region_uv_size = vec2(1.0, 1.0);   // Default to full texture if not set
// Uniforms for content bounds *within* the AtlasTexture region (normalized 0-1 relative to the region)
uniform vec2 content_bounds_in_region_uv_pos = vec2(0.0, 0.0); // Offset of content within region
uniform vec2 content_bounds_in_region_uv_size = vec2(1.0, 1.0); // Size of content within region

void fragment() {
    vec2 full_texture_uv = UV; // UVs for the entire base atlas texture

    // 1. Normalize UVs to be 0-1 within the specified AtlasTexture REGION
    vec2 uv_in_atlas_region;
    if (region_uv_size.x <= 0.00001 || region_uv_size.y <= 0.00001) {
        uv_in_atlas_region = vec2(2.0, 2.0); // Will be discarded
    } else {
        uv_in_atlas_region = (full_texture_uv - region_uv_offset) / region_uv_size;
    }

    // --- Atlas Region Culling ---
    if (uv_in_atlas_region.x < 0.0 || uv_in_atlas_region.x > 1.0 ||
        uv_in_atlas_region.y < 0.0 || uv_in_atlas_region.y > 1.0) {
        discard;
    }

    // --- Masking based on Texture Alpha (within the region) ---
    float mask_alpha = texture(TEXTURE, full_texture_uv).a;
    if (mask_alpha < 0.1) {
        discard;
    }

    // 2. Normalize UVs from "uv_in_atlas_region" to be 0-1 within the CONTENT BOUNDS
    vec2 local_uv_for_fill; // These are the UVs the fill logic will use
    if (content_bounds_in_region_uv_size.x <= 0.00001 || content_bounds_in_region_uv_size.y <= 0.00001) {
        // No content, or content bounds are invalid.
        local_uv_for_fill = vec2(2.0, 2.0); // Will make it appear as 'empty_color'
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
    // Only apply health fill if the pixel is *within* the 0-1 range of the content bounds UVs
    if (local_uv_for_fill.x >= 0.0 && local_uv_for_fill.x <= 1.0 &&
        local_uv_for_fill.y >= 0.0 && local_uv_for_fill.y <= 1.0) {
        if (current_uv_check_value <= health_ratio) {
            final_color_fill = health_color;
        } else {
            final_color_fill = empty_color;
        }
    } else {
        // Pixel is within atlas region, and has mask_alpha > 0.1, but outside content bounds.
        // Treat as empty part of the bar.
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
        // Optional diagonals
        float diag_w = w * 0.70710678118; float diag_h = h * 0.70710678118;
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv + vec2(diag_w, diag_h)).a);
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv - vec2(diag_w, diag_h)).a);
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv + vec2(diag_w, -diag_h)).a);
        max_neighbor_alpha_diff = max(max_neighbor_alpha_diff, mask_alpha - texture(TEXTURE, full_texture_uv - vec2(diag_w, -diag_h)).a);

        if (max_neighbor_alpha_diff > 0.5) {
            outline_effect = 1.0;
        }
    }

    // --- Combine Fill and Outline ---
    if (outline_effect > 0.5) {
        COLOR = mix(final_color_fill, outline_color, outline_color.a);
    } else {
        COLOR = final_color_fill;
    }
    COLOR.a *= mask_alpha; // Final alpha modulation
}