extends RefCounted

# Per-house material variation and small architectural additions on the two
# authored townhouse shells, so a street of repeated plots reads as separate
# buildings (reference G01-09/G01-10): scanned rubble stone or weathered
# plaster, varied shutter paint, darker slate, brick chimney stacks with clay
# pots, doorsteps, and canvas awnings on some shopfronts. Visual only; the
# plot collision in town_level.gd is unchanged.

const PBR := preload("res://scripts/world/pbr_library.gd")

# Godot local frame of both shells: front (door) face at +Z, walls 0.17 m
# thick around x = +/-4.5 and z = +/-8.
const STONE_TINTS := [Color(1.0, 1.0, 1.0), Color(0.93, 0.88, 0.8), Color(0.84, 0.85, 0.86), Color(0.78, 0.74, 0.68)]
const PLASTER_TINTS := [Color(0.96, 0.9, 0.78), Color(0.9, 0.8, 0.62), Color(0.8, 0.8, 0.77), Color(0.82, 0.86, 0.79), Color(0.93, 0.83, 0.76)]
const SHUTTER_TINTS := [Color(0.92, 0.92, 0.88), Color(0.5, 0.6, 0.46), Color(0.5, 0.58, 0.64), Color(0.55, 0.42, 0.3), Color(0.72, 0.74, 0.7)]
const AWNING_TINTS := [Color(0.3, 0.42, 0.3), Color(0.55, 0.22, 0.18), Color(0.25, 0.3, 0.38)]

static var _shutters: Array = []
static var _slate: Array = []
static var _pot_material: StandardMaterial3D
static var _brick: StandardMaterial3D
static var _step: StandardMaterial3D
static var _awning_plain: Array = []
static var _awning_striped: Array = []


