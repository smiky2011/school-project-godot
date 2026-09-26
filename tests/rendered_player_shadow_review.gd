extends SceneTree

# Real-light review of the first-person player's world shadow. Captures idle,
# moving, crouched and aimed poses on the town's spawn street.
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")


func _initialize() -> void:
	create_timer(40.0).timeout.connect(func() -> void:
		push_error("Player shadow review exceeded its 40-second watchdog")
		quit(98))
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Player shadow review requires a graphics display")
		quit(2)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	var player: CharacterBody3D = main.player
	var body := player.get_node_or_null("PlayerBodyPresentation")
	if body == null:
		push_error("Player world body is missing")
		quit(3)
		return
	# The StG scene can also contain an AnimationPlayer, so inspect the body
	# controller's exact player rather than a recursive name search.
	var animation := body.get("_animation") as AnimationPlayer
	var skeleton := (body.get("_body") as Node3D).find_child("Skeleton3D", true, false) as Skeleton3D
	if animation == null or skeleton == null or not animation.has_animation("GuardIdle"):
		push_error("Player world body is not rigged")
		quit(4)
		return
	var thigh := skeleton.find_bone("thigh_l")
	var knee := skeleton.find_bone("calf_l")
	var ankle := skeleton.find_bone("foot_l")
	var head := skeleton.find_bone("head")
	var grip := skeleton.find_bone("hand_r")
	if thigh < 0 or knee < 0 or ankle < 0 or head < 0 or grip < 0:
		push_error("Player world body is missing required leg/head/grip bones")
		quit(5)
		return
	var viewmodel: Node = player.get_camera().get_child(0)
	if not _all_geometry_has_shadow_mode(viewmodel, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF):
		push_error("Camera-bound viewmodel still casts a world shadow")
		quit(6)
		return
	if not _all_geometry_has_shadow_mode(body, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY):
		push_error("Player world body or weapon is visible instead of shadow-only")
		quit(7)
		return
	var observer := Camera3D.new()
	observer.name = "ShadowReviewCamera"
	observer.fov = 47.0
	observer.cull_mask = 1 # Omit camera-bound layer 2 viewmodel from review.
	main.add_child(observer)
	observer.current = true
	main.start_mission()
	main.hud.visible = false
	for _index in range(18):
		await physics_frame
	var standing_foot := _bone_world(skeleton, ankle)
	var standing_head := _bone_world(skeleton, head)
	var standing_knee_angle := _knee_angle(skeleton, thigh, knee, ankle)
	var weapon_mount := body.find_child("WorldWeaponShadowMount", true, false) as Node3D
	if weapon_mount == null:
		push_error("Player world weapon shadow has no right-hand mount")
		quit(21)
		return
	var standing_grip_offset := weapon_mount.global_position - _bone_world(skeleton, grip)
	print("PLAYER_SHADOW_STAND foot_y=", standing_foot.y, " head_y=", standing_head.y, " knee_deg=", rad_to_deg(standing_knee_angle))
	if standing_grip_offset.length() > 0.05:
		push_error("Standing world weapon trigger grip is detached from right hand")
		quit(22)
		return
	if not await _capture(observer, player, "player_shadow_idle"):
		quit(8)
		return
	Input.action_press("look_right")
	for _index in range(12):
		await physics_frame
	Input.action_release("look_right")
	print("PLAYER_SHADOW_TURN velocity=", player.get_real_velocity(), " clip=", animation.current_animation,
		" assigned=", animation.assigned_animation, " playing=", animation.is_playing(),
		" loop=", animation.get_animation("GuardIdle").loop_mode,
		" on_floor=", player.is_on_floor(), " pos=", player.global_position)
	if animation.current_animation != "GuardIdle":
		push_error("Turning in place played a walking shadow gait")
		quit(16)
		return
	for _index in range(120):
		if player.is_on_floor():
			break
		await physics_frame
	if not player.is_on_floor():
		push_error("Player did not settle on the spawn street for blocked-motion probe")
		quit(23)
		return
	player.rotation.y = 0.0
	var blocker := StaticBody3D.new()
	blocker.collision_layer = 1
	blocker.collision_mask = 1
	var blocked_shape := CollisionShape3D.new()
	var blocked_box := BoxShape3D.new()
	blocked_box.size = Vector3(2.0, 2.0, 0.2)
	blocked_shape.shape = blocked_box
	blocker.add_child(blocked_shape)
	main.add_child(blocker)
	blocker.global_position = player.global_position + Vector3(0.0, 1.0, -0.7)
	Input.action_press("move_forward")
	for _index in range(24):
		await physics_frame
	Input.action_release("move_forward")
	print("PLAYER_SHADOW_BLOCKED velocity=", player.get_real_velocity(), " clip=", animation.current_animation,
		" player_pos=", player.global_position, " blocker_pos=", blocker.global_position)
	if animation.current_animation != "GuardIdle" or Vector2(player.get_real_velocity().x, player.get_real_velocity().z).length() > 0.12:
		push_error("Pushing against a wall cycled the walking shadow")
		quit(17)
		return
	blocker.queue_free()
	for _index in range(3):
		await physics_frame
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	for _index in range(6):
		await physics_frame
	if player.is_on_floor() or animation.current_animation != "GuardIdle":
		push_error("Airborne motion cycled the walking shadow")
		quit(18)
		return
	for _index in range(48):
		await physics_frame
	var idle_rotation := skeleton.get_bone_pose_rotation(thigh)
	Input.action_press("move_forward")
	for _index in range(35):
		await physics_frame
	if animation.current_animation != "GuardWalk" or skeleton.get_bone_pose_rotation(thigh).angle_to(idle_rotation) < 0.08:
		push_error("Player world body did not enter a moving leg pose")
		Input.action_release("move_forward")
		quit(9)
		return
	if not await _capture(observer, player, "player_shadow_walk"):
		Input.action_release("move_forward")
		quit(8)
		return
	Input.action_release("move_forward")
	if not await _move_and_capture(observer, player, animation, "move_back", "PlayerWalkBack", "player_shadow_back"):
		quit(13)
		return
	if not await _move_and_capture(observer, player, animation, "move_left", "PlayerStrafeLeft", "player_shadow_strafe_left"):
		quit(14)
		return
	if not await _move_and_capture(observer, player, animation, "move_right", "PlayerStrafeRight", "player_shadow_strafe_right"):
		quit(15)
		return
	for _index in range(16):
		await physics_frame
	Input.action_press("hold_crouch")
	for _index in range(18):
		await physics_frame
	if not player.is_crouching or animation.current_animation != "PlayerCrouchIdle":
		push_error("Player world shadow did not enter its bent-knee crouch pose")
		Input.action_release("hold_crouch")
		quit(10)
		return
	var crouched_foot := _bone_world(skeleton, ankle)
	var crouched_head := _bone_world(skeleton, head)
	var crouched_knee_angle := _knee_angle(skeleton, thigh, knee, ankle)
	var world_grip := _bone_world(skeleton, grip)
	var crouched_grip_offset := weapon_mount.global_position - world_grip
	print("PLAYER_SHADOW_CROUCH foot_y=", crouched_foot.y, " head_y=", crouched_head.y,
		" knee_deg=", rad_to_deg(crouched_knee_angle), " grip_offset=", crouched_grip_offset,
		" stand_grip_offset=", standing_grip_offset)
	if absf(crouched_foot.y - standing_foot.y) > 0.15 or standing_head.y - crouched_head.y < 0.3 \
		or crouched_knee_angle - standing_knee_angle < deg_to_rad(30.0) \
		or crouched_grip_offset.length() > 0.05 \
		or absf(crouched_grip_offset.length() - standing_grip_offset.length()) > 0.04:
		push_error("Crouch did not bend and lower a grounded skeleton")
		Input.action_release("hold_crouch")
		quit(12)
		return
	if not await _capture(observer, player, "player_shadow_crouch"):
		Input.action_release("hold_crouch")
		quit(8)
		return
	Input.action_press("move_left")
	for _index in range(24):
		await physics_frame
	if animation.current_animation != "PlayerCrouchStrafeLeft":
		push_error("Crouched strafe used the wrong leg gait")
		Input.action_release("move_left")
		Input.action_release("hold_crouch")
		quit(19)
		return
	var strafe_foot := _bone_world(skeleton, ankle)
	print("PLAYER_SHADOW_CROUCH_STRAFE foot_y=", strafe_foot.y)
	if absf(strafe_foot.y - crouched_foot.y) > 0.15:
		push_error("Crouched strafe ankle rose too far from the ground")
		Input.action_release("move_left")
		Input.action_release("hold_crouch")
		quit(20)
		return
	if not await _capture(observer, player, "player_shadow_crouch_strafe"):
		Input.action_release("move_left")
		Input.action_release("hold_crouch")
		quit(8)
		return
	Input.action_release("move_left")
	Input.action_release("hold_crouch")
	Input.action_press("aim")
	for _index in range(20):
		await physics_frame
	if player.aim_amount < 0.9:
		push_error("Aim pose did not settle")
		Input.action_release("aim")
		quit(11)
		return
	if not await _capture(observer, player, "player_shadow_aim"):
		Input.action_release("aim")
		quit(8)
		return
	Input.action_release("aim")
	# The actual first-person camera must see the same world shadow while the
	# camera-bound weapon remains visible on its dedicated layer.
	player.set("_pitch", -0.85)
	for _index in range(8):
		await physics_frame
	observer.current = false
	player.get_camera().current = true
	if not await _capture_current("player_shadow_first_person"):
		quit(8)
		return
	print("PLAYER_SHADOW_REVIEW_PASS idle blocked turn air forward back strafe crouch crouch_strafe aim first_person")
	quit(0)


