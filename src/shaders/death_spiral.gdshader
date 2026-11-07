shader_type canvas_item;

// Efeito da Morte: Vórtice Espiral de Magia da Morte Perpétuo (Pilares 1 e 2)
// Verde-esmeralda espectral acinzentado rodopiando continuamente no plano liminar.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float vortex_time : hint_range(0.0, 100000.0) = 0.0;
uniform float spiral_arms : hint_range(1.0, 8.0) = 4.0;
uniform float spiral_speed : hint_range(0.5, 10.0) = 2.4;
uniform vec4 color_mist : source_color = vec4(0.18, 0.32, 0.26, 1.0);  // Verde-esmeralda espectral acinzentado
uniform vec4 color_edge : source_color = vec4(0.42, 0.74, 0.62, 1.0);  // Brilho místico das cristas da espiral
uniform vec4 color_void : source_color = vec4(0.03, 0.05, 0.04, 1.0);  // Abismo escuro da Morte

void fragment() {
	if (progress <= 0.0) {
		discard;
	}

	// Coordenadas centradas e corrigidas para aspect ratio 16:9 (640x360)
	vec2 p = UV - vec2(0.5);
	p.x *= 1.7777778;

	float dist = length(p);
	float angle = atan(p.y, p.x);

	// Raio de corte para expansão progressiva inicial (cobre todos os cantos da tela em 1.0)
	float max_radius = 1.35;
	float cutoff = progress * max_radius;

	// Tempo contínuo de rotação (alimentado via script ou fallback TIME)
	float current_time = vortex_time > 0.0 ? vortex_time : TIME;
	float spiral_twist = angle + log(max(dist, 0.001)) * 2.2 - current_time * spiral_speed;

	// Braços principais do vórtice em coordenadas logarítmicas
	float arm_wave = sin(spiral_twist * spiral_arms);
	float arm_factor = (arm_wave + 1.0) * 0.5;

	// Braços secundários e turbulência de névoa da morte
	float sub_arm = sin(spiral_twist * (spiral_arms * 2.0) + dist * 8.0 + current_time * 1.1);
	float mist_texture = arm_factor * 0.7 + (sub_arm + 1.0) * 0.15;

	// Distância espiral para que a frente de expansão avance girando
	float spiral_dist = dist - (1.0 - arm_factor) * 0.06;

	if (spiral_dist < cutoff) {
		// Brilho dinâmico na frente de expansão enquanto o vórtice engole a tela
		float edge_dist = cutoff - spiral_dist;
		float expansion_glow = smoothstep(0.09, 0.0, edge_dist) * (1.0 - progress);

		// Núcleo central escuro (olho do vórtice onde a alma é ancorada)
		float core_eye = smoothstep(0.03, 0.22, dist);

		// Composição da névoa esverdeada e vazio
		vec4 base_color = mix(color_void, color_mist, mist_texture * core_eye);

		// Realces espectrais nas cristas dos braços girando sem parar
		float crest_glow = pow(arm_factor, 2.8) * 0.42 * core_eye;
		vec4 final_color = mix(base_color, color_edge, clamp(expansion_glow + crest_glow, 0.0, 1.0));

		// Vinheta suave nas bordas para profundidade cinematográfica
		float vignette = smoothstep(1.3, 0.35, dist);
		COLOR = mix(color_void, final_color, vignette * 0.88 + 0.12);
	} else {
		discard;
	}
}
