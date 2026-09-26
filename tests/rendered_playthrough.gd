extends SceneTree

# Rendered input-driven route test. It presses the same InputMap actions as a
# player and lets CharacterBody3D and level collision resolve all movement.
# It never assigns the player's position, disables guards, or kills enemies.

const WAYPOINT_TIMEOUT := 35.0

var main
var player
var director
var level
var traveled_m := 0.0
var move_seconds := 0.0
var forward_seconds := 0.0
var turn_seconds := 0.0
var sprint_seconds := 0.0
var _last_position := Vector3.ZERO
var _last_sample_ms := 0
var _fps_samples := 0
var _fps_sum := 0.0
var _fps_min := INF
var _fps_max := 0.0
var _memory_mb_max := 0.0
var _screenshot_dir := ""
var _was_sprinting := false
var _frame_ms_samples: Array[float] = []
var _run_started_ms := 0
var _last_screenshot_ms := 0
var _previous_render_us := 0


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
	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		_fail("Could not load main scene")
		return
	main = scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	player = main.player
	director = main.director
	level = main.level
	main.start_mission()
	await process_frame
	_run_started_ms = Time.get_ticks_msec()
	_last_position = player.global_position
	_last_sample_ms = Time.get_ticks_msec()
	_previous_render_us = Time.get_ticks_usec()
	process_frame.connect(_on_render_frame)
	await _capture("01_spawn")
	var route_name := OS.get_environment("QA_ROUTE")
	if route_name == "":
		route_name = "direct_west"
	if route_name != "direct_west" and route_name != "covered":
		_fail("Unknown QA_ROUTE: " + route_name)
		return
	_log("start", {"position": _position(), "guard_count": level.get_guards().size(), "window_size": DisplayServer.window_get_size(), "route": route_name})
	if level.get_guards().size() != 8:
		_fail("Expected eight initial guards")
		return

	# Both candidate south routes join the same playable core. Each movement
	# uses ordinary look and forward InputMap actions against actual collision.
	var approach: Array = [["south_west_street", Vector2(-48.0, 164.0)]]
	if route_name == "covered":
		approach.append_array([
			# The sandbag wall at x=-43.6 spans z=162.85..170.15. Cross
			# north of its end with capsule clearance instead of steering into it.
			["south_sandbag_end", Vector2(-48.0, 160.5)],
			["south_service_lane", Vector2(-32.5, 160.5)],
			["south_service_corner", Vector2(-32.5, 130.0)],
			["south_service_passage", Vector2(-32.5, 111.0)],
			["south_service_north", Vector2(-32.5, 96.0)],
			["south_service_bypass", Vector2(-32.5, 62.0)],
		])
	else:
		approach.append_array([
			["south_west_corner", Vector2(-48.0, 130.0)],
			["south_west_lane", Vector2(-48.0, 96.0)],
			["south_west_bypass", Vector2(-48.0, 62.0)],
		])
	approach.append_array([
		["south_north_crossing", Vector2(-19.0, 62.0)],
		["south_north_lane", Vector2(-19.0, 41.0)],
		["core_seam", Vector2(-10.0, 41.0)],
		["west_entry", Vector2(-10.0, 34.0)],
		["west_lane", Vector2(-10.0, -15.7)],
		["residence_front", Vector2(-2.5, -15.7)],
		["threshold", Vector2(-2.5, -18.7)],
		["upper_ramp", Vector2(-2.5, -26.0)],
		["upper_landing", Vector2(4.6, -26.0)],
		["contact", Vector2(4.6, -27.2)],
	])
	for entry in approach:
		if not await _move_to(entry[0], entry[1], WAYPOINT_TIMEOUT):
			_fail(("Player died at " if player.dead else "Approach blocked at ") + entry[0])
			return
	await _capture("02_contact_approach")
	_log("contact_approach", {"position": _position(), "interaction": director.interaction_text, "phase": director.phase})
	if director.phase != "INFILTRATE":
		_fail("Unexpected phase before handoff")
		return

	Input.action_press("interact")
	var contact_wait := 0.0
	while director.phase == "INFILTRATE" and contact_wait < 40.0 and not player.dead:
		await physics_frame
		contact_wait += 1.0 / 60.0
	Input.action_release("interact")
	if director.phase != "INTEL_SECURED":
		_fail("Contact did not deliver packet: " + director.interaction_text)
		return
	await _capture("03_packet_secured")
	_log("packet_secured", {"game_seconds": director.mission_time, "contact_wait_seconds": contact_wait, "kills": director.kills})

	var alarm_wait := 0.0
	while not director.lockdown and alarm_wait < 18.0 and not player.dead:
		await physics_frame
		alarm_wait += 1.0 / 60.0
	if not director.lockdown:
		_fail("Lockdown did not occur")
		return
	await _capture("04_lockdown")
	_log("lockdown", {"game_seconds": director.mission_time, "guard_count": level.get_guards().size(), "subtitle": director.subtitle_text})
	if level.get_guards().size() != 12:
		_fail("Expected exactly four finite reinforcements")
		return

	# Return through the actual ramp and take the north town bypass to the
	# opposite shelter. No waypoint assigns a transform or opens a gate.
	var escape: Array = [
		["landing_return", Vector2(-2.5, -26.0)],
		["residence_exit", Vector2(-2.5, -16.0)],
		["core_west_crossing", Vector2(-10.0, -16.0)],
		["core_west_north", Vector2(-10.0, -41.0)],
		["north_gate", Vector2(-16.0, -45.0)],
		["north_west_lane", Vector2(-16.0, -75.0)],
	]
	if route_name == "covered":
		escape.append_array([
			["north_service_crossing", Vector2(-32.5, -75.0)],
			["north_service_lane", Vector2(-32.5, -195.0)],
		])
	else:
		escape.append_array([
			["north_west_crossing", Vector2(-48.0, -75.0)],
			["north_outer_lane", Vector2(-48.0, -195.0)],
		])
	escape.append_array([
		["shelter_approach", Vector2(43.0, -195.0)],
		["shelter", Vector2(44.0, -198.0)],
	])
	for entry in escape:
		if not await _move_to(entry[0], entry[1], WAYPOINT_TIMEOUT):
			_fail(("Player died at " if player.dead else "Extraction blocked at ") + entry[0])
			return
	await _capture("05_scout_approach")
	_log("scout_approach", {"position": _position(), "interaction": director.interaction_text, "health": player.health})
	if OS.get_environment("QA_NATIVE_EXTRACT") == "1":
		_log("await_native_interact", {"timeout_seconds": 30.0})
		var native_started_ms := Time.get_ticks_msec()
		while director.phase == "INTEL_SECURED" and Time.get_ticks_msec() - native_started_ms < 30000:
			await process_frame
		_log("native_interact_result", {"phase": director.phase, "wait_seconds": float(Time.get_ticks_msec() - native_started_ms) / 1000.0})
	else:
		var press := InputEventKey.new()
		press.physical_keycode = KEY_E
		press.pressed = true
		Input.parse_input_event(press)
		await process_frame
		var release := InputEventKey.new()
		release.physical_keycode = KEY_E
		release.pressed = false
		Input.parse_input_event(release)
		await process_frame
	await _capture("06_result")
	if director.phase != "EXTRACTED":
		_fail("Extraction interaction failed: " + director.interaction_text)
		return
	if director.kills != 0:
		_fail("Zero-kill route reported kills")
		return
	_log("passed", {"game_seconds": director.mission_time, "wall_seconds": float(Time.get_ticks_msec() - _run_started_ms) / 1000.0, "route_input_seconds": move_seconds, "forward_seconds": forward_seconds, "turn_seconds": turn_seconds, "sprint_seconds": sprint_seconds, "distance_m": traveled_m, "kills": director.kills, "health": player.health, "guards": level.get_guards().size(), "fps_samples": _fps_samples, "fps_avg": _fps_sum / maxf(1.0, _fps_samples), "fps_min": _fps_min, "fps_max": _fps_max, "render_frame_samples": _frame_ms_samples.size(), "render_frame_ms_p50": _frame_percentile(0.50), "render_frame_ms_p95": _frame_percentile(0.95), "memory_static_mb_max": _memory_mb_max})
	quit(0)


