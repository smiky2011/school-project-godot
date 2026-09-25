extends SceneTree

# Staged camera inspection of a real Guard in the built town. This is a visual
# check of idle, velocity-driven stride and death alignment, not route play.
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
	var camera := Camera3D.new()
	main.add_child(camera)
	camera.fov = 50.0
	camera.current = true
	main.start_mission()
	main.player.set_controls_enabled(false)
	guard.set_physics_process(false) # Stage a true idle pose for inspection.
	_frame_guard(camera, guard, Vector3.UP * 0.9)
	if not await _capture("guard_actor_idle"):
		quit(4)
		return
	guard.set_physics_process(true)
	var moving := false
	var stride := 0.0
	for _index in range(240):
		await physics_frame
		stride = _stride_strength(guard)
		var real_motion := guard.get_real_velocity()
		if Vector2(real_motion.x, real_motion.z).length() > 0.25 and stride > 0.7:
			moving = true
			break
	if not moving:
		push_error("Selected guard did not show a velocity-driven stride")
		quit(5)
		return
	_frame_guard(camera, guard, Vector3.UP * 0.9)
	var real_motion := guard.get_real_velocity()
	print("GUARD_REVIEW real_moving_speed=", Vector2(real_motion.x, real_motion.z).length(), " stride=", stride)
	if not await _capture("guard_actor_moving"):
		quit(6)
		return
	guard.take_damage(200.0, guard.global_position)
	if guard.state != "DEAD":
		push_error("Visual corpse setup failed")
		quit(7)
		return
	if _stride_strength(guard) > 0.01:
		push_error("Dead guard did not stop its stride morph")
		quit(9)
		return
	for _index in range(3):
		await physics_frame
	_frame_guard(camera, guard, Vector3.UP * 0.3)
	if not await _capture("guard_actor_dead"):
		quit(8)
		return
	print("GUARD_ACTOR_VISUAL_PASS idle moving dead")
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


func _stride_strength(node: Node) -> float:
	var result := 0.0
	if node is MeshInstance3D:
		var visual := node as MeshInstance3D
		if visual.mesh is ArrayMesh:
			for index in range(visual.mesh.get_blend_shape_count()):
				var shape_name: StringName = visual.mesh.get_blend_shape_name(index)
				if shape_name == "StepLeft" or shape_name == "StepRight":
					result = maxf(result, visual.get_blend_shape_value(index))
	for child in node.get_children():
		result = maxf(result, _stride_strength(child))
	return result
