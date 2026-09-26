extends RefCounted

# Set dressing that makes the blockout read as an occupied, recently fought-
# over 1944 town (references G01-07..G01-12). Placement follows rules, as in
# the Far Cry 5 notes in docs/SHOOTER_BENCHMARKS.md, rather than even scatter:
#   * weeds at wall bases and boundary edges;
#   * brick and stone rubble at building corners and in drifts on the streets;
#   * domestic clutter at doorways;
#   * military material (sandbags, tarped dumps, jerrycans) near guard posts;
#   * cast-iron street lamps along the paved streets, wall lamps by doors;
#   * telegraph poles with sagging wires; trees in yards and wide crossings.
# Solid pieces hug facades, avoid doors, passages and mission points, and
# register their footprints with the level's guard path grid. The layout is
# seeded, so every run and test sees the same town.

const PBR := preload("res://scripts/world/pbr_library.gd")
const TREE: PackedScene = preload("res://assets/environment/trees/town_tree.glb")

# Areas the regression tests and mission flow depend on stay free of solid
# dressing: the central core, the covered passages and both handoff points.
const KEEP_CLEAR := [
	Rect2(-12.0, -22.0, 24.0, 64.0),   # core courtyard, residence door, test fixtures
	Rect2(-35.5, 101.0, 6.0, 20.0),    # west service passage
	Rect2(-11.5, 101.0, 5.8, 20.0),    # south workshop passage
	Rect2(2.8, -130.0, 4.8, 20.0),     # north passage
	Rect2(16.0, -16.0, 5.0, 18.0),     # damaged corner passage
	Rect2(36.0, -206.0, 16.0, 16.0),   # scout shelter
	Rect2(-53.0, 186.0, 10.0, 18.0),   # player spawn
]

var level: Node3D
var obstacles: Array[Rect2]
var rng := RandomNumberGenerator.new()
var _bricks: Array[Transform3D] = []
var _stones: Array[Transform3D] = []
var _planks: Array[Transform3D] = []
var _sandbags: Array[Transform3D] = []
var _weeds: Dictionary = {} # mesh index -> Array[Transform3D]
var _weed_meshes: Array = []
var _weed_heights: Array[float] = []
var _tufts: Array[Transform3D] = []
var _doors: Array[Vector3] = []


func build(town: Node3D, navigation_obstacles: Array[Rect2]) -> void:
	level = town
	obstacles = navigation_obstacles
	rng.seed = 19440606
	for plot in level.plots:
		var size: Vector3 = plot.size
		if size.x >= 8.5 and size.z >= 12.5:
			var door_x: float = 2.25 if plot.plaster else -2.35
			_doors.append(Vector3(plot.base.x + door_x * size.x / 9.0, 0.0, plot.base.z + size.z * 0.5))
	_weed_meshes = PBR.meshes_of("nettle_plant") + PBR.meshes_of("weed_plant_02")
	for entry in _weed_meshes:
		var local: Transform3D = entry.transform
		_weed_heights.append(maxf(0.02, (local.basis * entry.mesh.get_aabb().size).abs().y))
	for plot in level.plots:
		_dress_plot(plot)
	_boundary_weeds()
	_street_rubble()
	_checkpoints()
	_street_lamps()
	_telegraph_line(Vector3(15.8, 0.0, 160.0), Vector3(15.8, 0.0, 40.0), 5, 1.0)
	_telegraph_line(Vector3(-45.6, 0.0, -60.0), Vector3(-45.6, 0.0, -190.0), 5, 1.0)
	_ruin(Rect2(27.2, 70.2, 8.0, 13.6), ["west", "south", "north_half"], Vector3(31.0, 0, 76.0))
	_ruin(Rect2(-43.6, -156.8, 7.2, 12.8), ["north", "west_half"], Vector3(-40.0, 0, -151.0))
	_trees()
	_contact_room()
	_flush_multimeshes()


# ---------------------------------------------------------------- per plot

