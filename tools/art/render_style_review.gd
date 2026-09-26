extends SceneTree

# Fixed-camera style review of the real mission scene for comparison with the
# selected references in reference/games (G01-07..G01-12). Output PNGs go to
# $STYLE_OUT (default build/qa/style). Camera placement only; not route
# evidence. Run with a display:
#   Godot --path . --script res://tools/art/render_style_review.gd

const VIEWS := [
	["01_spawn_street", Vector3(-48.0, 0.08, 196.0), Vector3(-48.0, 1.5, 150.0)],
	["02_south_crossing", Vector3(-30.0, 0.08, 130.0), Vector3(10.0, 2.0, 125.0)],
	["03_east_street", Vector3(12.0, 0.08, 90.0), Vector3(12.0, 1.8, 40.0)],
	["04_courtyard", Vector3(-4.0, 0.08, 26.0), Vector3(3.0, 2.2, -16.0)],
	["05_north_lane", Vector3(-48.0, 0.08, -70.0), Vector3(-48.0, 1.8, -130.0)],
	["06_exit_shelter", Vector3(40.0, 0.08, -178.0), Vector3(46.0, 1.4, -200.0)],
	["07_sun_check", Vector3(-48.0, 0.08, 150.0), Vector3.INF],
	["08_wall_base", Vector3(-49.5, 0.08, 176.0), Vector3(-54.0, 0.6, 168.0)],
	["09_sentry_post", Vector3(-17.0, 0.08, 99.0), Vector3(-23.0, 0.8, 89.0)],
	["10_contact_desk", Vector3(1.8, 3.27, -26.8), Vector3(3.6, 3.9, -29.5)],
	["11_ruin_square", Vector3(45.0, 0.08, 88.0), Vector3(30.0, 1.5, 76.0)],
	["12_edge_view", Vector3(-58.0, 0.08, 20.0), Vector3(-120.0, 3.0, -10.0)],
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var out := OS.get_environment("STYLE_OUT")
	if out == "":
		out = ProjectSettings.globalize_path("res://build/qa/style")
	DirAccess.make_dir_recursive_absolute(out)
	var only := OS.get_environment("STYLE_ONLY")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	main.start_mission()
	var player: CharacterBody3D = main.player
	player.set_controls_enabled(false)
	main.hud.visible = false if "visible" in main.hud else true
	for view in VIEWS:
		if only != "" and not String(view[0]).begins_with(only):
			continue
		player.global_position = view[1]
		player.velocity = Vector3.ZERO
		await physics_frame
		var camera: Camera3D = player.get_camera()
		var target: Vector3 = view[2]
		if target == Vector3.INF:
			var atmosphere = load("res://scripts/world/town_atmosphere.gd")
			target = camera.global_position + atmosphere.sun_direction() * 50.0
		camera.look_at(target)
		for i in range(24):
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path: String = out.path_join(String(view[0]) + ".png")
		print("STYLE_REVIEW ", path, " result=", image.save_png(path))
	quit()
