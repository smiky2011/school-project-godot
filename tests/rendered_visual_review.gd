extends SceneTree

# Short rendered visual review at the normal mission spawn. All movement,
# aiming, firing, reload, crouch and pause actions use the game's InputMap.
# Screenshots are for human art review, not proof of visual quality or a full run.
# Run with Godot --path . --script res://tests/rendered_visual_review.gd

var main: Node
var player: CharacterBody3D
var director: Node
var output_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = OS.get_environment("QA_OUTPUT_DIR")
	if output_dir == "":
		output_dir = ProjectSettings.globalize_path("res://build/qa/visual_review")
	if not output_dir.begins_with("/") or DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		_fail("QA_OUTPUT_DIR must be an absolute writable directory")
		return
	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		_fail("Main scene did not load")
		return
	main = scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	player = main.player
	director = main.director
	main.start_mission()
	await physics_frame
	if director.phase != "INFILTRATE" or player.ammo != 30 or player.dead:
		_fail("Normal mission start did not initialize the player")
		return
	var spawn: Vector3 = player.global_position
	await _capture("visual_01_spawn")

	Input.action_press("move_forward")
	for _i in range(45):
		await physics_frame
	Input.action_release("move_forward")
	if player.dead or player.global_position.distance_to(spawn) < 0.3:
		_fail("Ordinary forward input did not move the player")
		return
	_log("walked", {"metres": player.global_position.distance_to(spawn), "position": _position()})

	_send_key(KEY_H, true)
	for _i in range(12):
		await physics_frame
	if player.get_camera().fov >= 75.0:
		_fail("Mapped aim input did not narrow the view")
		return
	await _capture("visual_02_aim")

	_send_key(KEY_G, true)
	for _i in range(20):
		await physics_frame
	await _capture("visual_03_firing")
	_send_key(KEY_G, false)
	_send_key(KEY_H, false)
	if player.ammo >= 29 or player.ammo < 24:
		_fail("Mapped fire input did not produce a short finite burst")
		return
	var fired_ammo: int = player.ammo
	_log("fired", {"ammo": fired_ammo, "health": player.health})

	_send_key(KEY_R, true)
	await process_frame
	_send_key(KEY_R, false)
	if not player.is_reloading or player.ammo != fired_ammo:
		_fail("Mapped reload input did not begin reloading")
		return
	if not await _wait_reload_progress(0.30, 4.0):
		_fail("Reload did not reach 30 percent")
		return
	await _capture("visual_04_reload_30")
	if not await _wait_reload_progress(0.70, 4.0):
		_fail("Reload did not reach 70 percent")
		return
	await _capture("visual_05_reload_70")

	_send_key(KEY_ESCAPE, true)
	await process_frame
	_send_key(KEY_ESCAPE, false)
	if not paused:
		_fail("Mapped Escape input did not pause the mission")
		return
	var frozen_progress: float = player.get_reload_progress()
	var frozen_position: Vector3 = player.global_position
	var frozen_ammo: int = player.ammo
	await _capture("visual_06_paused")
	var pause_start_ms := Time.get_ticks_msec()
	while Time.get_ticks_msec() - pause_start_ms < 350:
		await process_frame
	if absf(player.get_reload_progress() - frozen_progress) > 0.01 \
		or player.global_position.distance_to(frozen_position) > 0.01 or player.ammo != frozen_ammo:
		_fail("Pause advanced reload, ammunition or position")
		return
	_log("paused", {"reload_progress": frozen_progress, "ammo": frozen_ammo})

	_send_key(KEY_ESCAPE, true)
	await process_frame
	_send_key(KEY_ESCAPE, false)
	if paused:
		_fail("Mapped Escape input did not resume the mission")
		return
	var reload_start_ms := Time.get_ticks_msec()
	while player.is_reloading and Time.get_ticks_msec() - reload_start_ms < 4000:
		await physics_frame
	if player.is_reloading or player.ammo != 30:
		_fail("Reload did not finish after resume")
		return
	await _capture("visual_07_resumed")

	Input.action_press("hold_crouch")
	for _i in range(70):
		await physics_frame
	if not player.is_crouching:
		_fail("Crouch input did not lower the player")
		return
	await _capture("visual_08_crouched")
	Input.action_release("hold_crouch")
	for _i in range(18):
		await physics_frame
	if player.is_crouching:
		_fail("Player did not stand after crouch input was released")
		return
	await _capture("visual_09_standing")
	_log("passed", {"ammo": player.ammo, "health": player.health, "phase": director.phase, "position": _position()})
	quit(0)


func _wait_reload_progress(target: float, timeout_seconds: float) -> bool:
	var start_ms := Time.get_ticks_msec()
	while player.get_reload_progress() < target and player.is_reloading \
		and Time.get_ticks_msec() - start_ms < int(timeout_seconds * 1000.0):
		await physics_frame
	return player.is_reloading and player.get_reload_progress() >= target


func _send_key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := output_dir.path_join(label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	_log("screenshot", {"path": path, "error": error})
	if error != OK:
		push_error("Screenshot failed: " + path)


func _position() -> Array:
	return [player.global_position.x, player.global_position.y, player.global_position.z]


func _log(event: String, values: Dictionary = {}) -> void:
	values["event"] = event
	print("RENDERED_VISUAL " + JSON.stringify(values))


func _fail(reason: String) -> void:
	Input.action_release("move_forward")
	Input.action_release("hold_crouch")
	_send_key(KEY_G, false)
	_send_key(KEY_H, false)
	_log("failed", {"reason": reason, "position": _position() if player != null else []})
	quit(1)
