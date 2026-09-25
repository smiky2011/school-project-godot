extends SceneTree

# Synthetic overhead fixture, real town floor and physics. This catches both a
# floor-touch false positive and a standing-through-low-ceiling false negative.
# Run: Godot --headless --path . --script res://tests/player_stance_regression.gd

var main: Node
var player: CharacterBody3D
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("Main scene failed to load")
		return
	main = packed.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	main.start_mission()
	player = main.player
	for guard in main.level.get_guards():
		guard.process_mode = Node.PROCESS_MODE_DISABLED
	await _physics_frames(75)
	if not _check(player.is_on_floor(), "Player settled on actual town floor"):
		return
	var standing_origin := player.global_position

	Input.action_press("hold_crouch")
	await _physics_frames(75)
	if not _check(player.is_crouching, "Crouch held for more than one second"):
		return
	Input.action_release("hold_crouch")
	await _physics_frames(30)
	if not _check(not player.is_crouching, "Open floor allows standing after sustained crouch"):
		return
	if not _check(player.global_position.distance_to(standing_origin) < 0.2, "Standing did not require a position jump"):
		return

	Input.action_press("hold_crouch")
	await _physics_frames(30)
	if not _check(player.is_crouching, "Player crouched before entering the low-ceiling fixture"):
		return
	var ceiling := StaticBody3D.new()
	ceiling.name = "Synthetic low ceiling"
	ceiling.collision_layer = 1
	ceiling.collision_mask = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 0.2, 2.0)
	shape.shape = box
	ceiling.add_child(shape)
	main.level.add_child(ceiling)
	ceiling.global_position = Vector3(player.global_position.x, 1.4, player.global_position.z)
	await _physics_frames(2)
	if not _check(player.is_crouching, "Player can crouch beneath synthetic low ceiling"):
		return
	Input.action_release("hold_crouch")
	await _physics_frames(30)
	if not _check(player.is_crouching, "Low ceiling blocks standing"):
		return

	Input.action_press("move_right")
	await _physics_frames(145)
	Input.action_release("move_right")
	var horizontal_distance := Vector2(player.global_position.x - ceiling.global_position.x,
		player.global_position.z - ceiling.global_position.z).length()
	if not _check(horizontal_distance > 1.5, "Crouched movement left the low ceiling"):
		return
	if not _check(not player.is_crouching, "Player stood after leaving the low ceiling"):
		return
	print("STANCE PASS checks=%d initial_y=%.3f final_y=%.3f" % [checks, standing_origin.y, player.global_position.y])
	quit(0)


func _physics_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame


func _check(condition: bool, message: String) -> bool:
	if condition:
		checks += 1
		print("STANCE CHECK %d %s" % [checks, message])
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	Input.action_release("hold_crouch")
	Input.action_release("move_right")
	push_error("STANCE FAIL: " + message)
	quit(1)
