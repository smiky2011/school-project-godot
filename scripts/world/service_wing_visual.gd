extends RefCounted

# Compact passage/service buildings. The wall, trim, glazing, timber and roof
# each become one mesh surface per wing; town_level.gd keeps collision/nav.

const STONE_BASE: Texture2D = preload("res://assets/environment/textures/stone_base.jpg")
const STONE_NORM: Texture2D = preload("res://assets/environment/textures/stone_normal.png")
const STONE_ROUGH: Texture2D = preload("res://assets/environment/textures/stone_rough.png")
const PLASTER_BASE: Texture2D = preload("res://assets/environment/textures/plaster_base.jpg")
const PLASTER_NORM: Texture2D = preload("res://assets/environment/textures/plaster_normal.png")
const PLASTER_ROUGH: Texture2D = preload("res://assets/environment/textures/plaster_rough.png")
const SLATE_BASE: Texture2D = preload("res://assets/environment/textures/slate_base.png")
const SLATE_NORM: Texture2D = preload("res://assets/environment/textures/slate_normal.png")
const SLATE_ROUGH: Texture2D = preload("res://assets/environment/textures/slate_rough.png")
const OAK_BASE: Texture2D = preload("res://assets/environment/textures/oak_base.jpg")
const OAK_NORM: Texture2D = preload("res://assets/environment/textures/oak_normal.png")
const OAK_ROUGH: Texture2D = preload("res://assets/environment/textures/oak_rough.png")
const SHUTTER_BASE: Texture2D = preload("res://assets/environment/textures/shutter_base.jpg")
const SHUTTER_NORM: Texture2D = preload("res://assets/environment/textures/shutter_normal.png")
const SHUTTER_ROUGH: Texture2D = preload("res://assets/environment/textures/shutter_rough.png")

static var _stone: StandardMaterial3D
static var _plaster: StandardMaterial3D
static var _slate: StandardMaterial3D
static var _wood: StandardMaterial3D
static var _shutter: StandardMaterial3D
static var _glass: StandardMaterial3D


static func add_shell(parent: Node3D, label: String, base: Vector3, size: Vector3, plaster: bool) -> void:
	_init_materials()
	var wing := Node3D.new()
	wing.name = label + " purpose-built service wing"
	wing.position = base
	parent.add_child(wing)
	var wall := _start(_plaster if plaster else _stone)
	var trim := _start(_stone)
	var slate := _start(_slate)
	var wood := _start(_wood)
	var shutters := _start(_shutter)
	var glazing := _start(_glass)
	var w: float = size.x
	var d: float = size.z
	var h: float = size.y
	var t := 0.28
	# The long sides receive four human-scale window bays. The side walls are
	# actually interrupted around the recessed glazing, not covered by decals.
	for side in [-1.0, 1.0]:
		var count := clampi(int(floor((d - 1.0) / 3.4)), 2, 4)
		var pitch := d / float(count)
		for i in range(count):
			var z: float = -d * 0.5 + (float(i) + 0.5) * pitch
			var opening := minf(1.04, pitch - 0.7)
			var pier := (pitch - opening) * 0.5
			for pz in [z - opening * 0.5 - pier * 0.5, z + opening * 0.5 + pier * 0.5]:
				_box(wall, Vector3(side * (w * 0.5 - t * 0.5), h * 0.5, pz), Vector3(t, h, pier))
			_side_opening(wall, trim, shutters, glazing, side, w, z, opening, h)
	# Each end has a genuinely closed entrance. Wide service bays use flanking
	# windows; the 2.5–3.6 m bays use one upper window above the door.
	for end in [-1.0, 1.0]:
		var centres: Array[float] = [0.0]
		if w >= 6.0:
			centres = [-2.1, 0.0, 2.1]
		var cursor := -w * 0.5
		for cx in centres:
			var opening: float = 1.05 if cx == 0.0 else 0.92
			var left: float = cx - opening * 0.5
			if left > cursor:
				_box(wall, Vector3((cursor + left) * 0.5, h * 0.5, end * (d * 0.5 - t * 0.5)), Vector3(left - cursor, h, t))
			_end_opening(wall, trim, wood, glazing, end, d, cx, opening, h, cx == 0.0)
			cursor = cx + opening * 0.5
		if cursor < w * 0.5:
			_box(wall, Vector3((cursor + w * 0.5) * 0.5, h * 0.5, end * (d * 0.5 - t * 0.5)), Vector3(w * 0.5 - cursor, h, t))
	# A shallow stone plinth and projecting course catch light along the lane.
	for side in [-1.0, 1.0]:
		_box(trim, Vector3(side * (w * 0.5 + 0.025), 0.22, 0), Vector3(0.10, 0.44, d + 0.08))
		_box(trim, Vector3(side * (w * 0.5 + 0.03), h - 0.10, 0), Vector3(0.13, 0.17, d + 0.15))
	var rise := 0.72 if w < 4.0 else 1.08
	var half_span := w * 0.5 + 0.37
	var pitch_angle := atan2(rise, half_span)
	var roof_length := sqrt(half_span * half_span + rise * rise)
	for side in [-1.0, 1.0]:
		_rotated_box(slate, Vector3(side * half_span * 0.5, h + rise * 0.5, 0),
			Vector3(roof_length + 0.12, 0.16, d + 0.72), -side * pitch_angle)
		_box(wood, Vector3(side * (w * 0.5 + 0.32), h - 0.05, 0), Vector3(0.10, 0.20, d + 0.70))
	for end in [-1.0, 1.0]:
		var z: float = end * d * 0.5
		_triangle(wall, Vector3(-w * 0.5, h - 0.01, z), Vector3(w * 0.5, h - 0.01, z), Vector3(0, h + rise, z), Vector3(0, 0, end))
		_box(wood, Vector3(0, h + rise + 0.04, end * (d * 0.5 + 0.36)), Vector3(0.11, 0.11, 0.12))
	# One chimney on the wider wing gives the passage an asymmetrical roofline.
	if w >= 6.0:
		_box(trim, Vector3(w * 0.26, h + 0.95, -d * 0.22), Vector3(0.64, 1.65, 0.68))
		_box(trim, Vector3(w * 0.26, h + 1.82, -d * 0.22), Vector3(0.80, 0.16, 0.83))
	_finish(wing, "Masonry with deep openings", wall)
	_finish(wing, "Dressed stone and chimney", trim)
	_finish(wing, "Pitched slate roof", slate)
	_finish(wing, "Closed timber doors and fascia", wood)
	_finish(wing, "Window shutters", shutters)
	_finish(wing, "Recessed glazing", glazing)


