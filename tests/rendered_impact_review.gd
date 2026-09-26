extends SceneTree

# Focused presentation fixture: raycast a real town wall, then fire one actual
# player shot. It checks cosmetic placement and first-person pixels, but does
# not replace the full rendered combat route.
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
var _output_dir := ""
var _main: Node
var _camera: Camera3D
var _fx: Node
var _player: CharacterBody3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("Rendered impact review needs a graphics display")
		return
	_output_dir = OS.get_environment("QA_OUTPUT_DIR")
	if _output_dir == "":
		_output_dir = ProjectSettings.globalize_path("res://build/qa/impact_review")
	if not _output_dir.begins_with("/") or DirAccess.make_dir_recursive_absolute(_output_dir) != OK:
		_fail("QA_OUTPUT_DIR must be an absolute writable directory")
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_move_to_foreground()
	_main = MAIN_SCENE.instantiate()
	root.add_child(_main)
	current_scene = _main
	_player = _main.player
	_fx = _main.level.get_node_or_null("CombatFx")
	if _fx == null:
		_fail("CombatFx is missing")
		return
	_main.start_mission()
	_player.set_controls_enabled(false)
	_main.hud.visible = false
	for guard in _main.level.get_guards():
		guard.set_physics_process(false)
	_camera = Camera3D.new()
	_camera.name = "ImpactReviewCamera"
	_camera.cull_mask = 1
	_camera.fov = 76.0
	_main.add_child(_camera)
	_camera.current = true
	for _i in range(12):
		await process_frame
	var wall_from := Vector3(-19.0, 2.58, 34.0)
	var wall_target := Vector3(-19.0, 2.58, 20.0)
	_frame(wall_from, Vector3(-19.0, 2.58, 25.66))
	if not await _capture("impact_01_wall_before"):
		return
	var wall := _ray(wall_from, wall_target)
	if not _check_hit(wall, "Western homes"):
		return
	var old_hit: Vector3 = wall.position
	var incoming := (wall_target - wall_from).normalized()
	var impact_at := Time.get_ticks_usec()
	_fx.impact(old_hit, wall.normal, "plaster", true, wall.collider, incoming)
	var decal: Decal = _last_decal()
	if decal == null or decal.global_position.distance_to(Vector3(-19.0, 2.58, 25.66)) > 0.08:
		_fail("Plaster wall mark missed the visible facade")
		return
	print("IMPACT_REVIEW house old_hit=", old_hit, " visual_mark=", decal.global_position)
	for _i in range(6):
		await process_frame
	var held_particles: Array[CPUParticles3D] = []
	for child in _fx.get_children():
		if child is CPUParticles3D:
			child.speed_scale = 0.0
			held_particles.append(child)
	print("IMPACT_REVIEW wall_dust_held=", held_particles.size(), " elapsed_ms=", (Time.get_ticks_usec() - impact_at) / 1000.0)
	if not await _capture("impact_02_wall_dust", 1):
		return
	for particles in held_particles:
		particles.visible = false
	_frame(Vector3(-19.0, 2.58, 28.2), Vector3(-19.0, 2.58, 25.66))
	if not await _capture("impact_03_wall_close", 2):
		return
	var count_before: int = (_fx.get("_decals") as Array).size()
	var door_from := Vector3(-16.75, 1.5, 34.0)
	var door_hit := _ray(door_from, Vector3(-16.75, 1.5, 20.0))
	if not _check_hit(door_hit, "Western homes"):
		return
	_fx.impact(door_hit.position, door_hit.normal, "plaster", true, door_hit.collider, Vector3.FORWARD)
	if (_fx.get("_decals") as Array).size() != count_before:
		_fail("Hidden mass behind door created a floating mark")
		return
	var player_camera: Camera3D = _player.get_camera()
	player_camera.current = true
	if not await _capture("impact_04_tracer_before", 2):
		return
	var before_frame := root.get_texture().get_image()
	# PNG encoding delays the next idle frame. Let that artificial hitch pass
	# before launching the short-lived tracer for a representative sample.
	for _i in range(4):
		await process_frame
	var shots_before: int = _player.shots_fired
	var fired_at := Time.get_ticks_usec()
	_player.call("_fire")
	if _player.shots_fired != shots_before + 1:
		_fail("Player fire did not create a shot")
		return
	var active_tracers: Array = _fx.get("_tracers")
	if active_tracers.is_empty():
		_fail("Player fire did not create a tracer")
		return
	# A PNG readback stalls the game long enough for a 340 m/s tracer to finish
	# its flight. Advance one controlled 25 ms step, then hold its actual
	# in-flight geometry while the renderer saves the frame.
	_fx.set_process(false)
	_fx.call("_process", 0.025)
	var t: Dictionary = active_tracers.back()
	var head: Vector3 = t.from + t.dir * minf(t.travel, t.distance)
	var screen: Vector2 = player_camera.unproject_position(head)
	print("IMPACT_REVIEW tracer_state travel=", t.travel, " elapsed_ms=", (Time.get_ticks_usec() - fired_at) / 1000.0,
		" head=", head, " screen=", screen, " camera=", player_camera.global_position)
	if not t.node.visible or not t.glow.visible or t.travel < 5.0 or t.travel > 12.0 \
			or player_camera.is_position_behind(head) or screen.x < 0.0 or screen.x > 1280.0 or screen.y < 0.0 or screen.y > 720.0:
		_fail("Controlled player tracer is not visible in its early flight")
		return
	if not await _capture("impact_05_tracer_inflight", 1):
		return
	var after_frame := root.get_texture().get_image()
	var strongest_red_gain := 0.0
	var strongest_warm_gain := 0.0
	for y in range(int(screen.y) - 4, int(screen.y) + 5):
		for x in range(int(screen.x) - 4, int(screen.x) + 5):
			var before: Color = before_frame.get_pixel(x, y)
			var after: Color = after_frame.get_pixel(x, y)
			var red_gain := after.r - before.r
			strongest_red_gain = maxf(strongest_red_gain, red_gain)
			strongest_warm_gain = maxf(strongest_warm_gain, red_gain - (after.b - before.b))
	print("IMPACT_REVIEW tracer_pixel red_gain=", strongest_red_gain, " warm_gain=", strongest_warm_gain)
	if strongest_red_gain < 0.1 or strongest_warm_gain < 0.08:
		_fail("In-flight tracer has no distinct warm pixels at its projected head")
		return
	print("IMPACT_REVIEW tracer_capture_elapsed_ms=", (Time.get_ticks_usec() - fired_at) / 1000.0)
	print("IMPACT_REVIEW PASS wall/door/actual-player-tracer frames=5")
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, false)
	quit(0)


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = [_player.get_rid()]
	return _main.get_world_3d().direct_space_state.intersect_ray(query)


func _check_hit(hit: Dictionary, label: String) -> bool:
	if hit.is_empty() or hit.collider.name != label:
		_fail("Ray missed expected " + label + "; got " + (str(hit.collider.name) if not hit.is_empty() else "nothing"))
		return false
	return true


func _last_decal() -> Decal:
	var decals: Array = _fx.get("_decals")
	return decals.back() as Decal if not decals.is_empty() else null


func _frame(position: Vector3, target: Vector3) -> void:
	_camera.global_position = position
	_camera.look_at(target)


func _capture(label: String, warmup_frames: int = 8) -> bool:
	DisplayServer.window_move_to_foreground()
	var started_at := Time.get_ticks_usec()
	for _i in range(warmup_frames):
		await process_frame
	await RenderingServer.frame_post_draw
	var path := _output_dir.path_join(label + ".png")
	var result := root.get_texture().get_image().save_png(path)
	print("IMPACT_REVIEW_FRAME name=", label, " save=", result, " elapsed_ms=", (Time.get_ticks_usec() - started_at) / 1000.0, " path=", path)
	if result != OK:
		_fail("Could not save " + label)
	return result == OK


func _fail(reason: String) -> void:
	push_error("IMPACT_REVIEW FAIL: " + reason)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, false)
	quit(1)