func _move_to(label: String, target: Vector2, timeout_seconds: float) -> bool:
	var seconds := 0.0
	var last_log := 0.0
	var starting_distance := Vector2(player.global_position.x, player.global_position.z).distance_to(target)
	var allowed_seconds := maxf(timeout_seconds, starting_distance / 3.2 + 15.0)
	while Vector2(player.global_position.x, player.global_position.z).distance_to(target) > 0.8 and seconds < allowed_seconds:
		if player.dead:
			_release_motion()
			_log("dead", {"waypoint": label, "position": _position(), "game_seconds": director.mission_time})
			return false
		var delta := target - Vector2(player.global_position.x, player.global_position.z)
		var direction := delta.normalized()
		var target_yaw := atan2(-direction.x, -direction.y)
		var yaw_error := wrapf(target_yaw - player.rotation.y, -PI, PI)
		_set_axis("look_left", yaw_error > 0.035)
		_set_axis("look_right", yaw_error < -0.035)
		var moving_forward := absf(yaw_error) < 0.28
		_set_axis("move_forward", moving_forward)
		_set_axis("move_left", false)
		_set_axis("move_right", false)
		_set_axis("move_back", false)
		var awareness: Dictionary = director.get_local_awareness()
		var under_fire: bool = String(awareness.state) == "COMBAT"
		_set_axis("sprint", under_fire)
		if under_fire != _was_sprinting:
			_log("evasion_change", {"sprinting": under_fire, "position": _position(), "awareness": awareness.state, "health": player.health})
			_was_sprinting = under_fire
		_set_axis("hold_crouch", false)
		await physics_frame
		var travel: Vector3 = player.global_position - _last_position
		travel.y = 0.0
		traveled_m += travel.length()
		_last_position = player.global_position
		seconds += 1.0 / 60.0
		move_seconds += 1.0 / 60.0
		if moving_forward:
			forward_seconds += 1.0 / 60.0
			if under_fire:
				sprint_seconds += 1.0 / 60.0
		else:
			turn_seconds += 1.0 / 60.0
		if seconds - last_log > 5.0:
			last_log = seconds
			_log("progress", {"waypoint": label, "position": _position(), "target": [target.x, target.y], "health": player.health, "yaw": player.rotation.y})
	_release_motion()
	_log("waypoint", {"name": label, "position": _position(), "seconds": seconds, "allowed_seconds": allowed_seconds, "health": player.health})
	return Vector2(player.global_position.x, player.global_position.z).distance_to(target) <= 0.8


