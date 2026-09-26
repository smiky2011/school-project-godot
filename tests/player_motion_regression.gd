extends SceneTree

# Real CharacterBody motion on a flat collision fixture. The viewmodel's
# distance-driven gait is checked against blocked and airborne movement.
# Run: Godot --headless --path . --script res://tests/player_motion_regression.gd

const PLAYER_SCRIPT: Script = preload("res://scripts/player/player.gd")

var player: CharacterBody3D
var world: Node3D
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_define_actions()
	world = Node3D.new()
	root.add_child(world)
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(100.0, 1.0, 100.0))
	player = PLAYER_SCRIPT.new() as CharacterBody3D
	world.add_child(player)
	player.set_controls_enabled(true)
	await _physics_frames(10)
	if not _check(player.is_on_floor(), "Player settled on fixture floor"):
		return

	Input.action_press("move_forward")
	await _physics_frames(1)
	var first_speed := _horizontal_speed()
	if not _check(first_speed > 0.0 and first_speed < 1.5, "Walk accelerates instead of jumping to full speed"):
		return
	await _physics_frames(18)
	if not _check(absf(_horizontal_speed() - player.WALK_SPEED) < 0.08, "Walk reaches existing speed cap"):
		return
	Input.action_release("move_forward")
	var stop_origin := player.global_position
	await _physics_frames(20)
	if not _check(_horizontal_speed() < 0.02 and player.global_position.distance_to(stop_origin) < 0.4, "Release brakes within a short stopping distance"):
		return

	Input.action_press("move_forward")
	await _physics_frames(18)
	Input.action_release("move_forward")
	Input.action_press("move_back")
	await _physics_frames(9)
	if not _check(player.velocity.z > 0.0, "Opposite input reverses direction promptly"):
		return
	Input.action_release("move_back")
	await _physics_frames(20)

	Input.action_press("move_forward")
	Input.action_press("sprint")
	await _physics_frames(20)
	if not _check(player.is_sprinting and absf(_horizontal_speed() - player.SPRINT_SPEED) < 0.08, "Sprint reaches its existing speed cap"):
		return
	Input.action_release("sprint")
	Input.action_press("aim")
	await _physics_frames(1)
	if not _check(_horizontal_speed() <= player.WALK_SPEED + 0.02, "Leaving sprint applies the lower stance cap immediately"):
		return
	Input.action_release("aim")
	Input.action_release("move_forward")
	await _physics_frames(20)

	Input.action_press("hold_crouch")
	Input.action_press("move_forward")
	await _physics_frames(18)
	if not _check(player.is_crouching and absf(_horizontal_speed() - player.CROUCH_SPEED) < 0.08, "Crouch reaches its existing speed cap"):
		return
	Input.action_release("hold_crouch")
	Input.action_press("aim")
	await _physics_frames(20)
	var aimed_cap: float = player.WALK_SPEED * 0.62
	if not _check(not player.is_crouching and player.aim_amount > 0.99 and absf(_horizontal_speed() - aimed_cap) < 0.08, "ADS keeps its existing movement cap"):
		return
	Input.action_release("aim")
	Input.action_release("move_forward")
	await _physics_frames(20)

	var wall := _add_box(player.global_position + Vector3(0.52, 1.2, 0.0), Vector3(0.2, 2.4, 5.0))
	Input.action_press("move_right")
	await _physics_frames(20)
	var blocked_origin := player.global_position
	var viewmodel: Node3D = player.get("_weapon")
	var blocked_phase: float = viewmodel.get("_walk_cycle")
	await _physics_frames(20)
	if not _check(player.global_position.distance_to(blocked_origin) < 0.02 and absf(viewmodel.get("_walk_cycle") - blocked_phase) < 0.02, "Blocked input does not advance weapon gait"):
		return
	Input.action_release("move_right")
	wall.queue_free()
	await _physics_frames(3)

	Input.action_press("jump")
	Input.action_press("move_right")
	await _physics_frames(1)
	Input.action_release("jump")
	var airborne_phase: float = viewmodel.get("_walk_cycle")
	await _physics_frames(8)
	if not _check(not player.is_on_floor() and absf(viewmodel.get("_walk_cycle") - airborne_phase) < 0.02, "Air movement does not advance weapon gait"):
		return
	Input.action_release("move_right")
	print("MOTION PASS checks=%d" % checks)
	quit(0)


func _define_actions() -> void:
	for action in ["move_left", "move_right", "move_forward", "move_back", "look_left", "look_right", "look_up", "look_down", "hold_crouch", "toggle_crouch", "aim", "sprint", "fire", "jump", "reload", "stealth_kill"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)


func _add_box(position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	world.add_child(body)
	body.global_position = position
	return body


func _horizontal_speed() -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()


func _physics_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame


func _check(condition: bool, message: String) -> bool:
	if condition:
		checks += 1
		print("MOTION CHECK %d %s" % [checks, message])
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	for action in ["move_forward", "move_back", "move_right", "hold_crouch", "aim", "jump", "sprint"]:
		Input.action_release(action)
	push_error("MOTION FAIL: " + message)
	quit(1)
