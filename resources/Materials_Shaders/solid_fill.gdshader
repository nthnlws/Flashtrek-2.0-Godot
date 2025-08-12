// solid_fill.gdshader
shader_type canvas_item;

// This is the color we will fill the shape with.
// The 'source_color' hint gives us a nice color picker in the editor.
uniform vec4 fill_color : source_color = vec4(0.01, 0.01, 0.01, 0.5);

// This will be our main control slider in the AnimationPlayer (0.0 = normal, 1.0 = solid)
uniform float fill_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    // 1. Get the original color and shape from the sprite's texture.
    vec4 original_color = texture(TEXTURE, UV);

    // 2. Create the solid color version.
    // We use the RGB from our fill_color uniform.
    // The alpha is the original sprite's alpha multiplied by our fill_color's alpha.
    // This preserves the sprite's shape and anti-aliased edges.
    vec4 solid_version = vec4(fill_color.rgb, original_color.a * fill_color.a);

    // 3. Mix between the original sprite and the solid version using our control slider.
    vec4 final_color = mix(original_color, solid_version, fill_amount);

    // 4. Apply the final color.
    COLOR = final_color;
}