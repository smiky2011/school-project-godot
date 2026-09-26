extends Node3D

# A world-space silhouette for the first-person player. It follows the real
# CharacterBody3D, but its meshes render only into shadow maps so the head and
# shoulders never cut across the camera view.
const BODY_SCENE: PackedScene = preload("res://assets/vendor/character_visual/makehuman/runtime/player_shadow_animated.glb")
const STG44_SCENE: PackedScene = preload("res://assets/vendor/weapon_visual/stg44/runtime/stg44.glb")
# Geometry-inspected trigger grip in the imported StG coordinate frame.
const STG_TRIGGER_GRIP := Vector3(0.0, 0.09, 0.13)

var _player: CharacterBody3D
var _body: Node3D
var _weapon_mount: Node3D
var _animation: AnimationPlayer
var _animation_name := ""


func _ready() -> void:
	name = "PlayerBodyPresentation"
	_player = get_parent() as CharacterBody3D
	if _player == null:
		push_error("Player body presentation must be attached to a CharacterBody3D")
		return
	_body = BODY_SCENE.instantiate() as Node3D
	_body.name = "BodyShadow"
	_body.rotation.y = PI # The imported character faces +Z.
	add_child(_body)
	_animation = _body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var required_clips := ["GuardIdle", "GuardWalk", "PlayerWalkBack", "PlayerStrafeLeft", "PlayerStrafeRight",
		"PlayerCrouchIdle", "PlayerCrouchWalk", "PlayerCrouchBack", "PlayerCrouchStrafeLeft", "PlayerCrouchStrafeRight"]
	if _animation == null:
		push_error("Player body is missing its AnimationPlayer")
		return
	for clip in required_clips:
		if not _animation.has_animation(clip):
			push_error("Player body is missing animation " + clip)
			return
		_animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_animation.play("GuardIdle")
	_animation.advance(0.0)
	_animation_name = "GuardIdle"
	var skeleton := _body.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null or skeleton.find_bone("hand_r") < 0:
		push_error("Player body is missing its right-hand attachment bone")
		return
	var hand_bone := skeleton.find_bone("hand_r")
	var grip := BoneAttachment3D.new()
	grip.name = "RightHandWeaponAttachment"
	grip.bone_name = "hand_r"
	skeleton.add_child(grip)
	_weapon_mount = Node3D.new()
	_weapon_mount.name = "WorldWeaponShadowMount"
	grip.add_child(_weapon_mount)
	# Match the mount to the authored hand position once. BoneAttachment3D
	# then carries it with the full hand pose, including crouch torso lean.
	var hand_world := skeleton.global_transform * skeleton.get_bone_global_pose(hand_bone).origin
	_weapon_mount.global_transform = _player.global_transform * Transform3D(
		Basis(Vector3.RIGHT, -0.13), _player.to_local(hand_world))
	var weapon := STG44_SCENE.instantiate() as Node3D
	weapon.name = "WorldWeaponShadow"
	# The StG glTF barrel is -Z in Godot; the body mesh alone needs PI yaw.
	weapon.position = -STG_TRIGGER_GRIP
	_weapon_mount.add_child(weapon)
	_set_shadow_only(_body)
	_set_shadow_only(_weapon_mount)
	# Viewmodel parts are camera-bound and otherwise leave a detached gun/arm
	# shadow on the world. Reapply this when adding new viewmodel geometry.
	for camera_child in _player.get_camera().get_children():
		_set_no_shadow(camera_child)


func _physics_process(delta: float) -> void:
	if _player == null or _animation == null:
		return
	var horizontal_velocity := _player.get_real_velocity()
	var horizontal_speed := Vector2(horizontal_velocity.x, horizontal_velocity.z).length() if _player.is_on_floor() else 0.0
	var moving: bool = horizontal_speed > 0.12 and _player.controls_enabled
	var desired := "PlayerCrouchIdle" if _player.is_crouching else "GuardIdle"
	if moving:
		var local_motion := _player.global_basis.inverse() * horizontal_velocity
		if absf(local_motion.x) > absf(local_motion.z) * 0.8:
			if _player.is_crouching:
				desired = "PlayerCrouchStrafeLeft" if local_motion.x < 0.0 else "PlayerCrouchStrafeRight"
			else:
				desired = "PlayerStrafeLeft" if local_motion.x < 0.0 else "PlayerStrafeRight"
		elif local_motion.z > 0.0:
			desired = "PlayerCrouchBack" if _player.is_crouching else "PlayerWalkBack"
		else:
			desired = "PlayerCrouchWalk" if _player.is_crouching else "GuardWalk"
	if desired != _animation_name:
		_animation_name = desired
		_animation.play(desired, 0.18)
	_animation.speed_scale = clampf(horizontal_speed / (1.2 if _player.is_crouching else 1.6), 0.08, 2.8) if moving else 1.0
	# The weapon follows the skinned right hand through its bone attachment.
	# ADS and camera pitch have no authored matching upper-body clip yet.


func _set_shadow_only(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	for child in node.get_children():
		_set_shadow_only(child)


func _set_no_shadow(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_set_no_shadow(child)