static func _side_opening(wall: SurfaceTool, trim: SurfaceTool, shutters: SurfaceTool, glazing: SurfaceTool,
		side: float, w: float, z: float, span: float, h: float) -> void:
	var x: float = side * (w * 0.5 - 0.14)
	var windows := [[1.38, 2.55]]
	if h >= 4.5:
		windows.append([3.05, minf(4.12, h - 0.25)])
	var bottom := 0.0
	for level in windows:
		var low: float = level[0]
		var high: float = level[1]
		_box(wall, Vector3(x, (bottom + low) * 0.5, z), Vector3(0.28, low - bottom, span))
		var cy: float = (low + high) * 0.5
		var height: float = high - low
		_box(glazing, Vector3(side * (w * 0.5 - 0.22), cy, z), Vector3(0.045, height - 0.09, span - 0.09))
		for edge_z in [z - span * 0.5, z + span * 0.5]:
			_box(trim, Vector3(side * (w * 0.5 + 0.055), cy, edge_z), Vector3(0.12, height + 0.08, 0.10))
		for edge_y in [low, high]:
			_box(trim, Vector3(side * (w * 0.5 + 0.07), edge_y, z), Vector3(0.14, 0.10, span + 0.18))
		for edge_z in [z - span * 0.5 - 0.16, z + span * 0.5 + 0.16]:
			_box(shutters, Vector3(side * (w * 0.5 + 0.075), cy, edge_z), Vector3(0.09, height - 0.03, 0.27))
		bottom = high
	if bottom < h:
		_box(wall, Vector3(x, (bottom + h) * 0.5, z), Vector3(0.28, h - bottom, span))


static func _end_opening(wall: SurfaceTool, trim: SurfaceTool, wood: SurfaceTool, glazing: SurfaceTool,
		end: float, d: float, cx: float, span: float, h: float, door: bool) -> void:
	var z: float = end * (d * 0.5 - 0.14)
	var low: float = 2.30 if door else 1.38
	if not door:
		_box(wall, Vector3(cx, low * 0.5, z), Vector3(span, low, 0.28))
		_box(glazing, Vector3(cx, 1.97, end * (d * 0.5 - 0.22)), Vector3(span - 0.08, 1.07, 0.045))
		for x in [cx - span * 0.5, cx + span * 0.5]:
			_box(trim, Vector3(x, 1.97, end * (d * 0.5 + 0.055)), Vector3(0.10, 1.22, 0.12))
		_box(trim, Vector3(cx, 2.58, end * (d * 0.5 + 0.06)), Vector3(span + 0.20, 0.13, 0.14))
	else:
		_box(wood, Vector3(cx, 1.11, end * (d * 0.5 - 0.12)), Vector3(span - 0.08, 2.22, 0.09))
		for x in [cx - span * 0.5, cx + span * 0.5]:
			_box(trim, Vector3(x, 1.14, end * (d * 0.5 + 0.055)), Vector3(0.11, 2.28, 0.13))
		_box(trim, Vector3(cx, 2.31, end * (d * 0.5 + 0.065)), Vector3(span + 0.22, 0.13, 0.15))
	var upper_low := 3.08
	var upper_high := minf(4.10, h - 0.24)
	var lower_opening_top: float = low if door else 2.55
	if upper_high <= upper_low:
		_box(wall, Vector3(cx, (lower_opening_top + h) * 0.5, z), Vector3(span, h - lower_opening_top, 0.28))
		return
	_box(wall, Vector3(cx, (lower_opening_top + upper_low) * 0.5, z), Vector3(span, upper_low - lower_opening_top, 0.28))
	_box(glazing, Vector3(cx, (upper_low + upper_high) * 0.5, end * (d * 0.5 - 0.22)),
		Vector3(span - 0.10, upper_high - upper_low - 0.08, 0.045))
	_box(wall, Vector3(cx, (upper_high + h) * 0.5, z), Vector3(span, h - upper_high, 0.28))
	for x in [cx - span * 0.5, cx + span * 0.5]:
		_box(trim, Vector3(x, (upper_low + upper_high) * 0.5, end * (d * 0.5 + 0.055)),
			Vector3(0.10, upper_high - upper_low + 0.10, 0.12))
	for y in [upper_low, upper_high]:
		_box(trim, Vector3(cx, y, end * (d * 0.5 + 0.06)), Vector3(span + 0.18, 0.10, 0.14))