func _dress_plot(plot: Dictionary) -> void:
	var base: Vector3 = plot.base
	var size: Vector3 = plot.size
	var half := Vector2(size.x * 0.5, size.z * 0.5)
	# Weeds along all four wall bases.
	var perimeter := [
		[Vector2(base.x - half.x, base.z + half.y + 0.25), Vector2(base.x + half.x, base.z + half.y + 0.25)],
		[Vector2(base.x - half.x, base.z - half.y - 0.25), Vector2(base.x + half.x, base.z - half.y - 0.25)],
		[Vector2(base.x - half.x - 0.25, base.z - half.y), Vector2(base.x - half.x - 0.25, base.z + half.y)],
		[Vector2(base.x + half.x + 0.25, base.z - half.y), Vector2(base.x + half.x + 0.25, base.z + half.y)],
	]
	for edge in perimeter:
		var a: Vector2 = edge[0]
		var b: Vector2 = edge[1]
		var steps := int(a.distance_to(b) / 0.9)
		for i in range(steps):
			if rng.randf() < 0.42:
				var p := a.lerp(b, (float(i) + rng.randf()) / float(steps))
				if not _near_door(Vector3(p.x, 0.0, p.y), 1.2):
					_add_weed(Vector3(p.x + rng.randf_range(-0.12, 0.12), 0.0, p.y + rng.randf_range(-0.12, 0.12)))
	# Rubble at one or two corners of about a third of the houses.
	if rng.randf() < 0.36:
		var corner := Vector3(base.x + half.x * (1.0 if rng.randf() < 0.5 else -1.0), 0.0, base.z + half.y * (1.0 if rng.randf() < 0.5 else -1.0))
		var outward := Vector3(signf(corner.x - base.x), 0.0, signf(corner.z - base.z))
		_rubble_heap(corner + outward * 0.8, rng.randf_range(0.8, 1.6), rng.randf_range(0.18, 0.38))
	if size.x < 8.5 or size.z < 12.5:
		return
	# Doorway clutter on the front (south) face.
	var front_z := base.z + half.y
	var door := Vector3(base.x + (2.25 if plot.plaster else -2.35) * size.x / 9.0, 0.0, front_z)
	if rng.randf() < 0.55:
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		var spot := door + Vector3(side * rng.randf_range(1.1, 1.8), 0.0, 0.42)
		if _clear_of_keep(spot, 0.8):
			var pick := rng.randi() % 5
			match pick:
				0:
					_place_model("wooden_bucket_01", spot, rng.randf() * TAU, 1.0)
				1:
					_place_model("wicker_basket_01", spot + Vector3(0, 0, 0.1), rng.randf() * TAU, 1.3)
				2:
					_place_model("painted_wooden_bench", spot + Vector3(side * 0.5, 0, 0.02), PI, 1.0, Vector3(1.16, 0.9, 0.5))
				3:
					_place_model("wooden_crate_01", spot, rng.randf_range(-0.3, 0.3), 1.0, Vector3(0.83, 0.35, 0.41))
				4:
					_place_model("metal_jerrycan_green", spot, rng.randf() * TAU, 1.0)
	if rng.randf() < 0.22:
		# Cast-iron bracket lamp beside the door.
		var lamp_pos := door + Vector3(1.0 if plot.plaster else -1.0, 2.75, 0.2)
		_place_model("street_lamp_02", lamp_pos, 0.0, 1.0)


# ----------------------------------------------------------------- scatter

func _add_weed(at: Vector3) -> void:
	# Every weed site also gets grass tufts; about half get a broadleaf plant
	# scaled to a real 0.3-0.85 m height (the scanned plant set is tiny).
	for i in range(rng.randi_range(1, 3)):
		var offset := Vector3(rng.randf_range(-0.25, 0.25), 0.0, rng.randf_range(-0.25, 0.25))
		var h := rng.randf_range(0.6, 1.25)
		_tufts.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(h, h * rng.randf_range(0.8, 1.3), h)), at + offset))
	if _weed_meshes.is_empty() or rng.randf() < 0.45:
		return
	var index := rng.randi() % _weed_meshes.size()
	var s := clampf(rng.randf_range(0.3, 0.85) / _weed_heights[index], 1.0, 14.0)
	var xform := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.9, 1.2), s)), at)
	if not _weeds.has(index):
		_weeds[index] = [] as Array[Transform3D]
	_weeds[index].append(xform)


func _rubble_heap(center: Vector3, radius: float, height: float) -> void:
	# A low mound of brick grit with loose bricks, stones and a few planks.
	var mound := MeshInstance3D.new()
	mound.name = "Rubble heap"
	mound.mesh = _mound_mesh(radius, height, rng.randi())
	mound.material_override = PBR.material("brick_gravel", 1.4, Color(0.85, 0.78, 0.72))
	mound.position = center
	level.add_child(mound)
	for i in range(int(radius * 38.0)):
		var r := radius * sqrt(rng.randf()) * 1.15
		var a := rng.randf() * TAU
		var p := center + Vector3(cos(a) * r, 0.0, sin(a) * r)
		var t := clampf(1.0 - r / (radius * 1.15), 0.0, 1.0)
		p.y = height * t * t * (3.0 - 2.0 * t) * 0.9 + 0.03
		var basis := Basis.from_euler(Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6)))
		if rng.randf() < 0.7:
			_bricks.append(Transform3D(basis, p))
		else:
			var s := rng.randf_range(0.6, 1.8)
			_stones.append(Transform3D(basis.scaled(Vector3(s, s * 0.7, s)), p))
	for i in range(rng.randi_range(0, 3)):
		var a := rng.randf() * TAU
		var p := center + Vector3(cos(a), 0.0, sin(a)) * radius * rng.randf_range(0.2, 0.9)
		p.y = height * 0.5
		var basis := Basis.from_euler(Vector3(rng.randf_range(-0.35, 0.35), rng.randf() * TAU, rng.randf_range(-0.25, 0.25)))
		_planks.append(Transform3D(basis.scaled(Vector3(1.0, 1.0, rng.randf_range(0.6, 1.4))), p))


