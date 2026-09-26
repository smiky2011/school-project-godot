extends SceneTree

# Focused rendered visual probe for the actual StG 44 sight and empty reload.
# Screenshots supplement, rather than replace, player acceptance.

var main: Node
var player: CharacterBody3D
var viewmodel: Node3D
var output_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = OS.get_environment("QA_OUTPUT_DIR")
	if output_dir == "":
		output_dir = ProjectSettings.globalize_path("res://build/qa/stg44_review")
	if not output_dir.begins_with("/") or DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		_fail("QA_OUTPUT_DIR must be an absolute writable path")
		return
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	player = main.player
	main.start_mission()
	await physics_frame
	viewmodel = player.get_camera().get_child(0) as Node3D
	if viewmodel.name != "StG44Viewmodel" or viewmodel.magazine == null or viewmodel.bolt_node == null:
		_fail("StG 44 and its movable meshes are missing")
		return
	for _i in range(12):
		await physics_frame
	await _capture("stg44_01_hip")
	Input.action_press("aim")
	for _i in range(24):
		await physics_frame
	await _capture("stg44_02_ads")
	var camera: Camera3D = player.get_camera()
	# These coordinates are measured from Body_Sight_Distance and the front
	# barrel sight vertices in the attributed FBX, not inferred from a marker.
	var sight: Vector2 = camera.unproject_position(viewmodel.model.to_global(Vector3(0.0, 0.2011, -0.006)))
	var front: Vector2 = camera.unproject_position(viewmodel.model.to_global(Vector3(0.0, 0.1998, -0.44)))
	var center := root.get_visible_rect().size * 0.5
	print("RENDERED_STG44 " + JSON.stringify({"event":"sights", "rear":sight, "front":front, "center":center}))
	if absf(front.x - center.x) > 3.0 or absf(front.y - center.y) > 3.0 \
		or absf(sight.x - center.x) > 3.0 or absf(sight.y - center.y) > 3.0:
		_fail("Real front post and rear notch do not align with screen aim")
		return
	Input.action_release("aim")
	for _i in range(18):
		await physics_frame
	player.ammo = 0
	player.call("_start_reload")
	if not player.is_reloading or not player.reload_is_empty:
		_fail("Empty reload did not start")
		return
	for phase in [0.36, 0.70, 0.87]:
		if not await _wait_reload_progress(phase):
			_fail("Empty reload failed to reach phase %s" % phase)
			return
		await _capture("stg44_empty_%02d" % roundi(phase * 100.0))
		print("RENDERED_STG44 " + JSON.stringify({"event":"reload_pose", "phase":phase,
			"magazine_position":viewmodel.magazine.position, "bolt_position":viewmodel.bolt_node.position}))
	while player.is_reloading:
		await physics_frame
	if player.ammo != 30:
		_fail("Empty reload did not restore the 30-round magazine")
		return
	await _capture("stg44_03_ready")
	print("RENDERED_STG44 " + JSON.stringify({"event":"passed", "ammo":player.ammo}))
	quit(0)


func _wait_reload_progress(target: float) -> bool:
	var start_ms := Time.get_ticks_msec()
	while player.is_reloading and player.get_reload_progress() < target \
		and Time.get_ticks_msec() - start_ms < 4000:
		await physics_frame
	return player.is_reloading and player.get_reload_progress() >= target


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := output_dir.path_join(label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	print("RENDERED_STG44 " + JSON.stringify({"event":"screenshot", "path":path, "error":error}))
	if error != OK:
		_fail("Screenshot failed")


func _fail(reason: String) -> void:
	Input.action_release("aim")
	print("RENDERED_STG44 " + JSON.stringify({"event":"failed", "reason":reason}))
	quit(1)
