shader_type canvas_item;

uniform float blur_size : hint_range(0.0, 20.0) = 5.0;
uniform vec2 resolution;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
void fragment() {
    vec4 color = vec4(0.0);
    vec2 offset = blur_size / resolution;

    // Apply Gaussian blur
    float weight_sum = 0.0;
    float weights[5] = float[](0.227027, 0.316216, 0.070270, 0.316216, 0.227027);

    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            float weight = weights[abs(i) + abs(j)];
            vec2 sample_pos = SCREEN_UV + vec2(float(i), float(j)) * offset;
            color += texture(SCREEN_TEXTURE, sample_pos) * weight;
            weight_sum += weight;
        }
    }

    COLOR = color / weight_sum; // Normalize by the sum of weights
}
