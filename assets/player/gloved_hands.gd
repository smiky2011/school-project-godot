extends Node3D

# Authored CC0 MakeHuman skin hands are posed around the Sten; only the cloth
# sleeves and cuff rings are generated here to conceal the cut wrists.
const LEFT_HAND: PackedScene = preload("res://assets/player/hands/hand_left_grip.glb")
const RIGHT_HAND: PackedScene = preload("res://assets/player/hands/hand_right_grip.glb")

var support_hand: Node3D


func _ready() -> void:
	name = "FirstPersonHands"
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.22, 0.235, 0.19)
	cloth.roughness = 0.98
	var cuff := StandardMaterial3D.new()
	cuff.albedo_color = Color(0.135, 0.145, 0.115)
	cuff.roughness = 0.94

	var trigger := Node3D.new()
	trigger.name = "TriggerHand"
	add_child(trigger)
	_tube(trigger, "TriggerSleeve", [Vector3(0.34, -0.49, 0.31), Vector3(0.13, -0.23, 0.16), Vector3(0.0, -0.005, 0.03)], [Vector2(0.075, 0.068), Vector2(0.064, 0.057), Vector2(0.038, 0.037)], cloth)
	_tube(trigger, "TriggerCuff", [Vector3(0.014, -0.032, 0.045), Vector3(0.0, -0.003, 0.03)], [Vector2(0.043, 0.041), Vector2(0.040, 0.039)], cuff)
	var right := RIGHT_HAND.instantiate() as Node3D
	right.name = "MakeHumanRightGrip"
	right.position = Vector3(0.0, -0.005, 0.03)
	right.basis = Basis(Vector3.RIGHT, deg_to_rad(30.0)) * Basis(Vector3.UP, PI)
	trigger.add_child(right)
	_configure_viewmodel_hand(right)

	support_hand = Node3D.new()
	support_hand.name = "SupportHand"
	add_child(support_hand)
	_tube(support_hand, "SupportSleeve", [Vector3(-0.37, -0.48, 0.17), Vector3(-0.25, -0.17, 0.08), Vector3(-0.15, 0.065, 0.04)], [Vector2(0.078, 0.071), Vector2(0.063, 0.058), Vector2(0.038, 0.037)], cloth)
	_tube(support_hand, "SupportCuff", [Vector3(-0.163, 0.038, 0.052), Vector3(-0.15, 0.067, 0.04)], [Vector2(0.044, 0.042), Vector2(0.040, 0.039)], cuff)
	var left := LEFT_HAND.instantiate() as Node3D
	left.name = "MakeHumanLeftGrip"
	left.position = Vector3(-0.15, 0.065, 0.04)
	left.basis = Basis(Vector3.RIGHT, deg_to_rad(30.0)) * Basis(Vector3.UP, PI)
	support_hand.add_child(left)
	_configure_viewmodel_hand(left)


func _configure_viewmodel_hand(node: Node) -> void:
	# Camera-bound hands sit against the gun: normal scene shadows produce
	# stippled self-shadow artifacts at this close range.
	if node is MeshInstance3D:
		var part := node as MeshInstance3D
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in range(part.mesh.get_surface_count()):
			var source := part.get_active_material(surface) as BaseMaterial3D
			if source != null:
				var material := source.duplicate() as BaseMaterial3D
				material.disable_receive_shadows = true
				part.set_surface_override_material(surface, material)
	for child in node.get_children():
		_configure_viewmodel_hand(child)


func _tube(parent: Node3D, label: String, points: Array, radii: Array, material: Material) -> void:
	const SIDES := 12
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for ring in range(points.size()):
		var tangent: Vector3
		if ring == 0:
			tangent = (points[1] - points[0]).normalized()
		elif ring == points.size() - 1:
			tangent = (points[ring] - points[ring - 1]).normalized()
		else:
			tangent = (points[ring + 1] - points[ring - 1]).normalized()
		var reference := Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.92 else Vector3.RIGHT
		var axis_a := tangent.cross(reference).normalized()
		var axis_b := tangent.cross(axis_a).normalized()
		for side in range(SIDES):
			var angle := TAU * float(side) / float(SIDES)
			var radial: Vector3 = axis_a * cos(angle) * radii[ring].x + axis_b * sin(angle) * radii[ring].y
			vertices.append(points[ring] + radial)
			normals.append(radial.normalized())
	for ring in range(points.size() - 1):
		for side in range(SIDES):
			var a := ring * SIDES + side
			var b := ring * SIDES + (side + 1) % SIDES
			var c := (ring + 1) * SIDES + side
			var d := (ring + 1) * SIDES + (side + 1) % SIDES
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	parent.add_child(instance)
