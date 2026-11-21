shader_type canvas_item;

varying vec2 v_local_pos;

// ==========================================
// 1. EFEITO DE DANO (HIT FLASH)
// ==========================================
group_uniforms hit_flash;
uniform bool flash_active = false;
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// ==========================================
// 2. EFEITO DE MORTE (PIXEL DISSOLVE 2 TONS)
// ==========================================
group_uniforms dissolve;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_texture : source_color, filter_nearest, repeat_enable;
uniform float burn_size : hint_range(0.0, 0.25) = 0.12;
uniform float ash_size : hint_range(0.0, 0.25) = 0.08;
uniform vec4 burn_color : source_color = vec4(0.35, 0.92, 0.68, 1.0);
uniform vec4 ash_color : source_color = vec4(0.04, 0.14, 0.11, 1.0);

void vertex() {
	v_local_pos = VERTEX;
}

void fragment() {
	vec4 base_color = COLOR;
	if (base_color.a <= 0.0) {
		COLOR = base_color;
	} else {
		float eff_flash = flash_active ? 1.0 : flash_intensity;
		vec3 final_rgb = mix(base_color.rgb, flash_color.rgb, clamp(eff_flash, 0.0, 1.0));
		float final_alpha = base_color.a;

		// Só calcula a dissolução quando iniciada (custo zero em combate normal)
		if (dissolve_amount > 0.0) {
			vec2 tex_size = max(vec2(textureSize(noise_texture, 0)), vec2(1.0));
			vec2 pixel_uv = fract(floor(v_local_pos) / tex_size);
			float noise_val = texture(noise_texture, pixel_uv).r;
			float total_edge = burn_size + ash_size;
			float threshold = dissolve_amount * (1.0 + total_edge);
			if (noise_val < threshold - total_edge) {
				final_alpha = 0.0;
			} else if (noise_val < threshold - ash_size) {
				final_rgb = burn_color.rgb;
			} else if (noise_val < threshold) {
				final_rgb = mix(base_color.rgb, ash_color.rgb, 0.85);
			}
		}

		COLOR = vec4(final_rgb, final_alpha);
	}
}
