// Sfondo animato: mare notturno, nebbia e la rete rossa che cresce dal basso.
// "rosso" (0..1) è guidato dalla risonanza del giocatore: più la nave o la
// piattaforma ti entra dentro, più le venature salgono e pulsano.
shader_type canvas_item;

uniform vec3 col_alto : source_color = vec3(0.04, 0.055, 0.07);
uniform vec3 col_basso : source_color = vec3(0.012, 0.025, 0.035);
uniform vec3 col_nebbia : source_color = vec3(0.55, 0.62, 0.68);
uniform vec3 col_rosso : source_color = vec3(0.62, 0.1, 0.07);
uniform float rosso : hint_range(0.0, 1.0) = 0.0;
uniform float nebbia : hint_range(0.0, 1.0) = 0.5;
uniform float battito : hint_range(0.0, 1.0) = 0.0;
uniform float qualita : hint_range(0.0, 1.0) = 1.0;
uniform vec2 risoluzione = vec2(1280.0, 800.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float aspetto = risoluzione.x / max(risoluzione.y, 1.0);
	vec2 p = vec2(uv.x * aspetto, uv.y);
	float t = TIME * 0.025;

	// Cielo e mare.
	vec3 c = mix(col_alto, col_basso, smoothstep(0.0, 1.0, uv.y));
	float onda = sin(uv.x * 9.0 + TIME * 0.35 + sin(uv.y * 5.0 + TIME * 0.2)) * 0.5 + 0.5;
	c += col_nebbia * 0.012 * onda * smoothstep(0.55, 1.0, uv.y);

	// Nebbia che scorre.
	float f1 = fbm(p * 2.0 + vec2(t * 2.2, t * 0.6));
	float f2 = fbm(p * 3.7 - vec2(t * 1.4, -t));
	c += col_nebbia * nebbia * 0.10 * (f1 * 0.7 + f2 * 0.3);

	// La rete: venature ottenute da rumore deformato.
	vec2 w = vec2(fbm(p * 1.4 + t), fbm(p * 1.4 - t + 4.0));
	vec2 q = p * 3.2 + w * 1.6;
	float n = fbm(q + vec2(0.0, t * 0.7));
	float vena = pow(1.0 - abs(n * 2.0 - 1.0), 16.0);
	float vena2 = 0.0;
	if (qualita > 0.5) {
		float n2 = fbm(q * 2.2 + 3.0);
		vena2 = pow(1.0 - abs(n2 * 2.0 - 1.0), 20.0);
	}

	// Crescita dal basso: con rosso = 0 quasi nulla, con rosso = 1 ovunque.
	float soglia = mix(1.18, -0.45, rosso);
	float altezza = uv.y + (f1 - 0.5) * 0.5;
	float crescita = smoothstep(soglia, soglia + 0.35, altezza);

	float pulsa = 0.7 + 0.3 * sin(TIME * (1.0 + battito * 1.5) + n * 7.0);
	float r = (vena * 0.95 + vena2 * 0.6) * crescita * pulsa;
	c = mix(c, col_rosso * (0.8 + 0.4 * pulsa), clamp(r, 0.0, 1.0) * 0.9);
	c += col_rosso * crescita * 0.05 * rosso * pulsa;

	// Vignettatura e grana.
	vec2 d = uv - 0.5;
	float vig = smoothstep(0.9, 0.25, length(d * vec2(1.0, 1.15)));
	c *= mix(0.4, 1.0, vig);
	c += (hash(floor(uv * risoluzione) * 0.0173 + vec2(fract(TIME * 7.13) * 31.0, fract(TIME * 3.7) * 17.0)) - 0.5) * 0.02;

	COLOR = vec4(c, 1.0);
}
