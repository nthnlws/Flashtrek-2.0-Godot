shader_type canvas_item;

group_uniforms Sine;
uniform bool do_abs;
uniform bool do_quantize;
uniform float quantize_to : hint_range(0, 2, 0.1) = 1;
uniform vec2 sine_amplitude = vec2(0.0, 35.0);
uniform vec2 sine_speed = vec2(0.0, 2.5);

void vertex() {
	vec2 s = sin(TIME * sine_speed);
	if (do_abs) {
		s = abs(s);
	}
	VERTEX += s * sine_amplitude;
	if (do_quantize) {
		VERTEX = round(VERTEX / quantize_to);
		VERTEX *= quantize_to;
	}
}