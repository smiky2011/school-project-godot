extends RefCounted

# Builds the blended ground ShaderMaterial (scripts/world/town_ground.gdshader).

const PBR := preload("res://scripts/world/pbr_library.gd")
const SHADER: Shader = preload("res://scripts/world/town_ground.gdshader")

static var _noise_large: Texture2D
static var _noise_small: Texture2D


static func make_material(grass_amount: float = 0.0, mud_amount: float = 0.58) -> ShaderMaterial:
	if _noise_large == null:
		_noise_large = _noise(0.012, 3, 7)
		_noise_small = _noise(0.03, 4, 19)
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("cobble_albedo", PBR.texture("cobblestone_floor_03", "diff"))
	m.set_shader_parameter("cobble_normal", PBR.texture("cobblestone_floor_03", "nor_gl"))
	m.set_shader_parameter("cobble_rough", PBR.texture("cobblestone_floor_03", "rough"))
	m.set_shader_parameter("mud_albedo", PBR.texture("brown_mud_02", "diff"))
	m.set_shader_parameter("mud_normal", PBR.texture("brown_mud_02", "nor_gl"))
	m.set_shader_parameter("mud_rough", PBR.texture("brown_mud_02", "rough"))
	m.set_shader_parameter("rubble_albedo", PBR.texture("brick_gravel", "diff"))
	m.set_shader_parameter("rubble_normal", PBR.texture("brick_gravel", "nor_gl"))
	m.set_shader_parameter("grass_albedo", PBR.texture("leafy_grass", "diff"))
	m.set_shader_parameter("grass_normal", PBR.texture("leafy_grass", "nor_gl"))
	m.set_shader_parameter("large_noise", _noise_large)
	m.set_shader_parameter("small_noise", _noise_small)
	m.set_shader_parameter("grass_amount", grass_amount)
	m.set_shader_parameter("mud_amount", mud_amount)
	return m


static func _noise(frequency: float, octaves: int, seed_value: int) -> Texture2D:
	# Baked synchronously: NoiseTexture2D generates on a thread and can be
	# sampled before it is ready, which read as solid white (all mud).
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var image := noise.get_seamless_image(512, 512, false, false, 0.1, true)
	image.convert(Image.FORMAT_L8)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
