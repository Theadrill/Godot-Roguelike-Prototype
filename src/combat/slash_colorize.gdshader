shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.0;
uniform float brightness_boost : hint_range(0.0, 1.5) = 0.25;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 hot_tint = mix(tint_color.rgb, vec3(1.0), smoothstep(0.75, 1.0, lum) * 0.45);
	vec3 colored = hot_tint * clamp(lum * (1.0 + brightness_boost), 0.0, 1.35);
	vec3 final_rgb = mix(tex.rgb, colored, tint_strength);
	COLOR = vec4(final_rgb, tex.a) * COLOR;
}
