shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Town ground after the selected references (G01-07, G01-09, G01-10):
// worn setts with trodden mud, brick-rubble grit, weedy edges and standing
// water. Layers are blended by world-space noise so no tiling seam lines up
// with the plot grid. All textures are CC0 Poly Haven scans.

uniform sampler2D cobble_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cobble_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cobble_rough : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D mud_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mud_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mud_rough : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D rubble_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rubble_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D large_noise : filter_linear, repeat_enable;
uniform sampler2D small_noise : filter_linear, repeat_enable;

uniform float cobble_tile = 2.2;
uniform float mud_tile = 3.2;
uniform float rubble_tile = 1.8;
uniform float grass_tile = 2.6;
uniform float mud_amount = 0.58;
uniform float rubble_amount = 0.05;
uniform float puddle_amount = 0.36;
uniform float grass_amount = 0.0;
// Town interior rectangle (xmin, zmin, xmax, zmax); grass creeps in near its
// edges and dominates outside it.
uniform vec4 town_rect = vec4(-64.0, -204.0, 64.0, 204.0);
uniform float edge_grass_width = 7.0;
uniform int debug_layers = 0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 unpack_normal(vec3 n) {
	return n;
}

void fragment() {
	vec2 p = world_pos.xz;
	float big = texture(large_noise, p / 70.0).r;
	float mid = texture(small_noise, p / 17.0).r;
	float fine = texture(small_noise, p / 5.3 + vec2(0.31, 0.77)).r;

	float mud_field = big * 0.55 + mid * 0.45;
	float mud = smoothstep(1.0 - mud_amount - 0.16, 1.0 - mud_amount + 0.16, mud_field);
	float rubble = smoothstep(1.0 - rubble_amount - 0.04, 1.0 - rubble_amount + 0.04, texture(small_noise, p / 5.0 + vec2(0.53, 0.19)).r) * (1.0 - mud * 0.6);
	float edge_dist = min(min(p.x - town_rect.x, town_rect.z - p.x), min(p.y - town_rect.y, town_rect.w - p.y));
	float grass = clamp(grass_amount + (1.0 - smoothstep(0.0, edge_grass_width, edge_dist)) * (0.55 + 0.45 * mid), 0.0, 1.0);
	grass = max(grass, step(edge_dist, 0.0));
	float puddle = mud * smoothstep(1.0 - puddle_amount, 1.0 - puddle_amount + 0.05, fine * 0.6 + mid * 0.4) * (1.0 - grass);

	vec3 c_alb = texture(cobble_albedo, p / cobble_tile).rgb;
	vec3 m_alb = texture(mud_albedo, p / mud_tile).rgb;
	vec3 r_alb = texture(rubble_albedo, p / rubble_tile).rgb;
	vec3 g_alb = texture(grass_albedo, p / grass_tile).rgb;
	vec3 c_nrm = texture(cobble_normal, p / cobble_tile).rgb;
	vec3 m_nrm = texture(mud_normal, p / mud_tile).rgb;
	vec3 r_nrm = texture(rubble_normal, p / rubble_tile).rgb;
	vec3 g_nrm = texture(grass_normal, p / grass_tile).rgb;
	float c_r = texture(cobble_rough, p / cobble_tile).g;
	float m_r = texture(mud_rough, p / mud_tile).g;

	// Mud settles in the gaps between setts before it covers them.
	float gap_fill = clamp(mud * 1.6 - (1.0 - c_alb.r * 1.4), 0.0, 1.0);
	float mud_w = max(mud * 0.8, gap_fill * 0.65);
	vec3 mud_col = mix(m_alb, vec3(dot(m_alb, vec3(0.3, 0.59, 0.11))), 0.45) * vec3(0.62, 0.58, 0.54);
	float cavity = smoothstep(0.18, 0.5, dot(c_alb, vec3(0.33)));
	vec3 cobble_col = c_alb * vec3(0.52, 0.5, 0.47) * mix(0.55, 1.0, cavity);
	vec3 albedo = mix(cobble_col, mud_col, mud_w);
	vec3 nrm = mix(c_nrm, m_nrm, mud_w);
	float rough = mix(c_r, m_r, mud_w);
	albedo = mix(albedo, mix(r_alb, vec3(dot(r_alb, vec3(0.33))), 0.45) * vec3(0.72, 0.64, 0.6), rubble);
	nrm = mix(nrm, r_nrm, rubble);
	rough = mix(rough, 0.95, rubble);
	albedo = mix(albedo, g_alb * vec3(0.78, 0.86, 0.66), grass);
	nrm = mix(nrm, g_nrm, grass);
	rough = mix(rough, 0.95, grass);
	// Standing water: darker, glossy, flat.
	albedo = mix(albedo, albedo * 0.38, puddle);
	rough = mix(rough, 0.04, puddle);
	nrm = mix(nrm, vec3(0.5, 0.5, 1.0), puddle * 0.9);
	// Low-frequency value variation breaks up tiling at distance.
	albedo *= mix(0.84, 1.08, big);

	ALBEDO = albedo;
	if (debug_layers == 1) { ALBEDO = vec3(mud, rubble, grass); }
	if (debug_layers == 2) { ALBEDO = vec3(puddle, big, mid); }
	NORMAL_MAP = nrm;
	NORMAL_MAP_DEPTH = 1.0;
	ROUGHNESS = rough;
	SPECULAR = 0.35;
}
