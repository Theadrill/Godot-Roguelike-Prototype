shader_type canvas_item;

uniform bool flash_active = false;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 base_color = COLOR;
	if (flash_active) {
		COLOR = vec4(flash_color.rgb, base_color.a * flash_color.a);
	} else {
		COLOR = base_color;
	}
}
