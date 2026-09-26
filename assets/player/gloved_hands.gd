extends Node3D

# Authored CC0 MakeHuman skin hands are posed around the StG 44; only the cloth
# sleeves and cuff rings are generated here to conceal the cut wrists.
const LEFT_HAND: PackedScene = preload("res://assets/player/hands/hand_left_grip.glb")
const RIGHT_HAND: PackedScene = preload("res://assets/player/hands/hand_right_grip.glb")

var support_hand: Node3D


func _ready() -> void:
	name = "FirstPersonHands"
	# Woven wool: the CC0 hessian scan's normal map at a fine scale gives the
	# weave; albedo stays a plain olive drab so no faction is implied.
	var weave: Texture2D = load("res://assets/vendor/polyhaven_cc0/texture/hessian_230/hessian_230_nor_gl_1k.jpg")
	var fibre: Texture2D = load("res://assets/vendor/polyhaven_cc0/texture/hessian_230/hessian_230_diff_1k.jpg")
	var cloth := StandardMaterial3D.new()
	cloth.albedo_texture = fibre
	cloth.albedo_color = Color(0.36, 0.36, 0.27)
	cloth.normal_enabled = weave != null
	cloth.normal_texture = weave
	cloth.normal_scale = 0.8
	cloth.uv1_scale = Vector3(3.0, 5.0, 1.0)
	cloth.roughness = 1.0
	var cuff := cloth.duplicate() as StandardMaterial3D
	cuff.albedo_color = Color(0.24, 0.24, 0.18)

	var trigger := Node3D.new()
	trigger.name = "TriggerHand"
	add_child(trigger)
	_tube(trigger, "TriggerSleeve", [Vector3(0.34, -0.49, 0.40), Vector3(0.14, -0.23, 0.24), Vector3(0.0, -0.005, 0.13)], [Vector2(0.075, 0.068), Vector2(0.064, 0.057), Vector2(0.038, 0.037)], cloth)
	_tube(trigger, "TriggerCuff", [Vector3(0.014, -0.032, 0.145), Vector3(0.0, -0.003, 0.13)], [Vector2(0.043, 0.041), Vector2(0.040, 0.039)], cuff)
	var right := RIGHT_HAND.instantiate() as Node3D
	right.name = "MakeHumanRightGrip"
	right.position = Vector3(0.0, -0.005, 0.13)
	right.basis = Basis(Vector3.RIGHT, deg_to_rad(30.0)) * Basis(Vector3.UP, PI)
	trigger.add_child(right)
	_configure_viewmodel_hand(right)

	support_hand = Node3D.new()
	support_hand.name = "SupportHand"
	add_child(support_hand)
	_tube(support_hand, "SupportSleeve", [Vector3(-0.37, -0.48, 0.14), Vector3(-0.23, -0.17, -0.10), Vector3(-0.04, 0.065, -0.18)], [Vector2(0.078, 0.071), Vector2(0.063, 0.058), Vector2(0.038, 0.037)], cloth)
	_tube(support_hand, "SupportCuff", [Vector3(-0.053, 0.038, -0.168), Vector3(-0.04, 0.067, -0.18)], [Vector2(0.044, 0.042), Vector2(0.040, 0.039)], cuff)
	var left := LEFT_HAND.instantiate() as Node3D
	left.name = "MakeHumanLeftGrip"
	left.position = Vector3(-0.04, 0.065, -0.18)
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
	const SIDES := 18
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var along := 0.0
	for ring in range(points.size()):
		if ring > 0:
			along += (points[ring] - points[ring - 1]).length()
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
		for side in range(SIDES + 1):
			var angle := TAU * float(side) / float(SIDES)
			# Gentle creases so the sleeve reads as cloth, not a pipe.
			var fold := 1.0 + 0.06 * sin(angle * 3.0 + along * 21.0) * (1.0 if ring > 0 else 0.4)
			var radial: Vector3 = (axis_a * cos(angle) * radii[ring].x + axis_b * sin(angle) * radii[ring].y) * fold
			vertices.append(points[ring] + radial)
			normals.append(radial.normalized())
			uvs.append(Vector2(float(side) / float(SIDES), along))
	for ring in range(points.size() - 1):
		for side in range(SIDES):
			var a := ring * (SIDES + 1) + side
			var b := ring * (SIDES + 1) + side + 1
			var c := (ring + 1) * (SIDES + 1) + side
			var d := (ring + 1) * (SIDES + 1) + side + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	parent.add_child(instance)
