shader_type canvas_item;

uniform vec4 white_replace_color : source_color = vec4(0.3, 0.4, 0.9, 1.0);
uniform vec4 red_replace_color : source_color = vec4(1.0, 0.7, 0.2, 1.0);
uniform float tolerance : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec3 current_color = COLOR.rgb;
    
    float dist_white = distance(current_color, vec3(1.0, 1.0, 1.0));
    float dist_red = distance(current_color, vec3(1.0, 0.0, 0.0));

    if (dist_white < tolerance) {
        COLOR.rgb = white_replace_color.rgb;
    } 
    else if (dist_red < tolerance) {
        COLOR.rgb = red_replace_color.rgb;
    }
}