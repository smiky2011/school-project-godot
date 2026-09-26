extends RefCounted

# Lighting and atmosphere tuned toward the selected Hell Let Loose references
# (G01-07..G01-12): a hard sun under broken cumulus, dark contact shadows,
# filmic tone mapping, aerial haze and distant smoke. The sun direction is
# derived from the HDRI's brightest pixel so sky and shadows agree.

const SKY_HDR: Texture2D = preload("res://assets/vendor/polyhaven_cc0/hdri/kloofendal_38d_partly_cloudy_puresky/kloofendal_38d_partly_cloudy_puresky_2k.hdr")
# Sun in the HDRI: brightest pixel at u=0.5996, v=0.2891 (38 degrees up, for
# long raking shadows like G01-10).
# Godot samples panoramas at u = atan2(x, -z) / TAU, v = acos(y) / PI, and a
# positive sky yaw turns the sun the same way as Vector3.rotated(UP, yaw);
# both were verified by rendering the sky at the computed direction.
const SUN_U := 0.5996
const SUN_V := 0.2891
# Sky yaw chosen so light arrives from the south-west across the N-S streets.
const SKY_YAW_DEG := -19.0


static func sun_direction() -> Vector3:
	# Direction toward the sun in world space for the rotated panorama.
	var theta := SUN_U * TAU
	var phi := SUN_V * PI
	var toward := Vector3(sin(theta) * sin(phi), cos(phi), -cos(theta) * sin(phi))
	return toward.rotated(Vector3.UP, deg_to_rad(SKY_YAW_DEG)).normalized()


static func build(parent: Node3D) -> void:
	var world := WorldEnvironment.new()
	world.name = "Broken cumulus daylight"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = SKY_HDR
	panorama.energy_multiplier = 1.0
	sky.sky_material = panorama
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	environment.sky = sky
	environment.sky_rotation = Vector3(0.0, deg_to_rad(SKY_YAW_DEG), 0.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.55
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.05
	environment.tonemap_white = 12.0
	environment.ssao_enabled = true
	environment.ssao_radius = 1.6
	environment.ssao_intensity = 2.2
	environment.ssao_power = 1.6
	environment.ssao_detail = 0.6
	environment.ssao_horizon = 0.06
	environment.ssil_enabled = true
	environment.ssil_radius = 4.0
	environment.ssil_intensity = 0.9
	environment.ssr_enabled = true
	environment.ssr_max_steps = 48
	environment.ssr_fade_in = 0.12
	environment.ssr_fade_out = 2.5
	environment.ssr_depth_tolerance = 0.25
	environment.glow_enabled = true
	environment.glow_intensity = 0.35
	environment.glow_bloom = 0.04
	environment.glow_hdr_threshold = 1.4
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_light_color = Color(0.62, 0.66, 0.7)
	environment.fog_light_energy = 0.9
	environment.fog_sun_scatter = 0.25
	environment.fog_density = 0.0011
	environment.fog_aerial_perspective = 0.4
	environment.fog_sky_affect = 0.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.86
	environment.adjustment_contrast = 1.06
	world.environment = environment
	parent.add_child(world)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	var toward := sun_direction()
	sun.basis = Basis.looking_at(-toward, Vector3.UP if absf(toward.y) < 0.99 else Vector3.FORWARD)
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_energy = 2.6
	# Default shadow bias. Larger normal bias, blur and angular size
	# (PCSS) erased the near-field building shadows on this scene.
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 140.0
	sun.directional_shadow_split_1 = 0.06
	sun.directional_shadow_split_2 = 0.18
	sun.directional_shadow_split_3 = 0.45
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_fade_start = 0.85
	parent.add_child(sun)