func _set_axis(action: StringName, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _release_motion() -> void:
	for action in ["move_left", "move_right", "move_forward", "move_back", "sprint", "hold_crouch", "look_left", "look_right"]:
		Input.action_release(action)


func _sample_metrics() -> void:
	if director.mission_time < 5.0 or Time.get_ticks_msec() - _last_sample_ms < 1000:
		return
	_last_sample_ms = Time.get_ticks_msec()
	var fps := Engine.get_frames_per_second()
	if fps > 0.0:
		_fps_samples += 1
		_fps_sum += fps
		_fps_min = minf(_fps_min, fps)
		_fps_max = maxf(_fps_max, fps)
		if fps < 30.0:
			_log("low_fps_sample", {"fps": fps, "game_seconds": director.mission_time, "phase": director.phase, "position": _position(), "since_capture_seconds": float(Time.get_ticks_msec() - _last_screenshot_ms) / 1000.0, "process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, "physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0})
	_memory_mb_max = maxf(_memory_mb_max, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)


func _on_render_frame() -> void:
	var now_us := Time.get_ticks_usec()
	var render_frame_ms := float(now_us - _previous_render_us) / 1000.0
	_previous_render_us = now_us
	if director == null or director.mission_time < 5.0 or not director.is_active():
		return
	_frame_ms_samples.append(render_frame_ms)
	if render_frame_ms > 50.0:
		_log("frame_hitch", {"frame_ms": render_frame_ms, "game_seconds": director.mission_time, "phase": director.phase, "position": _position(), "since_capture_seconds": float(Time.get_ticks_msec() - _last_screenshot_ms) / 1000.0})
	_sample_metrics()


func _frame_percentile(percentile: float) -> float:
	if _frame_ms_samples.is_empty():
		return 0.0
	var sorted := _frame_ms_samples.duplicate()
	sorted.sort()
	return sorted[clampi(ceili(percentile * float(sorted.size())) - 1, 0, sorted.size() - 1)]


func _position() -> Array:
	if player == null:
		return []
	return [player.global_position.x, player.global_position.y, player.global_position.z]


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := _screenshot_dir.path_join(label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	_last_screenshot_ms = Time.get_ticks_msec()
	_log("screenshot", {"path": path, "error": error})


func _log(event: String, values: Dictionary = {}) -> void:
	values["event"] = event
	print("RENDERED_QA " + JSON.stringify(values))


func _fail(message: String) -> void:
	_release_motion()
	_log("failed", {"reason": message, "position": _position(), "phase": director.phase if director != null else "NONE", "game_seconds": director.mission_time if director != null else 0.0})
	quit(1)
