extends SceneTree

# Fixed camera locations for visual review of the actual mission scene.
# These are rendered inspection views, not gameplay-route acceptance evidence.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var source := load("res://scenes/main.tscn") as PackedScene
	var main := source.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	main.start_mission()
	await _capture("res://docs/media/town_spawn_preview.png")
	var player: CharacterBody3D = main.player
	player.set_controls_enabled(false)
	player.global_position = Vector3(12.0, 0.08, 43.0)
	player.velocity = Vector3.ZERO
	await _capture("res://docs/media/town_approach_preview.png")
	player.global_position = Vector3(-2.5, 0.08, -17.1)
	player.velocity = Vector3.ZERO
	await physics_frame
	player.get_camera().look_at(Vector3(-2.6, 1.8, -23.2))
	await _capture("res://docs/media/town_contact_entry_preview.png")
	player.global_position = Vector3(1.5, 3.27, -26.5)
	player.velocity = Vector3.ZERO
	await physics_frame
	player.get_camera().look_at(Vector3(3.6, 3.9, -29.3))
	await _capture("res://docs/media/town_contact_room_preview.png")
	player.global_position = Vector3(18.5, 0.08, 7.5)
	player.velocity = Vector3.ZERO
	await physics_frame
	player.get_camera().look_at(Vector3(18.5, 2.2, -7.0))
	await _capture("res://docs/media/town_narrow_passage_preview.png")
	player.global_position = Vector3(44.0, 0.08, -188.0)
	player.velocity = Vector3.ZERO
	await physics_frame
	player.get_camera().look_at(Vector3(45.0, 1.55, -198.0))
	await _capture("res://docs/media/town_exit_preview.png")
	player.global_position = Vector3(44.0, 0.08, -193.6)
	player.velocity = Vector3.ZERO
	await physics_frame
	player.get_camera().look_at(Vector3(44.0, 1.45, -198.0))
	await _capture("res://docs/media/town_scout_close_preview.png")
	quit()


func _capture(path: String) -> void:
	for i in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(path))
	print("STREET_PREVIEW ", path, " ", image.get_width(), "x", image.get_height(), " result=", error)
