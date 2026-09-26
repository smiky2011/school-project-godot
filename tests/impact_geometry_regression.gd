extends SceneTree

# Cosmetic receiver checks only. The gameplay ray, damage and collision stay
# untouched; rendered_impact_review.gd checks actual projected pixels.
const RECEIVER := preload("res://scripts/world/townhouse_impact_geometry.gd")
const MARK_SIZE := 0.22
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var source := FileAccess.get_file_as_string("res://assets/environment/townhouse_facades.json")
	if not _check(not source.is_empty() and JSON.parse_string(source) is Dictionary, "Authored facade contract loads"):
		return
	var stone := Node.new()
	var scale := Vector3(1.0, 1.05, 0.875)
	var transform := Transform3D(Basis.IDENTITY.scaled(scale), Vector3(10.0, 0.0, 15.0))
	stone.set_meta("impact_shell", {"transform": transform, "style": "stone_gable"})
	var front_hit := transform * Vector3(0.0, 2.7, 8.0)
	var front: Dictionary = RECEIVER.resolve(front_hit, Vector3.BACK, stone, MARK_SIZE, Vector3.FORWARD)
	if not _check(front.visible and front.kind == "masonry" and front.position.distance_to(transform * Vector3(0.0, 2.7, 8.17)) < 0.001,
			"Front mark reaches the actual scaled outer wall"):
		return
	var back_hit := transform * Vector3(0.0, 2.7, -8.0)
	var back: Dictionary = RECEIVER.resolve(back_hit, Vector3.FORWARD, stone, MARK_SIZE, Vector3.BACK)
	if not _check(back.visible and back.position.distance_to(transform * Vector3(0.0, 2.7, -8.17)) < 0.001,
			"Opposite facade mark reaches outer wall"):
		return
	var door_hit := transform * Vector3(-2.35, 1.5, 8.0)
	if not _check(not RECEIVER.resolve(door_hit, Vector3.BACK, stone, MARK_SIZE, Vector3.FORWARD).visible,
			"Closed visual door gets no floating masonry mark"):
		return
	var near_door := transform * Vector3(-3.02, 1.5, 8.0)
	if not _check(not RECEIVER.resolve(near_door, Vector3.BACK, stone, MARK_SIZE, Vector3.FORWARD).visible,
			"Mark radius is kept clear of the door frame"):
		return
	var side_hit := transform * Vector3(4.5, 2.7, 0.0)
	var side: Dictionary = RECEIVER.resolve(side_hit, Vector3.RIGHT, stone, MARK_SIZE, Vector3.LEFT)
	if not _check(side.visible and side.position.distance_to(transform * Vector3(4.67, 2.7, 0.0)) < 0.001,
			"Side wall mark reaches visible masonry"):
		return
	var side_opening := transform * Vector3(4.5, 1.6, 2.05)
	if not _check(not RECEIVER.resolve(side_opening, Vector3.RIGHT, stone, MARK_SIZE, Vector3.LEFT).visible,
			"Side door opening gets no floating mark"):
		return
	var angled_dir := Vector3(0.5, 0.0, -1.0).normalized()
	var angled_hit := transform * Vector3(-3.50, 2.7, 8.0)
	var angled: Dictionary = RECEIVER.resolve(angled_hit, Vector3.BACK, stone, MARK_SIZE, angled_dir)
	if not _check(angled.visible and (angled.position - angled_hit).cross(angled_dir).length() < 0.001
			and is_equal_approx(angled.position.z, (transform * Vector3(0.0, 0.0, 8.17)).z),
			"Oblique impact stays on the shot line at the visible plane"):
		return
	var tilted := Node.new()
	var tilted_basis := Basis(Vector3.UP, deg_to_rad(37.0)) * Basis.IDENTITY.scaled(Vector3(1.2, 1.07, 0.9))
	var tilted_transform := Transform3D(tilted_basis, Vector3(-7.0, 0.0, -12.0))
	tilted.set_meta("impact_shell", {"transform": tilted_transform, "style": "plaster_hip"})
	var tilted_normal := (tilted_basis.inverse().transposed() * Vector3.BACK).normalized()
	var tilted_hit := tilted_transform * Vector3(0.0, 2.7, 8.0)
	var tilted_result: Dictionary = RECEIVER.resolve(tilted_hit, tilted_normal, tilted, MARK_SIZE, -tilted_normal)
	if not _check(tilted_result.visible and tilted_result.position.distance_to(tilted_transform * Vector3(0.0, 2.7, 8.17)) < 0.001,
			"Rotated nonuniform plaster shell resolves the visible plane"):
		return
	var plain := Node.new()
	if not _check(RECEIVER.resolve(Vector3(1, 2, 3), Vector3.UP, plain, MARK_SIZE).position == Vector3(1, 2, 3),
			"Aligned box/crate and dirt receiver remain unchanged"):
		return
	var roof := Node.new()
	roof.set_meta("impact_hidden_roof", true)
	if not _check(not RECEIVER.resolve(Vector3(1, 2, 3), Vector3.UP, roof, MARK_SIZE).visible,
			"Hidden coarse roof does not get a fake mark"):
		return
	stone.free()
	tilted.free()
	plain.free()
	roof.free()
	print("IMPACT GEOMETRY PASS checks=%d" % _checks)
	quit(0)


func _check(ok: bool, label: String) -> bool:
	if not ok:
		push_error("IMPACT GEOMETRY FAIL: " + label)
		quit(1)
		return false
	_checks += 1
	return true
