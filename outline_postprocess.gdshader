shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, cull_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float outline_thickness = 1.5;
uniform vec3 outline_color : source_color = vec3(0.1, 0.1, 0.1);
uniform float depth_threshold = 0.05;
uniform float normal_threshold = 0.5;
uniform float color_edge_fallback = 0.15;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 texel = 1.0 / VIEWPORT_SIZE;
	vec3 color = texture(screen_texture, uv).rgb;

	float outline = 0.0;

	if (outline_thickness > 0.0 && texel.x > 0.0 && texel.y > 0.0) {
		vec3 c0 = texture(screen_texture, uv).rgb;
		vec3 c1 = texture(screen_texture, uv + vec2(outline_thickness, 0.0) * texel).rgb;
		vec3 c2 = texture(screen_texture, uv + vec2(-outline_thickness, 0.0) * texel).rgb;
		vec3 c3 = texture(screen_texture, uv + vec2(0.0, outline_thickness) * texel).rgb;
		vec3 c4 = texture(screen_texture, uv + vec2(0.0, -outline_thickness) * texel).rgb;

		float lum0 = dot(c0, vec3(0.299, 0.587, 0.114));
		float lum1 = dot(c1, vec3(0.299, 0.587, 0.114));
		float lum2 = dot(c2, vec3(0.299, 0.587, 0.114));
		float lum3 = dot(c3, vec3(0.299, 0.587, 0.114));
		float lum4 = dot(c4, vec3(0.299, 0.587, 0.114));

		float diff = abs(lum0 - lum1) + abs(lum0 - lum2) + abs(lum0 - lum3) + abs(lum0 - lum4);
		if (diff > color_edge_fallback) {
			outline = 1.0;
		}
	}

	if (outline > 0.5) {
		ALBEDO = outline_color;
	} else {
		ALBEDO = color;
	}
}
