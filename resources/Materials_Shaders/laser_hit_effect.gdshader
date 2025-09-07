shader_type canvas_item;
render_mode blend_add;

uniform float energy = 40.0; // How much the beams ripple
uniform int roughness : hint_range(1, 10) = 3; 
uniform int frequency = 25; 
uniform float speed = 4.0; 
uniform vec2 noise_scale = vec2(0.4, 0.4); 

uniform vec4 color : source_color = vec4(0.91, 1.0, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(0.888, 0.362, 0.412, 1.0);

uniform float glow : hint_range(0.0, 3.0) = 0.0;
uniform float outline_glow : hint_range(0.0, 3.0) = 0.0;
uniform float progress : hint_range(0.0, 1.0) = 1.0;

//
// --- Noise Helpers ---
//
vec2 randomVec2(vec2 uv){
    uv = vec2(
        dot(uv, vec2(127.1,311.7)),
        dot(uv, vec2(269.5,183.3))
    );
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f*f*(3.0-2.0*f);

    return mix(
        mix(dot(randomVec2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
            dot(randomVec2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
        mix(dot(randomVec2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
            dot(randomVec2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
        u.y
    ) * 0.5 + 0.5;
}

float fbm(vec2 uv, float time) {
    int octaves = roughness;
    float amp = 0.01 * energy * progress;
    float freq = float(frequency);
    float value = 0.0;

    for(int i = 0; i < octaves; i++) {
        value += amp * noise(uv * freq + vec2(0.0, time));
        amp *= 0.5;
        freq *= 2.0;
    }
    return value;
}

vec4 difference(vec4 base, vec4 blend){
    return abs(base - blend);
}

//
// --- Energy Ball ---
//
void fragment() {
    vec2 center = vec2(0.5);
    float dist = distance(UV, center) / 0.5; // 0 at center, 1 at edge
    float radial = smoothstep(1.0, 0.0, dist); // falloff toward edges

    float time = TIME * speed;

    // Keep the beam-like noisy pattern
    vec4 clouds = vec4(fbm(UV * noise_scale, time));
    vec4 diff_clouds = difference(clouds, vec4(dist - 0.3));

    // Mix the main energy color and red “beam” outline
    vec4 core = diff_clouds * color;
    vec4 highlight = smoothstep(0.2, 0.8, diff_clouds) * outline_color;

    // Combine, weighted by radial fade + progress
    vec4 result = (core + highlight) * radial * progress;

    // Add HDR glow support
    result.rgb += glow * result.rgb;
    result.rgb += outline_glow * highlight.rgb;

    COLOR = result;
}
