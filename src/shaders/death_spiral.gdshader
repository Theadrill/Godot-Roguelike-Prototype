shader_type canvas_item;

// Efeito de Transição da Morte: Vórtice Espiral de Magia da Morte (Pilar 1 e 2)
// Verde-esmeralda espectral acinzentado da Morte rodopiando e engolindo a tela.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float spiral_arms : hint_range(1.0, 8.0) = 4.0;
uniform float spiral_speed : hint_range(0.5, 10.0) = 3.5;
uniform vec4 color_mist : source_color = vec4(0.16, 0.28, 0.24, 1.0);  // Verde espectral acinzentado
uniform vec4 color_edge : source_color = vec4(0.35, 0.65, 0.54, 1.0);  // Brilho místico das bordas da espiral
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

	// Curvatura espiral em coordenadas polares
	float spiral_coord = dist - (angle / (2.0 * 3.14159265)) * 0.25;
	float arm_wave = sin(angle * spiral_arms + dist * 16.0 - TIME * spiral_speed);
	float arm_factor = (arm_wave + 1.0) * 0.5;

	// Limite dinâmico de expansão do vórtice (cobre até os cantos da tela em 1.0)
	float max_radius = 1.15;
	float cutoff = progress * max_radius;

	// Distância ajustada pela espiral para que a borda feche em vórtice
	float spiral_dist = dist + (1.0 - arm_factor) * 0.08;

	if (spiral_dist < cutoff) {
		// Calcula proximidade da borda frontal do vórtice para criar o anel de brilho
		float edge_dist = cutoff - spiral_dist;
		float edge_glow = smoothstep(0.08, 0.0, edge_dist) * (1.0 - progress * 0.6);

		// Mistura a névoa esverdeada com o fundo escuro do vazio
		vec4 base_color = mix(color_void, color_mist, arm_factor * 0.65 + 0.35);
		vec4 final_color = mix(base_color, color_edge, edge_glow * 0.85);

		// Nos momentos finais (progress >= 0.85), escurece suavemente para o breu completo
		float blackout = smoothstep(0.85, 1.0, progress);
		COLOR = mix(final_color, color_void, blackout);
	} else {
		discard;
	}
}
