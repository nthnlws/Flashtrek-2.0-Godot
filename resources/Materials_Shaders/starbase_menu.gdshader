shader_type canvas_item;

// Uniforms for the 6 replacement colors
uniform vec4 color_1 : source_color = vec4(1.0); // Replaces Red
uniform vec4 color_2 : source_color = vec4(1.0); // Replaces Green
uniform vec4 color_3 : source_color = vec4(1.0); // Replaces Blue
uniform vec4 color_4 : source_color = vec4(1.0); // Replaces Yellow
uniform vec4 color_5 : source_color = vec4(1.0); // Replaces Cyan
uniform vec4 color_6 : source_color = vec4(1.0); // Replaces Magenta

void fragment() {
    vec4 mask = texture(TEXTURE, UV);
    vec3 out_rgb = mask.rgb;
    
    // We use a small epsilon to account for floating point errors
    float eps = 0.1;

    // Check for Red (1, 0, 0)
    if (mask.r > 1.0 - eps && mask.g < eps && mask.b < eps) {
        out_rgb = color_1.rgb;
    }
    // Check for Green (0, 1, 0)
    else if (mask.r < eps && mask.g > 1.0 - eps && mask.b < eps) {
        out_rgb = color_2.rgb;
    }
    // Check for Blue (0, 0, 1)
    else if (mask.r < eps && mask.g < eps && mask.b > 1.0 - eps) {
        out_rgb = color_3.rgb;
    }
    // Check for Yellow (1, 1, 0)
    else if (mask.r > 1.0 - eps && mask.g > 1.0 - eps && mask.b < eps) {
        out_rgb = color_4.rgb;
    }
    // Check for Cyan (0, 1, 1)
    else if (mask.r < eps && mask.g > 1.0 - eps && mask.b > 1.0 - eps) {
        out_rgb = color_5.rgb;
    }
    // Check for Magenta (1, 0, 1)
    else if (mask.r > 1.0 - eps && mask.g < eps && mask.b > 1.0 - eps) {
        out_rgb = color_6.rgb;
    }
    
    // Apply the final color with the original alpha channel
    COLOR = vec4(out_rgb, mask.a);
}