static func apply(shell: Node3D, seed_value: int, plaster: bool, wide: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_ensure_shared()
	var wall := _wall_material(plaster, rng.randi() % (PLASTER_TINTS.size() if plaster else STONE_TINTS.size()))
	var trim := PBR.material("rock_wall_13", 2.2, STONE_TINTS[rng.randi() % STONE_TINTS.size()])
	var shutter: Material = _shutters[rng.randi() % _shutters.size()]
	var slate: Material = _slate[rng.randi() % _slate.size()]
	for mesh_instance in _mesh_instances(shell):
		var mesh := mesh_instance.mesh
		for i in range(mesh.get_surface_count()):
			var source := mesh.surface_get_material(i)
			var label := source.resource_name if source != null else ""
			match label:
				"Town_stone":
					mesh_instance.set_surface_override_material(i, wall if not plaster else trim)
				"Town_plaster":
					mesh_instance.set_surface_override_material(i, wall)
				"Town_shutter":
					mesh_instance.set_surface_override_material(i, shutter)
				"Town_slate":
					mesh_instance.set_surface_override_material(i, slate)
	if not wide:
		return
	# Children inherit the plot's slight x/z scale, like the shell itself.
	var ridge := 7.45 if plaster else 8.0
	var eaves := 5.55 if plaster else 5.85
	var chimney := Vector3(-2.8, ridge + 1.52, 3.55) if plaster else Vector3(2.75, ridge + 1.52, -4.75)
	_add_pots(shell, chimney, rng)
	var stack_x := 2.6 if plaster else -2.45
	var stack_z := -5.2 if plaster else 6.4
	var slope_height := eaves + (ridge - eaves) * (1.0 - absf(stack_x) / 4.9)
	var top := ridge + 1.1 + rng.randf_range(0.0, 0.5)
	_box(shell, "Brick chimney stack", Vector3(stack_x, (slope_height - 0.3 + top) * 0.5, stack_z), Vector3(0.78, top - slope_height + 0.3, 0.62), _brick)
	_box(shell, "Chimney stack cap", Vector3(stack_x, top + 0.06, stack_z), Vector3(0.92, 0.12, 0.76), _step)
	_add_pots(shell, Vector3(stack_x, top + 0.12, stack_z), rng)
	var door_x := 2.25 if plaster else -2.35
	_box(shell, "Door step", Vector3(door_x, 0.09, 8.42), Vector3(1.6, 0.18, 0.5), _step)
	if rng.randf() < 0.3:
		var span := Vector2(-3.4, -0.0) if plaster else Vector2(0.0, 3.45)
		_add_awning(shell, span, rng)


static func _ensure_shared() -> void:
	if not _shutters.is_empty():
		return
	var base: Texture2D = load("res://assets/environment/textures/shutter_base.jpg")
	var normal: Texture2D = load("res://assets/environment/textures/shutter_normal.png")
	for tint in SHUTTER_TINTS:
		var m := StandardMaterial3D.new()
		m.albedo_texture = base
		# The authored shutter texture is mid green; desaturated paint colors
		# multiply over a lightened copy of it.
		m.albedo_color = Color(tint.r * 1.35, tint.g * 1.2, tint.b * 1.35)
		m.normal_enabled = true
		m.normal_texture = normal
		m.roughness = 0.8
		_shutters.append(m)
	var slate_base: Texture2D = load("res://assets/environment/textures/slate_base.png")
	var slate_normal: Texture2D = load("res://assets/environment/textures/slate_normal.png")
	for shade in [0.58, 0.66, 0.74]:
		var s := StandardMaterial3D.new()
		s.albedo_texture = slate_base
		s.albedo_color = Color(shade, shade * 1.02, shade * 1.06)
		s.normal_enabled = true
		s.normal_texture = slate_normal
		s.roughness = 0.72
		_slate.append(s)
	_brick = PBR.material("medieval_red_brick", 1.2, Color(0.85, 0.78, 0.74))
	_step = PBR.material("rock_wall_13", 1.5, Color(0.75, 0.74, 0.72))
	_pot_material = StandardMaterial3D.new()
	_pot_material.albedo_color = Color(0.56, 0.3, 0.2)
	_pot_material.roughness = 0.9
	var canvas_normal := PBR.texture("hessian_230", "nor_gl")
	for tint in AWNING_TINTS:
		var plain := StandardMaterial3D.new()
		plain.albedo_color = tint
		plain.normal_enabled = canvas_normal != null
		plain.normal_texture = canvas_normal
		plain.uv1_scale = Vector3(4.0, 2.0, 1.0)
		plain.roughness = 0.95
		plain.cull_mode = BaseMaterial3D.CULL_DISABLED
		_awning_plain.append(plain)
		var striped := plain.duplicate() as StandardMaterial3D
		striped.albedo_color = Color.WHITE
		striped.albedo_texture = _stripe_texture(tint)
		striped.uv1_scale = Vector3(1.0, 1.0, 1.0)
		_awning_striped.append(striped)


static func _wall_material(plaster: bool, index: int) -> Material:
	if plaster:
		return PBR.material("damaged_plaster", 2.6, PLASTER_TINTS[index])
	return PBR.material("rock_wall_13", 2.2, STONE_TINTS[index])


static func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found


static func _box(parent: Node3D, label: String, center: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	visual.position = center
	parent.add_child(visual)


static func _add_pots(parent: Node3D, top_center: Vector3, rng: RandomNumberGenerator) -> void:
	var count := 2 + rng.randi() % 3
	for i in range(count):
		var pot := MeshInstance3D.new()
		pot.name = "Chimney pot"
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.085
		mesh.bottom_radius = 0.12
		mesh.height = rng.randf_range(0.38, 0.6)
		mesh.radial_segments = 10
		pot.mesh = mesh
		pot.material_override = _pot_material
		var offset := (float(i) - float(count - 1) * 0.5) * 0.27
		pot.position = top_center + Vector3(offset, mesh.height * 0.5, 0.0)
		parent.add_child(pot)


static func _add_awning(parent: Node3D, span: Vector2, rng: RandomNumberGenerator) -> void:
	# Sloped canvas over the ground-floor shop windows, with a short valance.
	var striped := rng.randf() < 0.5
	var index := rng.randi() % AWNING_TINTS.size()
	var material: Material = _awning_striped[index] if striped else _awning_plain[index]
	var width := span.y - span.x
	var cx := (span.x + span.y) * 0.5
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var back_y := 2.72
	var front_y := 2.3
	var back_z := 8.2
	var front_z := 9.35
	var quads := [
		[Vector3(span.x, back_y, back_z), Vector3(span.y, back_y, back_z), Vector3(span.y, front_y, front_z), Vector3(span.x, front_y, front_z)],
		[Vector3(span.x, front_y, front_z), Vector3(span.y, front_y, front_z), Vector3(span.y, front_y - 0.22, front_z + 0.02), Vector3(span.x, front_y - 0.22, front_z + 0.02)],
	]
	for q in quads:
		var normal: Vector3 = (q[1] - q[0]).cross(q[3] - q[0]).normalized()
		var uvs := [Vector2(0, 0), Vector2(width, 0), Vector2(width, 1), Vector2(0, 1)]
		for idx in [0, 1, 2, 0, 2, 3]:
			surface.set_normal(-normal)
			surface.set_uv(uvs[idx])
			surface.add_vertex(q[idx])
	var visual := MeshInstance3D.new()
	visual.name = "Shop awning"
	visual.mesh = surface.commit()
	visual.material_override = material
	parent.add_child(visual)
	# Two thin iron arms.
	for x in [span.x + 0.08, span.y - 0.08]:
		_box(parent, "Awning arm", Vector3(x, (back_y + front_y) * 0.5 - 0.05, (back_z + front_z) * 0.5), Vector3(0.03, 0.03, 1.2), _pot_material)
	var _unused := cx


static func _stripe_texture(tint: Color) -> Texture2D:
	var image := Image.create(64, 8, true, Image.FORMAT_RGB8)
	for x in range(64):
		var band := (x / 8) % 2 == 0
		var c := tint if band else Color(0.86, 0.84, 0.78)
		for y in range(8):
			image.set_pixel(x, y, c)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
