extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var demo := scene.instantiate()
	root.add_child(demo)
	await physics_frame
	var town: Node3D = demo.town
	var player: CharacterBody3D = demo.player
	if not _check(town.plots.size() >= 70, "Town plots were not built"):
		return
	if not _check(player.camera != null and player.camera.current, "First-person camera missing"):
		return
	for i in range(20):
		await physics_frame
	if not _check(player.is_on_floor(), "Player did not settle on town ground"):
		return
	var start_z := player.global_position.z
	Input.action_press("move_forward")
	for i in range(40):
		await physics_frame
	Input.action_release("move_forward")
	if not _check(player.global_position.z < start_z - 1.0, "Forward movement failed"):
		return
	var moved := start_z - player.global_position.z
	for i in range(12):
		await physics_frame
	if not _check(player.is_on_floor(), "Player left floor before jump"):
		return
	Input.action_press("jump")
	for i in range(3):
		await physics_frame
	if not _check(player.velocity.y > 0.0, "Jump impulse failed"):
		return
	Input.action_release("jump")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	demo._unhandled_input(escape)
	if not _check(not player.controls_active, "Esc did not release movement"):
		return
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	demo._unhandled_input(click)
	if not _check(player.controls_active, "Click did not restore movement"):
		return
	player.global_position = Vector3(-12.0, 0.08, 18.0)
	player.velocity = Vector3.ZERO
	for i in range(4):
		await physics_frame
	Input.action_press("move_left")
	for i in range(70):
		await physics_frame
	Input.action_release("move_left")
	if not _check(player.global_position.x > -14.6, "House collision did not stop player"):
		return
	print("DEMO_SMOKE_OK plots=%d moved=%.2f collision_x=%.2f" % [
		town.plots.size(), moved, player.global_position.x])
	quit(0)


func _check(condition: bool, description: String) -> bool:
	if condition:
		return true
	push_error(description)
	quit(1)
	return false