func _all_geometry_has_shadow_mode(node: Node, expected: int) -> bool:
	if node is GeometryInstance3D and (node as GeometryInstance3D).cast_shadow != expected:
		return false
	for child in node.get_children():
		if not _all_geometry_has_shadow_mode(child, expected):
			return false
	return true


func _bone_world(skeleton: Skeleton3D, bone: int) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin


func _knee_angle(skeleton: Skeleton3D, thigh: int, knee: int, ankle: int) -> float:
	var hip_position := _bone_world(skeleton, thigh)
	var knee_position := _bone_world(skeleton, knee)
	var ankle_position := _bone_world(skeleton, ankle)
	return (knee_position - hip_position).angle_to(ankle_position - knee_position)


func _move_and_capture(camera: Camera3D, player: CharacterBody3D, animation: AnimationPlayer,
		action: StringName, expected_clip: String, label: String) -> bool:
	Input.action_press(action)
	for _index in range(24):
		await physics_frame
	if animation.current_animation != expected_clip:
		push_error("Directional shadow gait did not enter " + expected_clip)
		Input.action_release(action)
		return false
	var captured := await _capture(camera, player, label)
	Input.action_release(action)
	for _index in range(12):
		await physics_frame
	return captured


func _capture(camera: Camera3D, player: CharacterBody3D, label: String) -> bool:
	var focus := player.global_position + Vector3(-0.8, 0.15, 0.0)
	camera.global_position = player.global_position + Vector3(2.3, 4.0, 2.8)
	camera.look_at(focus)
	for _index in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://build/qa/" + label + ".png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var saved := root.get_texture().get_image().save_png(output)
	print("PLAYER_SHADOW_FRAME name=", label, " save=", saved, " path=", output)
	return saved == OK


func _capture_current(label: String) -> bool:
	for _index in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://build/qa/" + label + ".png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var saved := root.get_texture().get_image().save_png(output)
	print("PLAYER_SHADOW_FRAME name=", label, " save=", saved, " path=", output)
	return saved == OK