static func _init_materials() -> void:
	if _stone != null:
		return
	_stone = _pbr(STONE_BASE, STONE_NORM, STONE_ROUGH, Color(0.77, 0.76, 0.72), 2.4)
	_plaster = _pbr(PLASTER_BASE, PLASTER_NORM, PLASTER_ROUGH, Color(0.78, 0.76, 0.70), 2.4)
	_slate = _pbr(SLATE_BASE, SLATE_NORM, SLATE_ROUGH, Color(0.68, 0.71, 0.73), 1.5)
	_wood = _pbr(OAK_BASE, OAK_NORM, OAK_ROUGH, Color(0.54, 0.48, 0.41), 1.5)
	_shutter = _pbr(SHUTTER_BASE, SHUTTER_NORM, SHUTTER_ROUGH, Color(0.62, 0.66, 0.65), 1.4)
	_glass = StandardMaterial3D.new()
	_glass.albedo_color = Color(0.18, 0.23, 0.25)
	_glass.metallic = 0.16
	_glass.roughness = 0.32


static func _pbr(base: Texture2D, normal: Texture2D, rough: Texture2D, tint: Color, scale: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = base
	material.albedo_color = tint
	material.normal_enabled = true
	material.normal_texture = normal
	material.normal_scale = 0.65
	material.roughness_texture = rough
	material.roughness = 1.0
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / scale
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


static func _start(material: Material) -> SurfaceTool:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	return surface


static func _finish(parent: Node3D, label: String, surface: SurfaceTool) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	visual.mesh = surface.commit()
	parent.add_child(visual)


static func _box(surface: SurfaceTool, center: Vector3, size: Vector3) -> void:
	_rotated_box(surface, center, size, 0.0)


static func _rotated_box(surface: SurfaceTool, center: Vector3, size: Vector3, angle: float) -> void:
	var x: float = size.x * 0.5
	var y: float = size.y * 0.5
	var z: float = size.z * 0.5
	var faces := [
		[Vector3(-x, -y, z), Vector3(x, -y, z), Vector3(x, y, z), Vector3(-x, y, z)],
		[Vector3(x, -y, -z), Vector3(-x, -y, -z), Vector3(-x, y, -z), Vector3(x, y, -z)],
		[Vector3(x, -y, z), Vector3(x, -y, -z), Vector3(x, y, -z), Vector3(x, y, z)],
		[Vector3(-x, -y, -z), Vector3(-x, -y, z), Vector3(-x, y, z), Vector3(-x, y, -z)],
		[Vector3(-x, y, z), Vector3(x, y, z), Vector3(x, y, -z), Vector3(-x, y, -z)],
		[Vector3(-x, -y, -z), Vector3(x, -y, -z), Vector3(x, -y, z), Vector3(-x, -y, z)]
	]
	for face in faces:
		var points: Array[Vector3] = []
		for p in face:
			points.append(Vector3(p.x * cos(angle) - p.y * sin(angle), p.x * sin(angle) + p.y * cos(angle), p.z) + center)
		_quad(surface, points[0], points[1], points[2], points[3])


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	# Godot treats clockwise triangles as front faces. Keep the shading normal
	# outward while reversing the geometric cross-product winding.
	if (b - a).cross(c - a).dot(normal) > 0.0:
		var swap := a
		a = b
		b = swap
	for p in [a, b, c]:
		surface.set_normal(normal)
		surface.set_uv(Vector2(p.x / 2.4, p.y / 2.4))
		surface.add_vertex(p)


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	for p in [a, c, b, a, d, c]:
		surface.set_normal(normal)
		surface.set_uv(Vector2(p.x / 2.4, p.z / 2.4))
		surface.add_vertex(p)
