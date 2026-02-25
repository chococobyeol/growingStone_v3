shader_type spatial;
render_mode diffuse_toon, specular_toon, cull_back;

uniform vec3 base_color : source_color = vec3(0.9, 0.88, 0.85);
uniform vec3 light_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 shadow_color : source_color = vec3(0.7, 0.65, 0.6);

uniform float cloudiness : hint_range(0.0, 1.0) = 0.0;
uniform float grain_size : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 123.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453123);
}

void fragment() {
	vec3 final_albedo = mix(base_color, vec3(0.85, 0.85, 0.85), cloudiness * 0.5);
	if (grain_size > 0.05) {
		float n = hash(UV * 100.0);
		final_albedo *= mix(1.0, 0.8 + n * 0.4, grain_size);
		vec3 bump = vec3(n - 0.5, n - 0.5, n - 0.5) * grain_size * 0.6;
		NORMAL = normalize(NORMAL + bump);
	}
	ALBEDO = final_albedo;
}

void light() {
	float dot_nl = dot(NORMAL, LIGHT);
	float diff = smoothstep(-0.02, 0.02, dot_nl);

	vec3 current_shadow = mix(shadow_color, base_color * 0.8, cloudiness);
	vec3 out_color = mix(current_shadow, base_color, diff);

	if (dot_nl > 0.8 && cloudiness < 0.5 && grain_size < 0.3) {
		out_color = light_color;
	}

	DIFFUSE_LIGHT += out_color * ATTENUATION * LIGHT_COLOR;
}
