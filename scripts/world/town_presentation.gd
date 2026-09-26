extends RefCounted

# Exterior dressing. Building shells are visual-only over town_level.gd's
# existing mass collision. Small colliding props register their exact footprints
# with that level's AStar obstacle list before the grid is built.

const STONE_HOUSE: PackedScene = preload("res://assets/environment/townhouse_stone_gable_9x16.glb")
const PLASTER_HOUSE: PackedScene = preload("res://assets/environment/townhouse_plaster_hip_9x16.glb")
const COBBLE_DIFF: Texture2D = preload("res://assets/vendor/environment_visual/polyhaven/cobblestone_floor_001/cobblestone_floor_001_diff_1k.jpg")
const COBBLE_NORMAL: Texture2D = preload("res://assets/vendor/environment_visual/polyhaven/cobblestone_floor_001/cobblestone_floor_001_nor_gl_1k.png")
const COBBLE_ROUGH: Texture2D = preload("res://assets/vendor/environment_visual/polyhaven/cobblestone_floor_001/cobblestone_floor_001_rough_1k.png")
const MUD_DIFF: Texture2D = preload("res://assets/vendor/polyhaven/materials/muddy_tracks_diff_1k.jpg")
const MUD_NORMAL: Texture2D = preload("res://assets/world_materials/muddy_tracks_normal.png")
const MUD_ROUGH: Texture2D = preload("res://assets/world_materials/muddy_tracks_rough.png")
const CRATE: PackedScene = preload("res://assets/vendor/polyhaven/wooden_crate_02/wooden_crate_02_1k.gltf")
const SERVICE_WING := preload("res://scripts/world/service_wing_visual.gd")
const FACADE := preload("res://scripts/world/facade_variation.gd")
const TOWN_GROUND := preload("res://scripts/world/town_ground.gd")

static var _cobble_material: StandardMaterial3D
static var _mud_material: StandardMaterial3D
static var _puddle_material: StandardMaterial3D


static func add_plot_shell(parent: Node3D, label: String, base: Vector3, size: Vector3, plaster: bool) -> bool:
	# Small passage bays use their own human-scale openings and roof geometry.
	# Stretching the 9 m facade would compress the doors and windows.
	if size.x < 8.5 or size.z < 12.5:
		SERVICE_WING.add_shell(parent, label, base, size, plaster)
		return true
	var source := PLASTER_HOUSE if plaster else STONE_HOUSE
	var visual := source.instantiate() as Node3D
	if visual == null:
		return false
	visual.name = label + " architectural shell"
	visual.position = base
	visual.scale = Vector3(size.x / 9.0, 1.0, size.z / 16.0)
	parent.add_child(visual)
	FACADE.apply(visual, hash(label), plaster, true)
	return true


static func shell_eaves_height(plaster: bool, size: Vector3) -> float:
	if size.x < 8.5 or size.z < 12.5:
		return size.y
	return 5.55 if plaster else 5.85


static func add_street_surfaces(parent: Node3D, navigation_obstacles: Array[Rect2]) -> void:
	if _mud_material == null:
		_mud_material = _ground_material(MUD_DIFF, MUD_NORMAL, MUD_ROUGH, 2.4, Color(0.56, 0.59, 0.57))
	if _cobble_material == null:
		_cobble_material = _ground_material(COBBLE_DIFF, COBBLE_NORMAL, COBBLE_ROUGH, 2.4, Color(0.86, 0.84, 0.81))
	# One blended surface: worn setts, trodden mud, brick grit, puddles and
	# weedy edges (scripts/world/town_ground.gdshader).
	var ground := MeshInstance3D.new()
	ground.name = "Town ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(129.7, 409.7)
	ground.mesh = plane
	ground.material_override = TOWN_GROUND.make_material()
	ground.position = Vector3(0, 0.013, 0)
	parent.add_child(ground)
	_add_west_street_edges(parent)
	_add_roadside_props(parent, navigation_obstacles)
	_add_rubble_bands(parent)


static func _add_west_street_edges(parent: Node3D) -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = COBBLE_DIFF
	stone.albedo_color = Color(0.72, 0.72, 0.69)
	stone.roughness = 0.94
	stone.uv1_triplanar = true
	stone.uv1_world_triplanar = true
	stone.uv1_scale = Vector3.ONE / 2.4
	for x in [-50.95, -45.05]:
		for segment in [[181.0, 21.0], [149.5, 27.0], [111.0, 20.0]]:
			_add_visual_box(parent, "Interrupted old curb", Vector3(x, 0.047, segment[0]),
				Vector3(0.18, 0.075, segment[1]), stone)
	# Fine damp dirt at the building bases breaks the straight texture boundary.
	for x in [-53.0, -43.1]:
		for z in [184.0, 153.0, 114.0]:
			_add_patch(parent, "Damp verge", Vector3(x, 0.025, z), Vector2(0.9, 8.0), _mud_material)


static func _add_puddles(parent: Node3D) -> void:
	if _puddle_material == null:
		_puddle_material = StandardMaterial3D.new()
		_puddle_material.albedo_color = Color(0.22, 0.26, 0.27)
		_puddle_material.metallic = 0.05
		_puddle_material.roughness = 0.24
	for p in [Vector3(-51.7, 0.034, 189.0), Vector3(-45.3, 0.034, 171.0),
			Vector3(-51.5, 0.034, 139.0), Vector3(-46.0, 0.034, 109.0),
			Vector3(8.9, 0.034, 22.0)]:
		var visual := MeshInstance3D.new()
		visual.name = "Shallow rain puddle"
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.0
		visual.mesh = mesh
		visual.material_override = _puddle_material
		visual.position = p
		visual.scale = Vector3(0.95, 0.003, 1.7)
		parent.add_child(visual)


