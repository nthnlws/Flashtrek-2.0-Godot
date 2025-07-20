shader_type canvas_item;

uniform bool hasNeonEffect = true;
uniform bool hasDot = false;
uniform bool haszExpend = false;

uniform float theta: hint_range(0.0, 80.0, 0.1) = 80.;
uniform float addH: hint_range(0.0, 150.0, 1.0) = 135;
uniform float scale: hint_range(0.001, 0.01, 0.001) = 0.01;

uniform float light_disperse: hint_range(0.1, 10, 0.1) = 2;
uniform float stertch: hint_range(1, 1000, 0.1) = 30;
uniform float speed: hint_range(-50, 50, 0.1) = 10;
uniform float modTime: hint_range(1, 50, 0.1) = 20;
uniform bool iswhite;

uniform vec4 color_a : source_color = vec4(1.0, 0.0, 1.0, 1.0); // Magenta
uniform vec4 color_b : source_color = vec4(0.0, 1.0, 1.0, 1.0); // Cyan
uniform float gradient_speed : hint_range(0.1, 10.0, 0.1) = 1.0; // For time-based cycling

uniform int m = 8;
uniform int n = 30;

float random (vec2 uv) {
	return fract(sin(dot(uv.xy,
		vec2(12.9898,78.233))) * 46751.5453123);
}

void fragment() {
    COLOR = vec4(0.);
    vec2 suv = (UV - 0.5)*2.;

    for (int j = 0; j < n && (hasDot || hasNeonEffect); j++) {
        float seed = random(vec2(2.-float(j),float(j)*37.));
        for (int i = 0; i < m; i++) {
            // This base value determines the particle's raw progress before wrapping and scaling
            float base_progress_value = 5. + float(n)/float(j)*10. + TIME*speed + 8. + float(i)*scale*stertch;

            float z_mod_cycle = mod(base_progress_value, modTime); // Progress within the current 0 to modTime cycle
            float z = z_mod_cycle * scale; // Actual z used for drawing

            float aphla = seed*TAU;
            float H = addH*scale + z*tan(theta/180.*PI);
            float zscale = haszExpend ? min(z + 0.06,modTime)*scale*modTime*0.5 : scale;
            vec2 nuv = vec2(H*cos(aphla), H*sin(aphla));

            if (hasNeonEffect) {
                float l = max(exp(-(distance(suv/zscale, nuv/zscale)/light_disperse)), 0.);
                vec4 L;
                if (iswhite) {
                    L = vec4(l);
                } else {
                    // Normalized progress of the particle within its current cycle (0.0 to 1.0)
                    // This is 0 when the particle "appears" or "recycles" at the near end.
                    float normalized_progress = z_mod_cycle / modTime;

                    // Mix factor from 0 (color_a) to 1 (color_b)
                    // It clamps at 1, so once it reaches color_b, it stays there for the rest of its cycle.
                    // A higher gradient_speed makes the transition complete earlier in the cycle.
                    float mix_factor = clamp(normalized_progress * gradient_speed, 0.0, 1.0);

                    // Alternative: Smoother transition
                    // float transition_endpoint = 1.0 / max(gradient_speed, 0.01); // Avoid division by zero
                    // float mix_factor = smoothstep(0.0, clamp(transition_endpoint, 0.001, 1.0 / 0.01), normalized_progress);


                    vec3 mixed_rgb = mix(color_a.rgb, color_b.rgb, mix_factor);
                    // You can also mix alpha if color_a and color_b have different alphas
                    float mixed_alpha = mix(color_a.a, color_b.a, mix_factor);

                    L = vec4(mixed_rgb * l, mixed_alpha * l);
                }
                COLOR = min(COLOR + L, vec4(1.));
            }

            if (distance(suv, nuv) < 1.*zscale && hasDot) {
                COLOR = vec4(1.);
            }
        }
    }
}