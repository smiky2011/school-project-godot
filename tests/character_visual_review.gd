extends SceneTree

# Isolated rendered asset inspection. This does not exercise mission gameplay.
# Run with Godot --path . --script res://tests/character_visual_review.gd


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var scene := load("res://assets/vendor/character_visual/makehuman/runtime/contact_idle.glb") as PackedScene
	if scene == null:
		push_error("Contact idle GLB did not import")
		quit(2)
		return
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.20, 0.22, 0.23)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.73, 0.77, 0.80)
	settings.ambient_light_energy = 0.70
	environment.environment = settings
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-39, -25, 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	world.add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6, 6)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.32, 0.33, 0.32)
	floor_material.roughness = 1.0
	floor.material_override = floor_material
	world.add_child(floor)
	var person := scene.instantiate()
	world.add_child(person)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(1.05, 1.40, 3.0)
	camera.look_at(Vector3(0, 0.88, 0))
	camera.fov = 49
	camera.current = true
	var mesh_count := _count_meshes(person)
	if mesh_count != 7:
		push_error("Expected 7 actual character meshes; found %d" % mesh_count)
		quit(3)
		return
	for _i in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://build/qa/contact_godot_preview.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var screenshot := root.get_texture().get_image()
	var saved := screenshot.save_png(output)
	print("CHARACTER_GODOT_PREVIEW meshes=%d image=%s size=%dx%d save=%d" % [
		mesh_count, output, screenshot.get_width(), screenshot.get_height(), saved])
	quit(0 if saved == OK else 4)


func _count_meshes(node: Node) -> int:
	var total := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		total += _count_meshes(child)
	return total