static func _add_roadside_props(parent: Node3D, navigation_obstacles: Array[Rect2]) -> void:
	for p in [Vector3(-53.0, 0.0, 176.5), Vector3(-43.2, 0.0, 146.0),
			Vector3(-53.1, 0.0, 109.0), Vector3(8.8, 0.0, 11.0),
			Vector3(51.2, 0.0, -196.5)]:
		_add_crate(parent, p, navigation_obstacles)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.22, 0.17, 0.12)
	wood.roughness = 0.91
	for p in [Vector3(-53.1, 0.16, 167.0), Vector3(-42.9, 0.16, 115.0)]:
		_add_visual_box(parent, "Discarded timber", p, Vector3(0.17, 0.2, 3.2), wood)
		_add_visual_box(parent, "Discarded timber", p + Vector3(0.2, 0.07, 0.35), Vector3(0.15, 0.19, 2.65), wood)
	for p in [Vector3(-53.0, 0, 151.0), Vector3(9.0, 0, -5.8), Vector3(51.7, 0, -199.5)]:
		_add_barrel(parent, p, navigation_obstacles)


static func _add_crate(parent: Node3D, position: Vector3, navigation_obstacles: Array[Rect2]) -> void:
	var body := StaticBody3D.new()
	body.name = "Roadside wooden crate"
	body.position = position
	parent.add_child(body)
	body.add_child(CRATE.instantiate())
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.62, 0.48, 1.18)
	shape.shape = box
	shape.position.y = 0.24
	body.add_child(shape)
	navigation_obstacles.append(Rect2(Vector2(position.x - 0.31, position.z - 0.59), Vector2(0.62, 1.18)))


static func _add_barrel(parent: Node3D, position: Vector3, navigation_obstacles: Array[Rect2]) -> void:
	var body := StaticBody3D.new()
	body.name = "Closed roadside barrel"
	body.position = position
	parent.add_child(body)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.37
	cylinder.height = 0.86
	shape.shape = cylinder
	shape.position.y = 0.43
	body.add_child(shape)
	navigation_obstacles.append(Rect2(Vector2(position.x - 0.37, position.z - 0.37), Vector2(0.74, 0.74)))
	var timber := StandardMaterial3D.new()
	timber.albedo_color = Color(0.23, 0.17, 0.12)
	timber.roughness = 0.90
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.14, 0.16, 0.16)
	metal.metallic = 0.65
	metal.roughness = 0.65
	var shell := MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.34
	barrel_mesh.bottom_radius = 0.36
	barrel_mesh.height = 0.86
	barrel_mesh.radial_segments = 12
	shell.mesh = barrel_mesh
	shell.material_override = timber
	shell.position.y = 0.43
	body.add_child(shell)
	for y in [0.20, 0.65]:
		var hoop := MeshInstance3D.new()
		var hoop_mesh := CylinderMesh.new()
		hoop_mesh.top_radius = 0.38
		hoop_mesh.bottom_radius = 0.38
		hoop_mesh.height = 0.045
		hoop_mesh.radial_segments = 12
		hoop.mesh = hoop_mesh
		hoop.material_override = metal
		hoop.position.y = y
		body.add_child(hoop)


static func _add_rubble_bands(parent: Node3D) -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = COBBLE_DIFF
	stone.albedo_color = Color(0.70, 0.69, 0.65)
	stone.roughness = 1.0
	stone.uv1_triplanar = true
	stone.uv1_world_triplanar = true
	stone.uv1_scale = Vector3.ONE / 2.4
	var fragment := BoxMesh.new()
	fragment.size = Vector3.ONE
	fragment.material = stone
	var cluster := MultiMeshInstance3D.new()
	cluster.name = "Irregular rubble clusters at building bases"
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = fragment
	var centres := [Vector3(-53.15, 0.0, 184.0), Vector3(-43.25, 0.0, 147.0),
		Vector3(8.55, 0.0, 20.8), Vector3(-53.15, 0.0, 110.0),
		Vector3(51.05, 0.0, -198.0)]
	instances.instance_count = centres.size() * 12
	cluster.multimesh = instances
	parent.add_child(cluster)
	for region in range(centres.size()):
		for fragment_index in range(12):
			var seed := float(region * 17 + fragment_index)
			var angle := seed * 2.39996
			var radius := 0.18 + 0.12 * float(fragment_index % 5)
			var pos: Vector3 = centres[region] + Vector3(cos(angle) * radius, 0.09, sin(angle) * radius * 1.65)
			var scale := Vector3(0.18 + 0.13 * absf(sin(seed * 1.37)),
				0.10 + 0.09 * absf(cos(seed * 0.81)),
				0.18 + 0.15 * absf(sin(seed * 0.91)))
			var basis := Basis(Vector3.UP, angle).scaled(scale)
			instances.set_instance_transform(region * 12 + fragment_index, Transform3D(basis, pos))


static func _ground_material(diffuse: Texture2D, normal: Texture2D, rough: Texture2D, meters_per_tile: float, tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = diffuse
	material.albedo_color = tint
	material.normal_enabled = true
	material.normal_texture = normal
	material.normal_scale = 0.55
	material.roughness_texture = rough
	material.roughness = 1.0
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / meters_per_tile
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


static func _add_patch(parent: Node3D, label: String, position: Vector3, dimensions: Vector2, material: Material) -> void:
	var patch := MeshInstance3D.new()
	patch.name = label
	var mesh := PlaneMesh.new()
	mesh.size = dimensions
	patch.mesh = mesh
	patch.material_override = material
	patch.position = position
	parent.add_child(patch)


static func _add_visual_box(parent: Node3D, label: String, position: Vector3, dimensions: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position
	parent.add_child(visual)
