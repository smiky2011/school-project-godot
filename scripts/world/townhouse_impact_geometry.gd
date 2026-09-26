extends RefCounted

# Cosmetic impact receiver for the two imported exterior houses. The Blender
# recipe and this resolver read the same authored facade measurements. Gameplay
# still raycasts against the old broad collision mass; no projectile, AI or
# navigation rule changes here.
const FACADE_DATA := "res://assets/environment/townhouse_facades.json"
const EDGE_GAP := 0.035
static var _spec: Dictionary = {}


static func resolve(at: Vector3, normal: Vector3, collider: Object, mark_size: float, incoming_dir: Vector3 = Vector3.ZERO) -> Dictionary:
	var unchanged := {"position": at, "visible": true, "kind": "flush"}
	if not (collider is Node):
		return unchanged
	var body := collider as Node
	if body.has_meta("impact_hidden_roof"):
		return {"position": at, "visible": false, "kind": "hidden_roof"}
	if not body.has_meta("impact_shell"):
		return unchanged
	var shell: Dictionary = body.get_meta("impact_shell")
	var spec := _get_spec()
	if spec.is_empty() or not shell.has("transform") or not shell.has("style"):
		return {"position": at, "visible": false, "kind": "missing_geometry"}
	var style := str(shell.style)
	if not spec.has(style):
		return {"position": at, "visible": false, "kind": "unknown_style"}
	var transform: Transform3D = shell.transform
	var scale := transform.basis.get_scale()
	if minf(scale.x, minf(scale.y, scale.z)) <= 0.0:
		return {"position": at, "visible": false, "kind": "bad_scale"}
	# B^T maps a world face normal back into the imported mesh's axes, even
	# when the instance is rotated and scaled differently along each axis.
	var local_normal := (transform.basis.transposed() * normal).normalized()
	var face_is_z := absf(local_normal.z) > 0.95
	var face_is_x := absf(local_normal.x) > 0.95
	if not face_is_x and not face_is_z:
		return {"position": at, "visible": false, "kind": "non_wall"}
	var incoming := incoming_dir.normalized() if incoming_dir.length_squared() > 0.0001 else -normal
	var incidence := incoming.dot(normal)
	if incidence > -0.15:
		return {"position": at, "visible": false, "kind": "grazing"}
	var outward_scale := scale.z if face_is_z else scale.x
	var travel := float(spec.wall_half_thickness) * outward_scale / incidence
	# Project backward along the actual shot line to its visible wall plane.
	# At oblique incidence a pure normal shift would make the mark miss the aim.
	var visual_at := at + incoming * travel
	var local := transform.affine_inverse() * visual_at
	var half_width: float = mark_size * 0.5 + EDGE_GAP
	var mx := half_width / (scale.x if face_is_z else scale.z)
	var my := half_width / scale.y
	var across := local.x if face_is_z else -local.z # Blender Y -> Godot -Z.
	var edge := float(spec.half_width) if face_is_z else float(spec.half_depth)
	if absf(across) > edge - mx or local.y < my or local.y > float(spec[style].eaves) - my:
		return {"position": at, "visible": false, "kind": "wall_edge"}
	if _in_opening(across, local.y, local_normal, spec, style, mx, my):
		# The broad collider sits behind actual recessed glass/wood. Until
		# those leaves have matching receivers, omit a floating masonry mark.
		return {"position": at, "visible": false, "kind": "opening"}
	return {"position": visual_at, "visible": true, "kind": "masonry"}


static func _get_spec() -> Dictionary:
	if _spec.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FACADE_DATA))
		if parsed is Dictionary:
			_spec = parsed
	return _spec


static func _in_opening(across: float, height: float, normal: Vector3, spec: Dictionary, style: String, mx: float, my: float) -> bool:
	if normal.z < -0.95:
		return false # Rear facade has no openings in the authored model.
	if normal.z > 0.95:
		var front: Dictionary = spec.front
		var variant: Dictionary = spec[style]
		if _within(across, height, float(variant.front_door_center), float(front.door_half_width), front.door_y, mx, my):
			return true
		for center in variant.front_lower_window_centers:
			if _within(across, height, float(center), float(front.lower_window_half_width), front.lower_window_y, mx, my):
				return true
		for center in front.upper_window_centers:
			if _within(across, height, float(center), float(front.upper_window_half_width), front.upper_window_y, mx, my):
				return true
		return false
	var side: Dictionary = spec.side
	for bay in side.bay_centers:
		var door := normal.x > 0.95 and is_equal_approx(float(bay), float(side.door_bay))
		var half_width := float(side.door_half_width) if door else float(side.lower_window_half_width)
		var y_span: Array = side.door_y if door else side.lower_window_y
		if _within(across, height, float(bay), half_width, y_span, mx, my):
			return true
		if _within(across, height, float(bay), float(side.upper_window_half_width), side.upper_window_y, mx, my):
			return true
	return false


static func _within(x: float, y: float, center: float, half_width: float, y_span: Array, mx: float, my: float) -> bool:
	return absf(x - center) <= half_width + mx and y >= float(y_span[0]) - my and y <= float(y_span[1]) + my
