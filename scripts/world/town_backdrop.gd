extends RefCounted

# What lies beyond the playable town: the edge reads as a field wall and
# hedgerow instead of a 4 m arena wall, with fields, treelines, distant farms
# and smoke columns behind it (references G01-07, G01-08, G01-11, G01-12).
# Only visuals change; the original outer collision boxes stay in place.

const PBR := preload("res://scripts/world/pbr_library.gd")
const TOWN_GROUND := preload("res://scripts/world/town_ground.gd")
const TREE: PackedScene = preload("res://assets/environment/trees/town_tree.glb")
const TREE_CARD: Texture2D = preload("res://assets/environment/trees/town_tree_card.png")
const STONE_HOUSE: PackedScene = preload("res://assets/environment/townhouse_stone_gable_9x16.glb")
const PLASTER_HOUSE: PackedScene = preload("res://assets/environment/townhouse_plaster_hip_9x16.glb")
const FX_TEXTURES := preload("res://scripts/fx/fx_textures.gd")
const FACADE := preload("res://scripts/world/facade_variation.gd")

const HALF_X := 65.0
const HALF_Z := 205.0

var rng := RandomNumberGenerator.new()


func build(level: Node3D) -> void:
	rng.seed = 1944
	_hide_arena_walls(level)
	_field_wall(level)
	_hedgerow(level)
	_fields(level)
	_edge_trees(level)
	_treeline_cards(level)
	_distant_farms(level)
	_smoke_column(level, Vector3(-260.0, 0.0, -120.0), 1.0)
	_smoke_column(level, Vector3(190.0, 0.0, 60.0), 0.8)
	_smoke_column(level, Vector3(40.0, 0.0, -520.0), 1.3)


func _hide_arena_walls(level: Node3D) -> void:
	for child in level.get_children():
		var label := String(child.name)
		if label.ends_with("outer boundary"):
			for part in child.get_children():
				if part is MeshInstance3D:
					part.visible = false
		elif label.begins_with("Boundary stone coping") or label.begins_with("Boundary foot course"):
			child.visible = false


func _field_wall(level: Node3D) -> void:
	# 1.5 m dry-stone wall on the old boundary line, coping stones on top.
	var stone := PBR.material("rock_wall_13", 1.8, Color(0.82, 0.8, 0.76))
	var segments := [
		[Vector3(-HALF_X, 0, 0), Vector3(1.0, 1.5, HALF_Z * 2.0)],
		[Vector3(HALF_X, 0, 0), Vector3(1.0, 1.5, HALF_Z * 2.0)],
		[Vector3(0, 0, -HALF_Z), Vector3(HALF_X * 2.0, 1.5, 1.0)],
		[Vector3(0, 0, HALF_Z), Vector3(HALF_X * 2.0, 1.5, 1.0)],
	]
	for seg in segments:
		var wall := MeshInstance3D.new()
		wall.name = "Field wall"
		var mesh := BoxMesh.new()
		mesh.size = seg[1]
		wall.mesh = mesh
		wall.material_override = stone
		wall.position = seg[0] + Vector3(0, 0.75, 0)
		level.add_child(wall)
		var cap := MeshInstance3D.new()
		var cap_mesh := BoxMesh.new()
		cap_mesh.size = seg[1] * Vector3(1.15, 0.0, 1.0) + Vector3(0, 0.14, 0) if seg[1].x < 2.0 else seg[1] * Vector3(1.0, 0.0, 1.15) + Vector3(0, 0.14, 0)
		cap.mesh = cap_mesh
		cap.material_override = stone
		cap.position = seg[0] + Vector3(0, 1.55, 0)
		level.add_child(cap)