func _street_rubble() -> void:
	# Drifts of loose bricks across the streets and a few larger heaps.
	for i in range(900):
		var p := Vector3(rng.randf_range(-62.0, 62.0), 0.03, rng.randf_range(-200.0, 200.0))
		if _inside_obstacle(p, 0.2):
			continue
		var basis := Basis.from_euler(Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.2, 0.2)))
		if rng.randf() < 0.75:
			_bricks.append(Transform3D(basis, p))
		else:
			_stones.append(Transform3D(basis.scaled(Vector3.ONE * rng.randf_range(0.5, 1.2)), p))
	for spot in [Vector3(-44.0, 0, 128.0), Vector3(40.0, 0, 96.0), Vector3(-15.0, 0, -76.0), Vector3(47.0, 0, -134.0), Vector3(-60.0, 0, 60.0), Vector3(28.0, 0, -62.0)]:
		if not _inside_obstacle(spot, 1.0):
			_rubble_heap(spot, rng.randf_range(1.6, 2.4), rng.randf_range(0.25, 0.42))


func _boundary_weeds() -> void:
	for i in range(700):
		var along := rng.randf()
		var side := rng.randi() % 4
		var p: Vector3
		match side:
			0:
				p = Vector3(-64.2 + rng.randf() * 1.2, 0, lerpf(-203.0, 203.0, along))
			1:
				p = Vector3(64.2 - rng.randf() * 1.2, 0, lerpf(-203.0, 203.0, along))
			2:
				p = Vector3(lerpf(-63.0, 63.0, along), 0, -204.2 + rng.randf() * 1.2)
			_:
				p = Vector3(lerpf(-63.0, 63.0, along), 0, 204.2 - rng.randf() * 1.2)
		_add_weed(p)


# -------------------------------------------------------------- military

func _checkpoints() -> void:
	# Sandbag positions beside (not in front of) guard posts, tarped dumps and
	# fuel cans. They sit on street edges so every lane stays open.
	_sandbag_wall([Vector3(-23.2, 0, 96.5), Vector3(-23.2, 0, 90.0), Vector3(-21.6, 0, 88.4)])
	_sandbag_wall([Vector3(19.4, 0, -146.0), Vector3(19.4, 0, -152.5)])
	_sandbag_wall([Vector3(48.6, 0, -161.0), Vector3(48.6, 0, -168.0), Vector3(47.0, 0, -169.6)])
	_sandbag_wall([Vector3(-43.6, 0, 170.0), Vector3(-43.6, 0, 163.0)])
	_sandbag_wall([Vector3(-52.6, 0, -62.0), Vector3(-52.6, 0, -69.0)])
	_supply_dump(Vector3(-23.6, 0, 84.0), 0.0)
	_supply_dump(Vector3(40.2, 0, -142.0), PI * 0.5)
	_supply_dump(Vector3(-52.8, 0, 132.0), 0.0)
	_supply_dump(Vector3(16.6, 0, -86.0), PI * 0.5)
	for p in [Vector3(-22.9, 0, 99.0), Vector3(-22.6, 0, 99.4), Vector3(19.0, 0, -143.6), Vector3(48.2, 0, -158.6), Vector3(48.4, 0, -159.0)]:
		if not _inside_obstacle(p, 0.1):
			_place_model("metal_jerrycan_green", p, rng.randf_range(-0.4, 0.4), 1.0)


