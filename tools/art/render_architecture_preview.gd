extends SceneTree

# Godot import/render probe for the two reusable exterior models.
# Run with a real graphics display: Godot --path . --script res://tools/art/render_architecture_preview.gd

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.58, 0.63, 0.66)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.75, 0.78, 0.80)
	settings.ambient_light_energy = 0.8
	environment.environment = settings
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-47, -31, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	world.add_child(sun)
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(38, 30)
	floor.mesh = floor_mesh
	var ground := StandardMaterial3D.new()
	ground.albedo_color = Color(0.34, 0.36, 0.34)
	ground.roughness = 1.0
	floor.material_override = ground
	world.add_child(floor)
	for variant in ["stone_gable", "plaster_hip"]:
		var source := load("res://assets/environment/townhouse_%s_9x16.glb" % variant) as PackedScene
		if source == null:
			push_error("Could not load %s" % variant)
			quit(2)
			return
		var building := source.instantiate()
		building.position.x = -6.8 if variant == "stone_gable" else 6.8
		world.add_child(building)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(17, 12.5, 27)
	camera.look_at(Vector3(0, 3.5, 0))
	camera.fov = 54
	camera.current = true
	for i in range(15):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var output := "res://docs/media/preview_townhouses.png"
	var error := image.save_png(ProjectSettings.globalize_path(output))
	print("ARCHITECTURE_PREVIEW ", output, " ", image.get_width(), "x", image.get_height(), " result=", error)
	quit(0 if error == OK else 3)
