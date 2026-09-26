extends RefCounted

# Cached PBR materials built from the CC0 Poly Haven textures fetched by
# tools/art/fetch_polyhaven.py (see each folder's PROVENANCE.json).

const TEXTURE_ROOT := "res://assets/vendor/polyhaven_cc0/texture/"
const MODEL_ROOT := "res://assets/vendor/polyhaven_cc0/model/"

static var _materials: Dictionary = {}
static var _scenes: Dictionary = {}


static func texture(id: String, suffix: String) -> Texture2D:
	for ext in ["jpg", "png"]:
		var path := "%s%s/%s_%s_1k.%s" % [TEXTURE_ROOT, id, id, suffix, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null


static func material(id: String, meters_per_tile: float = 2.0, tint: Color = Color.WHITE, triplanar: bool = true, key_suffix: String = "") -> StandardMaterial3D:
	var key := "%s|%s|%s|%s|%s" % [id, meters_per_tile, tint.to_html(), triplanar, key_suffix]
	if _materials.has(key):
		return _materials[key]
	if id == "cobblestone_floor_001_flags":
		# Larger pale setts from the earlier CC0 import read as pavement.
		var f := StandardMaterial3D.new()
		f.albedo_texture = load("res://assets/vendor/environment_visual/polyhaven/cobblestone_floor_001/cobblestone_floor_001_diff_1k.jpg")
		f.albedo_color = Color(0.62, 0.61, 0.58)
		f.normal_enabled = true
		f.normal_texture = load("res://assets/vendor/environment_visual/polyhaven/cobblestone_floor_001/cobblestone_floor_001_nor_gl_1k.png")
		f.roughness_texture = load("res://assets/vendor/environment_visual/polyhaven/cobblestone_floor_001/cobblestone_floor_001_rough_1k.png")
		f.uv1_triplanar = true
		f.uv1_world_triplanar = true
		f.uv1_scale = Vector3.ONE / 1.6
		_materials[key] = f
		return f
	var m := StandardMaterial3D.new()
	m.resource_name = id
	m.albedo_texture = texture(id, "diff")
	m.albedo_color = tint
	var normal := texture(id, "nor_gl")
	if normal != null:
		m.normal_enabled = true
		m.normal_texture = normal
	var rough := texture(id, "rough")
	if rough != null:
		m.roughness_texture = rough
		m.roughness = 1.0
	var ao := texture(id, "ao")
	if ao != null:
		m.ao_enabled = true
		m.ao_texture = ao
		m.ao_light_affect = 0.5
	if triplanar:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_triplanar_sharpness = 4.0
		m.uv1_scale = Vector3.ONE / meters_per_tile
	else:
		m.uv1_scale = Vector3(1.0 / meters_per_tile, 1.0 / meters_per_tile, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_materials[key] = m
	return m


static func model(id: String) -> PackedScene:
	if _scenes.has(id):
		return _scenes[id]
	var path := "%s%s/%s_1k.gltf" % [MODEL_ROOT, id, id]
	var scene: PackedScene = load(path) if ResourceLoader.exists(path) else null
	_scenes[id] = scene
	return scene


static func meshes_of(id: String) -> Array:
	# [{"mesh": Mesh, "transform": Transform3D, "name": String}] for every
	# MeshInstance3D in a model, relative to the model root. Used for
	# MultiMesh scattering of multi-part assets such as plant sets.
	var result: Array = []
	var scene := model(id)
	if scene == null:
		return result
	var root := scene.instantiate() as Node3D
	_collect(root, Transform3D.IDENTITY, result)
	root.free()
	return result


static func _collect(node: Node, parent_xform: Transform3D, result: Array) -> void:
	var xform := parent_xform
	if node is Node3D:
		xform = parent_xform * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		result.append({"mesh": (node as MeshInstance3D).mesh, "transform": xform, "name": String(node.name)})
	for child in node.get_children():
		_collect(child, xform, result)