func _sandbag_wall(points: Array) -> void:
	for point in points:
		if _inside_obstacle(point, 0.35) or not _clear_of_keep(point, 0.5):
			return
	for i in range(points.size() - 1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var length := a.distance_to(b)
		var dir := (b - a).normalized()
		var yaw := atan2(dir.x, dir.z)
		var per_row := maxi(1, int(length / 0.56))
		for row in range(5):
			var offset := 0.28 if row % 2 == 1 else 0.0
			for k in range(per_row):
				var t := (float(k) * 0.56 + offset + 0.28) / length
				if t > 1.0:
					continue
				var p := a.lerp(b, t) + Vector3(0.0, 0.1 + float(row) * 0.19, 0.0)
				var basis := Basis(Vector3.UP, yaw + PI * 0.5 + rng.randf_range(-0.08, 0.08)) * Basis(Vector3.FORWARD, rng.randf_range(-0.05, 0.05))
				_sandbags.append(Transform3D(basis, p + Vector3(rng.randf_range(-0.02, 0.02), 0, rng.randf_range(-0.02, 0.02))))
		_solid_box("Sandbag wall", (a + b) * 0.5 + Vector3(0, 0.5, 0), Vector3(0.42, 1.0, length + 0.3), yaw)


func _supply_dump(at: Vector3, yaw: float) -> void:
	# Stacked crates under a lashed tarp.
	if not _clear_of_keep(at, 1.5) or _inside_obstacle(at, 1.3):
		return
	var root := Node3D.new()
	root.name = "Tarped supply dump"
	root.position = at
	root.rotation.y = yaw
	level.add_child(root)
	var crates := [["wooden_military_crate", Vector3(0, 0, -0.35)], ["wooden_military_crate", Vector3(0, 0, 0.35)], ["wooden_military_crate", Vector3(0, 0.46, 0.0)]]
	for c in crates:
		var scene := PBR.model(c[0])
		if scene != null:
			var node := scene.instantiate() as Node3D
			node.position = c[1]
			node.rotation.y = PI * 0.5 + rng.randf_range(-0.06, 0.06)
			root.add_child(node)
	var tarp := MeshInstance3D.new()
	tarp.name = "Tarp"
	tarp.mesh = _draped_box(Vector3(0.95, 0.95, 1.55), rng.randi())
	tarp.material_override = PBR.material("hessian_230", 0.8, Color(0.28, 0.31, 0.22), true, "tarp")
	tarp.position = Vector3(0, 0.47, 0.3)
	root.add_child(tarp)
	_place_model("old_military_crate", at + Vector3(0.0, 0, 0.0).rotated(Vector3.UP, yaw) + Vector3(cos(yaw), 0, -sin(yaw)) * 1.3, yaw + 0.2, 0.9)
	_solid_box("Supply dump", at + Vector3(0, 0.55, 0), Vector3(1.1, 1.1, 1.9), yaw)


# ---------------------------------------------------------- street furniture

func _street_lamps() -> void:
	var spots: Array[Vector3] = []
	for z in range(190, -200, -26):
		spots.append(Vector3(-53.1 if (z / 26) % 2 == 0 else -43.1, 0, float(z)))
		spots.append(Vector3(17.1 if (z / 26) % 2 == 0 else 7.2, 0, float(z) - 13.0))
	for candidate in spots:
		var toward_center := Vector3(1.0 if candidate.x < -48.0 or (candidate.x > 0.0 and candidate.x < 12.0) else -1.0, 0, 0)
		var p := _snap_clear(candidate, toward_center, 0.35)
		if p == Vector3.INF or not _clear_of_keep(p, 1.0):
			continue
		_place_model("street_lamp_01", p, 0.0, 1.0)
		_solid_box("Lamp post", p + Vector3(0, 1.9, 0), Vector3(0.24, 3.8, 0.24), 0.0)


func _telegraph_line(from: Vector3, to: Vector3, poles: int, drop_side: float) -> void:
	var wood := PBR.material("old_planks_02", 1.5, Color(0.55, 0.47, 0.38), true, "pole")
	var porcelain := StandardMaterial3D.new()
	porcelain.albedo_color = Color(0.86, 0.85, 0.8)
	porcelain.roughness = 0.35
	var wire_material := StandardMaterial3D.new()
	wire_material.albedo_color = Color(0.08, 0.08, 0.08)
	wire_material.roughness = 0.6
	var tops: Array[Vector3] = []
	for i in range(poles):
		var p := _snap_clear(from.lerp(to, float(i) / float(poles - 1)), Vector3(-drop_side, 0, 0), 0.35)
		if p == Vector3.INF:
			continue
		var pole := MeshInstance3D.new()
		pole.name = "Telegraph pole"
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.1
		mesh.bottom_radius = 0.14
		mesh.height = 7.2
		mesh.radial_segments = 10
		pole.mesh = mesh
		pole.material_override = wood
		pole.position = p + Vector3(0, 3.6, 0)
		pole.rotation = Vector3(rng.randf_range(-0.02, 0.02), 0, rng.randf_range(-0.02, 0.02))
		level.add_child(pole)
		var arm := MeshInstance3D.new()
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(1.5, 0.1, 0.1)
		arm.mesh = arm_mesh
		arm.material_override = wood
		arm.position = p + Vector3(0, 6.7, 0)
		level.add_child(arm)
		for x in [-0.6, -0.2, 0.2, 0.6]:
			var insulator := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.025
			cyl.bottom_radius = 0.04
			cyl.height = 0.12
			cyl.radial_segments = 8
			insulator.mesh = cyl
			insulator.material_override = porcelain
			insulator.position = p + Vector3(x, 6.81, 0)
			level.add_child(insulator)
		tops.append(p + Vector3(0, 6.86, 0))
		_solid_box("Telegraph pole base", p + Vector3(0, 1.5, 0), Vector3(0.3, 3.0, 0.3), 0.0)
	for i in range(tops.size() - 1):
		for x in [-0.6, -0.2, 0.2, 0.6]:
			_wire(tops[i] + Vector3(x, 0, 0), tops[i + 1] + Vector3(x, 0, 0), 0.55, wire_material)
		# Service drop to the facade on the pole's side.
		if i % 2 == 0:
			var a := tops[i] + Vector3(0.6 * drop_side, 0, 0)
			_wire(a, a + Vector3(1.6 * drop_side, -1.7, 2.5), 0.2, wire_material)


func _wire(a: Vector3, b: Vector3, sag: float, material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 16
	var radius := 0.008
	var prev: Array[Vector3] = []
	for s in range(segments + 1):
		var t := float(s) / segments
		var p := a.lerp(b, t) + Vector3.DOWN * sag * 4.0 * t * (1.0 - t)
		var dir := (b - a).normalized()
		var side := dir.cross(Vector3.UP).normalized() * radius
		var up := Vector3.UP * radius
		var ring: Array[Vector3] = [p + side, p + up, p - side, p - up]
		if not prev.is_empty():
			for k in range(4):
				var k2 := (k + 1) % 4
				for v in [prev[k], ring[k], ring[k2], prev[k], ring[k2], prev[k2]]:
					st.add_vertex(v)
		prev = ring
	st.generate_normals()
	var wire := MeshInstance3D.new()
	wire.name = "Telegraph wire"
	wire.mesh = st.commit()
	wire.material_override = material
	wire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	level.add_child(wire)


func _trees() -> void:
	# Mature trees in wide crossings and yards; canopies overhang roofs.
	var spots := [
		Vector3(-60.5, 0, 162.0), Vector3(-9.5, 0, 160.0), Vector3(33.0, 0, 128.0), Vector3(58.5, 0, 95.0),
		Vector3(-38.0, 0, 61.0), Vector3(40.0, 0, 62.0), Vector3(-59.5, 0, -40.0), Vector3(58.0, 0, -44.0),
		Vector3(-31.5, 0, -105.0), Vector3(30.0, 0, -135.0), Vector3(-60.0, 0, -165.0), Vector3(-44.0, 0, -150.0),
		Vector3(24.0, 0, 5.0), Vector3(-24.0, 0, 30.0),
	]
	for p in spots:
		if _inside_obstacle(p, 0.6) or not _clear_of_keep(p, 1.0):
			continue
		var tree := TREE.instantiate() as Node3D
		tree.name = "Town tree"
		var s := rng.randf_range(0.42, 0.58)
		tree.scale = Vector3(s, s * rng.randf_range(0.95, 1.1), s)
		tree.rotation.y = rng.randf() * TAU
		tree.position = p
		level.add_child(tree)
		_solid_box("Tree trunk", p + Vector3(0, 1.5, 0), Vector3(0.6, 3.0, 0.6), 0.0)


func _ruin(area: Rect2, walls: Array, fire_at: Vector3) -> void:
	# A shelled house: jagged brick wall stubs, fallen beams, a heap of its
	# own masonry, scorched ground and a small fire still smouldering.
	var brick := PBR.material("broken_brick_wall", 2.0, Color(0.66, 0.6, 0.57))
	var inner := PBR.material("damaged_plaster", 2.4, Color(0.8, 0.76, 0.7))
	var x0 := area.position.x
	var z0 := area.position.y
	var x1 := area.end.x
	var z1 := area.end.y
	var specs := {
		"west": [Vector3(x0, 0, z0), Vector3(x0, 0, z1)],
		"west_half": [Vector3(x0, 0, z0), Vector3(x0, 0, lerpf(z0, z1, 0.5))],
		"south": [Vector3(x0, 0, z1), Vector3(x1, 0, z1)],
		"north": [Vector3(x0, 0, z0), Vector3(x1, 0, z0)],
		"north_half": [Vector3(x0, 0, z0), Vector3(lerpf(x0, x1, 0.55), 0, z0)],
	}
	for w in walls:
		var ends: Array = specs[w]
		var a: Vector3 = ends[0]
		var b: Vector3 = ends[1]
		var length := a.distance_to(b)
		var dir := (b - a).normalized()
		var yaw := atan2(dir.x, dir.z)
		var columns := int(length / 0.6)
		var height := rng.randf_range(2.6, 4.2)
		for c in range(columns):
			var t := (float(c) + 0.5) / float(columns)
			# Jagged top: a broken profile that dips where shells struck.
			var h := height * (0.55 + 0.45 * absf(sin(t * PI * rng.randf_range(1.2, 2.4)))) + rng.randf_range(-0.5, 0.3)
			h = clampf(h, 0.6, 4.6)
			var col := MeshInstance3D.new()
			col.name = "Ruin wall"
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.36, h, length / float(columns) + 0.02)
			col.mesh = mesh
			col.material_override = brick if c % 3 != 1 else inner
			col.position = a.lerp(b, t) + Vector3(0, h * 0.5, 0)
			col.rotation.y = yaw
			level.add_child(col)
			# Loose bricks spill from each broken column.
			for k in range(rng.randi_range(2, 6)):
				var p := col.position + Vector3(rng.randf_range(-1.2, 1.2), 0.0, rng.randf_range(-1.2, 1.2))
				p.y = 0.035
				_bricks.append(Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))), p))
		_solid_box("Ruin wall", (a + b) * 0.5 + Vector3(0, height * 0.5, 0), Vector3(0.4, height, length), yaw)
	var center := Vector3(area.get_center().x, 0, area.get_center().y)
	_rubble_heap(center + Vector3(rng.randf_range(-1.0, 1.0), 0, rng.randf_range(-1.5, 1.5)), minf(area.size.x, area.size.y) * 0.36, 0.7)
	_solid_box("Ruin rubble", center + Vector3(0, 0.25, 0), Vector3(area.size.x * 0.4, 0.5, area.size.y * 0.35), 0.0)
	for i in range(4):
		var beam := MeshInstance3D.new()
		beam.name = "Fallen roof beam"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.22, 0.22, rng.randf_range(3.0, 5.0))
		beam.mesh = mesh
		beam.material_override = PBR.material("old_planks_02", 1.5, Color(0.35, 0.3, 0.26), true, "charred")
		beam.position = center + Vector3(rng.randf_range(-2.0, 2.0), 0.6 + rng.randf() * 0.8, rng.randf_range(-3.0, 3.0))
		beam.rotation = Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.3, 0.3))
		level.add_child(beam)
	var fx := level.get_node_or_null("CombatFx")
	if fx != null:
		fx.place_static_decal(center + Vector3(0, 0.05, 0), Vector3.UP, "scorch", 6.0, Color(1, 1, 1, 0.9))
	_smoulder(fire_at)