func _hedgerow(level: Node3D) -> void:
	# Real scanned shrubs just outside the wall, chunked so only nearby
	# stretches draw; a dark leafy core hides gaps at any distance.
	var parts := PBR.meshes_of("shrub_02")
	if parts.is_empty():
		return
	var per_part: Array = []
	for i in range(parts.size()):
		per_part.append([] as Array[Transform3D])
	var lines := [
		[Vector3(-HALF_X - 1.6, 0, -HALF_Z), Vector3(-HALF_X - 1.6, 0, HALF_Z)],
		[Vector3(HALF_X + 1.6, 0, -HALF_Z), Vector3(HALF_X + 1.6, 0, HALF_Z)],
		[Vector3(-HALF_X, 0, -HALF_Z - 1.6), Vector3(HALF_X, 0, -HALF_Z - 1.6)],
		[Vector3(-HALF_X, 0, HALF_Z + 1.6), Vector3(HALF_X, 0, HALF_Z + 1.6)],
	]
	for line in lines:
		var a: Vector3 = line[0]
		var b: Vector3 = line[1]
		var length := a.distance_to(b)
		var along_z := absf(b.z - a.z) > absf(b.x - a.x)
		var across := Vector3(1, 0, 0) if along_z else Vector3(0, 0, 1)
		var steps := int(length / 1.25)
		for row in range(2):
			for i in range(steps + 1):
				var p := a.lerp(b, (float(i) + 0.5 * row) / float(steps)) + across * (float(row) * 1.3 * signf(a.x + a.z)) \
					+ Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35))
				var index := rng.randi() % parts.size()
				var s := rng.randf_range(1.3, 2.0)
				per_part[index].append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(1.1, 1.5), s)), p + Vector3(0, 0.35, 0)))
	for i in range(parts.size()):
		var entry: Dictionary = parts[i]
		var strip := Transform3D((entry.transform as Transform3D).basis, Vector3.ZERO)
		var list: Array[Transform3D] = []
		for t in per_part[i]:
			list.append(t * strip)
		_chunked(level, "Hedgerow shrubs", entry.mesh, list, 95.0)


func _fields(level: Node3D) -> void:
	# Rolling farmland beyond the wall: the town ground shader in all-grass
	# mode with muddy tracks, on a plane that sits just below the town ground.
	var field := MeshInstance3D.new()
	field.name = "Surrounding fields"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(1600, 1600)
	mesh.subdivide_width = 8
	mesh.subdivide_depth = 8
	field.mesh = mesh
	field.material_override = TOWN_GROUND.make_material(1.0, 0.25)
	field.position = Vector3(0, -0.02, 0)
	level.add_child(field)


func _edge_trees(level: Node3D) -> void:
	for i in range(34):
		var side := rng.randi() % 4
		var p: Vector3
		match side:
			0:
				p = Vector3(-HALF_X - rng.randf_range(6.0, 30.0), 0, rng.randf_range(-HALF_Z, HALF_Z))
			1:
				p = Vector3(HALF_X + rng.randf_range(6.0, 30.0), 0, rng.randf_range(-HALF_Z, HALF_Z))
			2:
				p = Vector3(rng.randf_range(-HALF_X, HALF_X), 0, -HALF_Z - rng.randf_range(6.0, 30.0))
			_:
				p = Vector3(rng.randf_range(-HALF_X, HALF_X), 0, HALF_Z + rng.randf_range(6.0, 30.0))
		var tree := TREE.instantiate() as Node3D
		tree.name = "Edge tree"
		var s := rng.randf_range(0.5, 0.8)
		tree.scale = Vector3(s, s * rng.randf_range(0.95, 1.2), s)
		tree.rotation.y = rng.randf() * TAU
		tree.position = p
		level.add_child(tree)
		for mesh_instance in _mesh_instances(tree):
			mesh_instance.visibility_range_end = 140.0
			mesh_instance.visibility_range_end_margin = 15.0
			mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		# Beyond the 3D range a matching card takes over.
		_card(level, p, 24.5 * s, 19.4 * s * 1.05, 140.0, 0.0)


func _treeline_cards(level: Node3D) -> void:
	# Clustered billboard trees on the horizon.
	for cluster in range(46):
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(120.0, 520.0)
		var center := Vector3(cos(angle) * dist * 0.9, 0, sin(angle) * dist * 1.35)
		if absf(center.x) < HALF_X + 40.0 and absf(center.z) < HALF_Z + 40.0:
			continue
		for i in range(rng.randi_range(4, 14)):
			var p := center + Vector3(rng.randf_range(-35.0, 35.0), 0, rng.randf_range(-12.0, 12.0)).rotated(Vector3.UP, rng.randf() * TAU)
			var s := rng.randf_range(0.5, 0.95)
			_card(level, p, 24.5 * s, 19.4 * s, 0.0, 0.0)


