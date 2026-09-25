extends Node3D

# Visual-only low-ready Sten for the guard. The caller attaches this at the
# actor origin, whose forward direction is -Z. The character GLB turns by PI
# separately because its imported front is +Z.
const STEN_SCENE: PackedScene = preload("res://assets/vendor/weapon_visual/sten_mk2/runtime/sten_mk2.glb")


static func make_model() -> Node3D:
	var root := Node3D.new()
	root.name = "FieldStenVisual"
	var mount := Node3D.new()
	mount.name = "LowReadyMount"
	mount.position = Vector3(0.04, 1.05, -0.38)
	mount.rotation.x = -0.13
	root.add_child(mount)
	var sten := STEN_SCENE.instantiate() as Node3D
	sten.name = "StenMkII"
	sten.rotation.y = PI # Source barrel points +Z; actor forward is -Z.
	mount.add_child(sten)
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0.0, 0.061, 0.347)
	sten.add_child(muzzle)
	return root
