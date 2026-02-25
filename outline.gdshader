shader_type spatial;
render_mode unshaded, cull_front;

uniform float outline_thickness = 0.04;
uniform vec3 outline_color : source_color = vec3(0.1, 0.1, 0.1);

void vertex() {
	VERTEX += NORMAL * outline_thickness;
}

void fragment() {
	ALBEDO = outline_color;
}
