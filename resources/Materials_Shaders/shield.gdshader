shader_type canvas_item;

uniform vec4 color: source_color = vec4(0.36, 0.527, 0.837, 1.0);

float circle(vec2 position, float radius, float feather)
{
	return smoothstep(radius, radius + feather, length(position - vec2(0.5)));
}


void fragment(){
	float outer = circle(UV, 0.455, 0.045); 
	float fade_effect = sin(TIME * 0.5) * 0.01;
	float inner = 1.0 - circle(UV, 0.357, 0.13 - fade_effect);
	
	COLOR.rgb = color.rgb;
	COLOR.a *= color.a - (outer + inner);
}