func _smoulder(at: Vector3) -> void:
	# Low flames and a grey plume from burning timber.
	var fire_material := StandardMaterial3D.new()
	fire_material.albedo_texture = preload("res://scripts/fx/fx_textures.gd").get_texture("flash_star")
	fire_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fire_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fire_material.vertex_color_use_as_albedo = true
	var fire_quad := QuadMesh.new()
	fire_quad.size = Vector2(0.9, 1.3)
	fire_quad.material = fire_material
	var fire := CPUParticles3D.new()
	fire.name = "Smouldering fire"
	fire.mesh = fire_quad
	fire.amount = 26
	fire.lifetime = 0.9
	fire.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	fire.emission_box_extents = Vector3(0.7, 0.1, 0.5)
	fire.direction = Vector3.UP
	fire.spread = 12.0
	fire.gravity = Vector3(0, 1.2, 0)
	fire.initial_velocity_min = 0.4
	fire.initial_velocity_max = 1.0
	fire.angle_min = -30.0
	fire.angle_max = 30.0
	fire.scale_amount_min = 0.6
	fire.scale_amount_max = 1.3
	var flame_ramp := Gradient.new()
	flame_ramp.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	flame_ramp.colors = PackedColorArray([Color(1.0, 0.75, 0.35, 1.0), Color(1.0, 0.45, 0.12, 0.8), Color(0.3, 0.08, 0.02, 0.0)])
	fire.color_ramp = flame_ramp
	fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fire.position = at + Vector3(0, 0.35, 0)
	level.add_child(fire)
	var glow := OmniLight3D.new()
	glow.name = "Fire glow"
	glow.light_color = Color(1.0, 0.55, 0.22)
	glow.light_energy = 1.6
	glow.omni_range = 6.0
	glow.position = at + Vector3(0, 0.9, 0)
	level.add_child(glow)
	var smoke_material := StandardMaterial3D.new()
	smoke_material.albedo_texture = preload("res://scripts/fx/fx_textures.gd").get_texture("soft_puff")
	smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_material.vertex_color_use_as_albedo = true
	smoke_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	smoke_material.billboard_keep_scale = true
	var smoke_quad := QuadMesh.new()
	smoke_quad.material = smoke_material
	var smoke := CPUParticles3D.new()
	smoke.name = "Ruin smoke"
	smoke.mesh = smoke_quad
	smoke.amount = 24
	smoke.lifetime = 9.0
	smoke.preprocess = 9.0
	smoke.local_coords = false
	smoke.direction = Vector3.UP
	smoke.spread = 10.0
	smoke.gravity = Vector3(0.5, 0.6, 0.15)
	smoke.initial_velocity_min = 0.8
	smoke.initial_velocity_max = 1.4
	smoke.angle_min = -180.0
	smoke.angle_max = 180.0
	smoke.scale_amount_min = 1.5
	smoke.scale_amount_max = 2.5
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.5))
	grow.add_point(Vector2(1.0, 4.0))
	smoke.scale_amount_curve = grow
	var smoke_ramp := Gradient.new()
	smoke_ramp.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	smoke_ramp.colors = PackedColorArray([Color(0.2, 0.19, 0.18, 0.0), Color(0.22, 0.21, 0.2, 0.6), Color(0.45, 0.45, 0.46, 0.0)])
	smoke.color_ramp = smoke_ramp
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	smoke.position = at + Vector3(0, 1.0, 0)
	level.add_child(smoke)


