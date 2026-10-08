extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var demo := scene.instantiate()
	root.add_child(demo)
	for i in range(30):
		await process_frame
	var destination := "/private/tmp/town_map_movement_spawn.png"
	var result := root.get_texture().get_image().save_png(destination)
	if result != OK:
		push_error("Could not save rendered spawn image: %d" % result)
		quit(1)
		return
	print("DEMO_CAPTURE_OK " + destination)
	quit(0)
