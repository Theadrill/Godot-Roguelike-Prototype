shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(0.58, 0.04, 0.05, 1.0);
uniform vec2 pixel_resolution = vec2(640.0, 360.0);
uniform float inner_radius : hint_range(0.0, 1.5) = 0.78;
uniform float outer_radius : hint_range(0.1, 2.0) = 1.12;
uniform float alpha : hint_range(0.0, 1.0) = 0.0;
uniform float dither_levels : hint_range(2.0, 8.0) = 4.0;

float bayer4x4(vec2 pos) {
	int x = int(mod(pos.x, 4.0));
	int y = int(mod(pos.y, 4.0));
	int idx = x + y * 4;
	if (idx == 0) return 0.0 / 16.0;
	if (idx == 1) return 8.0 / 16.0;
	if (idx == 2) return 2.0 / 16.0;
	if (idx == 3) return 10.0 / 16.0;
	if (idx == 4) return 12.0 / 16.0;
	if (idx == 5) return 4.0 / 16.0;
	if (idx == 6) return 14.0 / 16.0;
	if (idx == 7) return 6.0 / 16.0;
	if (idx == 8) return 3.0 / 16.0;
	if (idx == 9) return 11.0 / 16.0;
	if (idx == 10) return 1.0 / 16.0;
	if (idx == 11) return 9.0 / 16.0;
	if (idx == 12) return 15.0 / 16.0;
	if (idx == 13) return 7.0 / 16.0;
	if (idx == 14) return 13.0 / 16.0;
	return 5.0 / 16.0;
}

void fragment() {
	vec2 grid_pos = floor(UV * pixel_resolution);
	vec2 snapped_uv = (grid_pos + 0.5) / pixel_resolution;
	vec2 centered = (snapped_uv - 0.5) * 2.0;
	float dist = length(centered * vec2(1.0, 0.92));

	float mask = smoothstep(inner_radius, outer_radius, dist) * alpha;
	float threshold = bayer4x4(grid_pos) - 0.5;
	float quantized = clamp(floor(mask * dither_levels + 0.5 + threshold) / dither_levels, 0.0, 1.0);

	COLOR = vec4(vignette_color.rgb, quantized * vignette_color.a);
}
