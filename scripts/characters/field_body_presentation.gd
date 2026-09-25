extends Node3D

# Baked, visible-only mesh morphs avoid exporting MakeHuman's masked helper faces.
const FIELD_BODY: PackedScene = preload("res://assets/vendor/character_visual/makehuman/runtime/guard_field_morph.glb")

var _step_left: Array[MeshInstance3D] = []
var _step_right: Array[MeshInstance3D] = []
var _left_indices: Array[int] = []
var _right_indices: Array[int] = []
var _phase := 0.0
var _intensity := 0.0
var _dead := false


func _ready() -> void:
	var body := FIELD_BODY.instantiate() as Node3D
	body.name = "FieldBody"
	body.rotation.y = PI # The imported model faces +Z; the actor faces -Z.
	add_child(body)
	_collect_shapes(body)


func update_locomotion(horizontal_speed: float, delta: float) -> void:
	if _dead:
		return
	var moving := horizontal_speed > 0.12
	var target := clampf(horizontal_speed / 2.0, 0.0, 1.0) if moving else 0.0
	_intensity = move_toward(_intensity, target, delta * 4.0)
	if moving:
		_phase += delta * horizontal_speed * 5.2
	var left := maxf(0.0, sin(_phase)) * _intensity
	var right := maxf(0.0, -sin(_phase)) * _intensity
	for index in range(_step_left.size()):
		_step_left[index].set_blend_shape_value(_left_indices[index], left)
	for index in range(_step_right.size()):
		_step_right[index].set_blend_shape_value(_right_indices[index], right)


func freeze_dead() -> void:
	_dead = true
	for index in range(_step_left.size()):
		_step_left[index].set_blend_shape_value(_left_indices[index], 0.0)
	for index in range(_step_right.size()):
		_step_right[index].set_blend_shape_value(_right_indices[index], 0.0)


func _collect_shapes(node: Node) -> void:
	if node is MeshInstance3D:
		var visual := node as MeshInstance3D
		if visual.mesh != null:
			for index in range(visual.mesh.get_blend_shape_count()):
				var shape_name: StringName = visual.mesh.get_blend_shape_name(index)
				if shape_name == "StepLeft":
					_step_left.append(visual)
					_left_indices.append(index)
				elif shape_name == "StepRight":
					_step_right.append(visual)
					_right_indices.append(index)
	for child in node.get_children():
		_collect_shapes(child)
