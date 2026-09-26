extends SceneTree

# Staged camera inspection of a real Guard in the built town. This is a visual
# check of idle, velocity-driven skeletal gait and death alignment, not route play.
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Guard visual review requires a graphics display")
		quit(2)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	var guards: Array = main.level.get_guards()
	if guards.is_empty():
		push_error("Town has no guards to inspect")
		quit(3)
		return
	var guard: CharacterBody3D = guards[0]
	var animation := guard.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skeleton := guard.find_child("Skeleton3D", true, false) as Skeleton3D
	if animation == null or skeleton == null or not animation.has_animation("GuardWalk"):
		push_error("Guard is missing the rigged gait")
		quit(9)
		return
	var thigh := skeleton.find_bone("thigh_l")
	if thigh < 0:
		push_error("Guard walk has no left thigh bone")
		quit(10)
		return
	var camera := Camera3D.new()
	main.add_child(camera)
	camera.fov = 50.0
	camera.current = true
	main.start_mission()
	main.player.set_controls_enabled(false)
	guard.set_physics_process(false) # Stage a true idle pose for inspection.
	for _index in range(12):
		await process_frame
	var idle_rotation := skeleton.get_bone_pose_rotation(thigh)
	_frame_guard(camera, guard, Vector3.UP * 0.9)
	if not await _capture("guard_actor_idle"):
		quit(4)
		return
	guard.set_physics_process(true)
	var moving := false
	for _index in range(240):
		await physics_frame
		var real_motion := guard.get_real_velocity()
		if Vector2(real_motion.x, real_motion.z).length() > 0.25 and animation.current_animation == "GuardWalk":
			moving = true
			break
	if not moving:
		push_error("Selected guard did not show a velocity-driven stride")
		quit(5)
		return
	var real_motion := guard.get_real_velocity()
	print("GUARD_REVIEW real_moving_speed=", Vector2(real_motion.x, real_motion.z).length(), " animation=", animation.current_animation)
	guard.set_physics_process(false)
	_frame_guard(camera, guard, Vector3.UP * 0.9)
	# Remove any remaining entry blend before seeking fixed review phases.
	animation.play("GuardWalk", 0.0)
	animation.advance(0.0)
	if not await _capture_pose(animation, "guard_actor_contact", 0.02):
		quit(6)
		return
	if not await _capture_pose(animation, "guard_actor_mid_swing", 0.27):
		quit(6)
		return
	if not await _capture_pose(animation, "guard_actor_opposite_contact", 0.52):
		quit(6)
		return
	var walking_rotation := skeleton.get_bone_pose_rotation(thigh)
	if walking_rotation.angle_to(idle_rotation) < 0.08:
		push_error("Guard walk does not rotate its skinned thigh")
		quit(11)
		return
	var body_presentation := guard.find_child("FieldBodyPresentation", true, false)
	if body_presentation == null:
		push_error("Guard has no body presentation")
		quit(12)
		return
	animation.play()
	body_presentation.call("update_locomotion", 0.0, 0.016)
	await create_timer(0.25).timeout # Longer than the 0.18 s stop blend.
	if animation.current_animation != "GuardIdle" or skeleton.get_bone_pose_rotation(thigh).angle_to(idle_rotation) > 0.08:
		push_error("Stopped guard did not settle back to its idle thigh pose")
		quit(13)
		return
	body_presentation.call("update_locomotion", 2.0, 0.016)
	await create_timer(0.25).timeout
	animation.seek(0.52, true)
	guard.take_damage(200.0, guard.global_position)
	if guard.state != "DEAD":
		push_error("Visual corpse setup failed")
		quit(7)
		return
	if animation.current_animation != "GuardIdle":
		push_error("Dead guard did not settle to the idle rig pose")
		quit(9)
		return
	await create_timer(0.20).timeout # Longer than the 0.12 s death blend.
	if skeleton.get_bone_pose_rotation(thigh).angle_to(idle_rotation) > 0.08:
		push_error("Dead guard did not finish settling its rig pose")
		quit(14)
		return
	_frame_guard(camera, guard, Vector3.UP * 0.3)
	if not await _capture("guard_actor_dead"):
		quit(8)
		return
	print("GUARD_ACTOR_VISUAL_PASS idle contact mid_swing opposite_contact dead")
	quit(0)


func _frame_guard(camera: Camera3D, guard: CharacterBody3D, focus_offset: Vector3) -> void:
	var side := guard.global_basis.x * 1.2
	var front := -guard.global_basis.z * 2.8
	camera.global_position = guard.global_position + front + side + Vector3.UP * 1.45
	camera.look_at(guard.global_position + focus_offset)


func _capture(label: String) -> bool:
	for _index in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://build/qa/" + label + ".png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var result := root.get_texture().get_image().save_png(output)
	print("GUARD_REVIEW_FRAME name=", label, " save=", result, " path=", output)
	return result == OK


func _capture_pose(animation: AnimationPlayer, label: String, position: float) -> bool:
	animation.seek(position, true)
	animation.pause()
	var saved := await _capture(label)
	var actual := animation.current_animation_position
	print("GUARD_REVIEW_POSE name=", label, " clip_time=", actual)
	if absf(actual - position) > 0.02:
		push_error("Captured guard pose drifted from its labeled clip time")
		return false
	return saved
