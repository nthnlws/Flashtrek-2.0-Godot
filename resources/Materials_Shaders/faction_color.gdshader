shader_type canvas_item;

// Use a hint to make sure the mask is treated as a texture with transparency
uniform sampler2D mask_texture : source_color, hint_default_transparent;
uniform vec4 faction_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 stripe_color  : source_color = vec4(1.0, 1.0, 1.0, 0.25);
uniform float stripe_speed   = 0.5;
uniform float stripe_spacing = 40.0;
uniform float stripe_width   = 0.2;

void fragment() {
    // --- CHANGE 1: Sample the ALPHA channel (.a) of the mask ---
    // For a PNG mask, the shape is defined by its transparency, not its color.
    float mask = texture(mask_texture, UV).a;

    // Base fill
    vec4 base = faction_color;

    // Screen coordinates for consistent stripe movement
    vec2 uv_screen = FRAGCOORD.xy;

    // Rotate UV for diagonal stripes (-45 degrees)
    mat2 rot = mat2(vec2(0.7071, 0.7071),
                    vec2(-0.7071, 0.7071));
    uv_screen = rot * uv_screen;

    // Animate stripes
    uv_screen.x += TIME * stripe_speed * stripe_spacing;

    // Stripe pattern
    float stripe_pattern = step(1.0 - stripe_width, fract(uv_screen.x / stripe_spacing));

    // Mix colors
    vec4 final_color = mix(base, stripe_color, stripe_pattern);

    // --- CHANGE 2: Apply the mask to the alpha channel directly ---
    // This is a more explicit and robust way to apply a mask.
    COLOR.rgb = final_color.rgb;
    COLOR.a = final_color.a * mask;
}