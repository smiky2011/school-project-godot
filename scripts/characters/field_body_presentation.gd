extends Node3D

# The source rig, masked visible meshes, and two in-place clips are retained in
# source/guard_field_locomotion.blend. Guard movement remains CharacterBody3D-led.
const FIELD_BODY: PackedScene = preload("res://assets/vendor/character_visual/makehuman/runtime/guard_field_animated.glb")

var _animation: AnimationPlayer
var _walking := false
var _dead := false


func _ready() -> void:
	var body := FIELD_BODY.instantiate() as Node3D
	body.name = "FieldBody"
	body.rotation.y = PI # The imported model faces +Z; the actor faces -Z.
	add_child(body)
	_animation = body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation == null or not _animation.has_animation("GuardIdle") or not _animation.has_animation("GuardWalk"):
		push_error("Guard body is missing its authored idle/walk clips")
		return
	_animation.get_animation("GuardWalk").loop_mode = Animation.LOOP_LINEAR
	_animation.play("GuardIdle")


func update_locomotion(horizontal_speed: float, _delta: float) -> void:
	if _dead or _animation == null:
		return
	var moving := horizontal_speed > 0.12
	if moving != _walking:
		_walking = moving
		_animation.play("GuardWalk" if moving else "GuardIdle", 0.18)
	if moving:
		# The authored ankle sweep spans about 0.78 m per step, so one
		# 1.6 m cycle follows actual travel without the former slow foot slide.
		_animation.speed_scale = clampf(horizontal_speed / 1.6, 0.08, 1.7)
	else:
		_animation.speed_scale = 1.0


func freeze_dead() -> void:
	_dead = true
	_walking = false
	if _animation != null:
		_animation.speed_scale = 1.0
		_animation.play("GuardIdle", 0.12)