func _card(level: Node3D, at: Vector3, width: float, height: float, begin: float, _end: float) -> void:
	var card := MeshInstance3D.new()
	card.name = "Tree card"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(width, height)
	mesh.center_offset = Vector3(0, height * 0.5, 0)
	card.mesh = mesh
	card.material_override = _card_material()
	card.position = at
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if begin > 0.0:
		card.visibility_range_begin = begin
		card.visibility_range_begin_margin = 15.0
		card.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	level.add_child(card)


static var _card_mat: StandardMaterial3D


func _card_material() -> StandardMaterial3D:
	if _card_mat == null:
		_card_mat = StandardMaterial3D.new()
		_card_mat.albedo_texture = TREE_CARD
		_card_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		_card_mat.alpha_scissor_threshold = 0.45
		_card_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		_card_mat.billboard_keep_scale = true
		_card_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_card_mat.albedo_color = Color(0.78, 0.84, 0.74)
		_card_mat.roughness = 1.0
	return _card_mat


func _distant_farms(level: Node3D) -> void:
	var farms := [Vector3(-210.0, 0, 40.0), Vector3(230.0, 0, -160.0), Vector3(-160.0, 0, -330.0), Vector3(150.0, 0, 330.0), Vector3(-240.0, 0, 260.0), Vector3(260.0, 0, 120.0)]
	for i in range(farms.size()):
		var house := (STONE_HOUSE if i % 2 == 0 else PLASTER_HOUSE).instantiate() as Node3D
		house.name = "Distant farmhouse"
		house.position = farms[i]
		house.rotation.y = rng.randf() * TAU
		level.add_child(house)
		FACADE.apply(house, i * 7919, i % 2 == 1, false)


func _smoke_column(level: Node3D, at: Vector3, strength: float) -> void:
	# Tall black smoke from fires beyond town, drifting with the wind.
	var material := StandardMaterial3D.new()
	material.albedo_texture = FX_TEXTURES.get_texture("soft_puff")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.billboard_keep_scale = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness = 1.0
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	quad.material = material
	var smoke := CPUParticles3D.new()
	smoke.name = "Distant smoke column"
	smoke.mesh = quad
	smoke.amount = int(70 * strength)
	smoke.lifetime = 28.0
	smoke.preprocess = 28.0
	smoke.local_coords = false
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 4.0
	smoke.direction = Vector3.UP
	smoke.spread = 8.0
	smoke.gravity = Vector3(0.35, 0.12, 0.1)
	smoke.initial_velocity_min = 3.2
	smoke.initial_velocity_max = 4.2
	smoke.damping_min = 0.05
	smoke.damping_max = 0.1
	smoke.angle_min = -180.0
	smoke.angle_max = 180.0
	smoke.scale_amount_min = 18.0 * strength
	smoke.scale_amount_max = 28.0 * strength
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.35))
	grow.add_point(Vector2(1.0, 2.8))
	smoke.scale_amount_curve = grow
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.08, 0.6, 1.0])
	ramp.colors = PackedColorArray([Color(0.08, 0.075, 0.07, 0.0), Color(0.1, 0.095, 0.09, 0.85), Color(0.22, 0.22, 0.22, 0.55), Color(0.4, 0.4, 0.42, 0.0)])
	smoke.color_ramp = ramp
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	smoke.position = at
	level.add_child(smoke)


func _chunked(level: Node3D, label: String, mesh: Mesh, list: Array[Transform3D], view_distance: float) -> void:
	var cells: Dictionary = {}
	for t in list:
		var key := Vector2i(floori(t.origin.x / 40.0), floori(t.origin.z / 40.0))
		if not cells.has(key):
			cells[key] = []
		cells[key].append(t)
	for key in cells.keys():
		var center := Vector3((key.x + 0.5) * 40.0, 0.0, (key.y + 0.5) * 40.0)
		var items: Array = cells[key]
		var instance := MultiMeshInstance3D.new()
		instance.name = label
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = items.size()
		for i in range(items.size()):
			var t: Transform3D = items[i]
			mm.set_instance_transform(i, Transform3D(t.basis, t.origin - center))
		instance.multimesh = mm
		instance.position = center
		instance.visibility_range_end = view_distance
		instance.visibility_range_end_margin = 10.0
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		level.add_child(instance)


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found