func _contact_room() -> void:
	# The upstairs contact's desk gains a field radio and an oil lamp.
	_place_model("vintage_radio_transceiver", Vector3(2.85, 3.825, -29.55), 0.25, 1.0)
	_place_model("vintage_oil_lamp", Vector3(4.45, 3.825, -29.6), 0.0, 0.9)
	var shelf := PBR.model("wooden_bookshelf_worn")
	if shelf != null:
		var node := shelf.instantiate() as Node3D
		node.position = Vector3(-5.6, 3.15, -30.5)
		node.rotation.y = PI * 0.5
		level.add_child(node)


# ----------------------------------------------------------------- helpers

func _place_model(id: String, at: Vector3, yaw: float, scale: float, solid_size: Vector3 = Vector3.ZERO) -> void:
	var scene := PBR.model(id)
	if scene == null:
		return
	var node := scene.instantiate() as Node3D
	node.name = id
	node.position = at
	node.rotation.y = yaw
	node.scale = Vector3.ONE * scale
	level.add_child(node)
	if solid_size != Vector3.ZERO:
		_solid_box(id, at + Vector3(0, solid_size.y * 0.5, 0), solid_size * scale, yaw)


func _solid_box(label: String, center: Vector3, size: Vector3, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.name = label
	var surface := "dirt"
	if label.contains("Lamp"):
		surface = "metal"
	elif label.contains("dump") or label.contains("bench") or label.contains("crate") or label.contains("pole") or label.contains("Tree"):
		surface = "wood"
	body.set_meta("surface", surface)
	level.add_child(body)
	body.position = center
	body.rotation.y = yaw
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	# Axis-aligned footprint for the guard path grid.
	var ex := absf(cos(yaw)) * size.x * 0.5 + absf(sin(yaw)) * size.z * 0.5
	var ez := absf(sin(yaw)) * size.x * 0.5 + absf(cos(yaw)) * size.z * 0.5
	obstacles.append(Rect2(Vector2(center.x - ex, center.z - ez), Vector2(ex * 2.0, ez * 2.0)))


func _snap_clear(p: Vector3, step_dir: Vector3, margin: float) -> Vector3:
	# Slide a point off any house footprint toward the street, up to 3 m.
	var q := p
	for i in range(13):
		if not _inside_obstacle(q, margin):
			return q
		q += step_dir * 0.25
	return Vector3.INF


func _near_door(p: Vector3, radius: float) -> bool:
	for d in _doors:
		if Vector2(p.x - d.x, p.z - d.z).length() < radius:
			return true
	return false


func _clear_of_keep(p: Vector3, margin: float) -> bool:
	for r in KEEP_CLEAR:
		if (r as Rect2).grow(margin).has_point(Vector2(p.x, p.z)):
			return false
	return not _near_door(p, 1.0)


func _inside_obstacle(p: Vector3, margin: float) -> bool:
	for r in obstacles:
		if r.grow(margin).has_point(Vector2(p.x, p.z)):
			return true
	return false


func _flush_multimeshes() -> void:
	var brick_mesh := BoxMesh.new()
	brick_mesh.size = Vector3(0.21, 0.065, 0.1)
	_multimesh("Loose bricks", brick_mesh, PBR.material("medieval_red_brick", 0.5, Color(0.8, 0.72, 0.68)), _bricks, 120.0)
	_multimesh("Loose stones", _rock_mesh(), PBR.material("rock_wall_13", 0.6), _stones, 120.0)
	var plank_mesh := BoxMesh.new()
	plank_mesh.size = Vector3(0.2, 0.035, 2.2)
	_multimesh("Broken planks", plank_mesh, PBR.material("old_planks_02", 1.0, Color(0.6, 0.55, 0.5)), _planks, 160.0)
	var bag_material := PBR.material("hessian_230", 0.5, Color(0.7, 0.62, 0.48), true, "sandbag")
	_multimesh("Sandbags", _sandbag_mesh(), bag_material, _sandbags, 220.0)
	_multimesh("Grass tufts", _tuft_mesh(), _tuft_material(), _tufts, 60.0, false)
	for index in _weeds.keys():
		var entry: Dictionary = _weed_meshes[index]
		# Plant set meshes carry their own placement offset; strip it so each
		# instance sits at the scattered point.
		var local: Transform3D = entry.transform
		var strip := Transform3D(local.basis, Vector3.ZERO)
		var list: Array[Transform3D] = []
		for t in _weeds[index]:
			list.append(t * strip)
		_multimesh("Weeds " + String(entry.name), entry.mesh, null, list, 70.0, false)


func _multimesh(label: String, mesh: Mesh, material: Material, list: Array[Transform3D], view_distance: float, shadows: bool = true) -> void:
	# Split into 32 m cells, each MultiMeshInstance centered on its cell, so
	# frustum culling and visibility ranges (measured from the node origin)
	# work per neighbourhood instead of for the whole town at once.
	var cells: Dictionary = {}
	for t in list:
		var key := Vector2i(floori(t.origin.x / 32.0), floori(t.origin.z / 32.0))
		if not cells.has(key):
			cells[key] = []
		cells[key].append(t)
	for key in cells.keys():
		var center := Vector3((key.x + 0.5) * 32.0, 0.0, (key.y + 0.5) * 32.0)
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
		if material != null:
			instance.material_override = material
		instance.position = center
		instance.visibility_range_end = view_distance
		instance.visibility_range_end_margin = 10.0
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		if not shadows:
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		level.add_child(instance)


func _tuft_mesh() -> ArrayMesh:
	# Three crossed cards, 0.5 m wide and 0.42 m tall, normals pointing up so
	# both faces light like a soft clump instead of dark backfaces.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(3):
		var a := PI * float(k) / 3.0
		var d := Vector3(cos(a), 0.0, sin(a)) * 0.25
		var quad := [-d, d, d + Vector3(0, 0.42, 0), -d + Vector3(0, 0.42, 0)]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(uvs[idx])
			st.add_vertex(quad[idx])
	return st.commit()


func _tuft_material() -> StandardMaterial3D:
	var image := Image.create(128, 128, true, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var blade_rng := RandomNumberGenerator.new()
	blade_rng.seed = 4242
	for b in range(46):
		var root_x := blade_rng.randf_range(10.0, 118.0)
		var lean := blade_rng.randf_range(-26.0, 26.0)
		var height := blade_rng.randf_range(55.0, 124.0)
		var width := blade_rng.randf_range(1.6, 3.4)
		var dry := blade_rng.randf() < 0.3
		for yy in range(int(height)):
			var t := float(yy) / height
			var x := root_x + lean * t * t
			var w := width * (1.0 - t * 0.85)
			var shade := lerpf(0.45, 1.0, t)
			var col := Color(0.62, 0.58, 0.32) if dry else Color(0.3, 0.42, 0.16)
			col = col * shade
			for xx in range(int(x - w), int(x + w) + 1):
				if xx >= 0 and xx < 128:
					image.set_pixel(xx, 127 - yy, Color(col.r, col.g, col.b, 1.0))
	image.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(image)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m


func _sandbag_mesh() -> ArrayMesh:
	# A filled hessian bag: a subdivided box pulled toward an ellipsoid, so
	# the ends stay square-ish while the faces bulge.
	var box := BoxMesh.new()
	box.size = Vector3(0.62, 0.2, 0.34)
	box.subdivide_width = 6
	box.subdivide_height = 2
	box.subdivide_depth = 4
	var arrays := box.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var half := Vector3(0.31, 0.1, 0.17)
	for i in range(verts.size()):
		var v := verts[i]
		var n := Vector3(v.x / half.x, v.y / half.y, v.z / half.z)
		var e := n / maxf(n.length(), 0.001)
		var rounded := Vector3(e.x * half.x, e.y * half.y, e.z * half.z)
		verts[i] = v.lerp(rounded, 0.45) + Vector3(0, -0.012 * absf(n.x), 0)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = null
	arrays[Mesh.ARRAY_TANGENT] = null
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st := SurfaceTool.new()
	st.create_from(mesh, 0)
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


func _rock_mesh() -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.14
	sphere.radial_segments = 7
	sphere.rings = 4
	var arrays := sphere.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var noise := RandomNumberGenerator.new()
	noise.seed = 77
	for i in range(verts.size()):
		verts[i] *= noise.randf_range(0.75, 1.2)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _mound_mesh(radius: float, height: float, seed_value: int) -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 1.6
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 8
	var sectors := 18
	var grid: Array = []
	for r in range(rings + 1):
		var row: Array[Vector3] = []
		var t := float(r) / rings
		for s in range(sectors):
			var a := TAU * float(s) / sectors
			var rr := radius * t * (1.0 + noise.get_noise_2d(cos(a) * 3.0, sin(a) * 3.0) * 0.25)
			var y := height * (1.0 - t * t) * (1.0 + noise.get_noise_2d(cos(a) * rr * 2.0, sin(a) * rr * 2.0) * 0.35)
			row.append(Vector3(cos(a) * rr, maxf(y, 0.0) - 0.02, sin(a) * rr))
		grid.append(row)
	for r in range(rings):
		for s in range(sectors):
			var s2 := (s + 1) % sectors
			var a: Vector3 = grid[r][s]
			var b: Vector3 = grid[r][s2]
			var c: Vector3 = grid[r + 1][s]
			var d: Vector3 = grid[r + 1][s2]
			for v in [a, c, b, b, c, d]:
				st.set_uv(Vector2(v.x, v.z))
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()


func _draped_box(size: Vector3, seed_value: int) -> ArrayMesh:
	var box := BoxMesh.new()
	box.size = size
	box.subdivide_width = 6
	box.subdivide_height = 6
	box.subdivide_depth = 8
	var arrays := box.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 2.2
	for i in range(verts.size()):
		var v := verts[i]
		var sag := 0.0
		if v.y > size.y * 0.45:
			sag = -0.05 * (1.0 - absf(v.x) / (size.x * 0.5))
		var n := noise.get_noise_3dv(v * 2.0) * 0.045
		var outward := Vector3(signf(v.x) * 0.03, 0.0, signf(v.z) * 0.03)
		# Tarp skirt flares slightly near the ground.
		if v.y < -size.y * 0.3:
			outward *= 2.0
		verts[i] = v + Vector3(n, n * 0.5 + sag, n) + outward
	arrays[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
