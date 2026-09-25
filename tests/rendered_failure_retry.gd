extends SceneTree

# Rendered input-driven failure/retry check. The player walks through normal
# CharacterBody3D collision into a patrol's sightline; CUA clicks Retry Mission.

var main
var player
var director
var _screenshot_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_screenshot_dir = OS.get_environment("QA_OUTPUT_DIR")
	if _screenshot_dir == "":
		_screenshot_dir = ProjectSettings.globalize_path("res://build/qa")
	if not _screenshot_dir.begins_with("/") or DirAccess.make_dir_recursive_absolute(_screenshot_dir) != OK:
		push_error("QA_OUTPUT_DIR must be an absolute writable directory")
		quit(1)
		return
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	player = main.player
	director = main.director
	main.start_mission()
	await process_frame
	_log("start", {"position": _position(), "health": player.health})

	# Cross at the southern lane, then face the fixed middle sentry from its
	# open south side. No transforms, guard flags or damage calls are changed.
	if not await _walk_axis("move_forward", "z", 164.0, false, 20.0):
		_fail("The player did not reach the southern crossing")
		return
	if not await _walk_axis("move_right", "x", -19.0, true, 20.0):
		_fail("The player did not cross into the middle lane")
		return
	if not await _walk_axis("move_forward", "z", 105.0, false, 30.0):
		_fail("The player did not approach the middle sentry")
		return
	_log("sentry_approach", {"position": _position(), "health": player.health})

	var combat_started_ms := Time.get_ticks_msec()
	while not player.dead and Time.get_ticks_msec() - combat_started_ms < 45000:
		await physics_frame
	if not player.dead or director.phase != "FAILED":
		_fail("Patrol did not cause actual mission failure")
		return
	await _capture("07_failed")
	_log("failed_under_fire", {"position": _position(), "game_seconds": director.mission_time, "guard_count": main.level.get_guards().size()})
	_log("await_native_retry", {"timeout_seconds": 120.0})

	var retry_started_ms := Time.get_ticks_msec()
	while Time.get_ticks_msec() - retry_started_ms < 120000:
		await process_frame
		if current_scene != null and is_instance_valid(current_scene) and current_scene != main:
			break
	if current_scene == null or not is_instance_valid(current_scene) or current_scene == main:
		_fail("No new mission scene after native Retry Mission click")
		return
	var fresh_main = current_scene
	await process_frame
	await process_frame
	if fresh_main.director.phase != "INFILTRATE" or fresh_main.player.health != 100.0 or fresh_main.player.ammo != 30 or fresh_main.director.running:
		_fail("Retry did not restore the briefing and player state")
		return
	await _capture("08_retry_briefing")
	_log("retry_passed", {"phase": fresh_main.director.phase, "health": fresh_main.player.health, "ammo": fresh_main.player.ammo, "guard_count": fresh_main.level.get_guards().size()})
	quit(0)


func _position() -> Array:
	return [player.global_position.x, player.global_position.y, player.global_position.z]


func _walk_axis(action: String, axis: String, target: float, increasing: bool, timeout_seconds: float) -> bool:
	Input.action_press(action)
	var started_ms := Time.get_ticks_msec()
	while (_axis_value(axis) < target if increasing else _axis_value(axis) > target) and Time.get_ticks_msec() - started_ms < int(timeout_seconds * 1000.0) and not player.dead:
		await physics_frame
	Input.action_release(action)
	_log("axis_walk", {"action": action, "position": _position(), "health": player.health, "seconds": float(Time.get_ticks_msec() - started_ms) / 1000.0})
	return player.dead or (_axis_value(axis) >= target if increasing else _axis_value(axis) <= target)


func _axis_value(axis: String) -> float:
	return player.global_position.x if axis == "x" else player.global_position.z


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := _screenshot_dir.path_join(label + ".png")
	_log("screenshot", {"path": path, "error": root.get_texture().get_image().save_png(path)})


func _log(event: String, values: Dictionary = {}) -> void:
	values["event"] = event
	print("RENDERED_RETRY " + JSON.stringify(values))


func _fail(message: String) -> void:
	Input.action_release("move_forward")
	Input.action_release("move_right")
	_log("failed", {"reason": message})
	quit(1)
