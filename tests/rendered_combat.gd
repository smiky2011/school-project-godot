extends SceneTree

# Rendered input-driven combat smoke from the normal mission spawn. No
# transforms, enemy flags, health, ammunition or mission phases are injected.
# Run with Godot --path . --script res://tests/rendered_combat.gd

var main: Node
var player: CharacterBody3D
var director: Node
var level: Node3D
var output_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = OS.get_environment("QA_OUTPUT_DIR")
	if output_dir == "":
		output_dir = ProjectSettings.globalize_path("res://build/qa/combat")
	if not output_dir.begins_with("/") or DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		_fail("QA_OUTPUT_DIR must be an absolute writable directory")
		return
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("Main scene did not load")
		return
	main = packed.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	player = main.player
	director = main.director
	level = main.level
	main.start_mission()
	await physics_frame
	_log("start", {"position": _position(), "ammo": player.ammo, "guards": level.get_guards().size()})
	await _capture("combat_01_spawn")

	# The default camera faces north. Walk along the open entry street with
	# ordinary movement so the first patrol is in a clear, physical sightline.
	Input.action_press("move_forward")
	var walk_seconds := 0.0
	while player.global_position.z > 178.0 and walk_seconds < 14.0 and not player.dead:
		await physics_frame
		walk_seconds += 1.0 / 60.0
	Input.action_release("move_forward")
	if player.dead or player.global_position.z > 179.0:
		_fail("Could not reach the shooting position through normal collision")
		return
	_log("shooting_position", {"position": _position(), "walk_seconds": walk_seconds})

	# Architecture and live patrol movement changed the old fixed camera angle.
	# Read the patrol's position, then steer with the ordinary look actions until
	# the game's center ray sees its body. Never assign any actor transform.
	var target: CharacterBody3D
	for guard in level.get_guards():
		if guard.name == "South west patrol":
			target = guard
			break
	if target == null or not await _aim_at(target):
		_fail("Could not establish a physical center-ray sightline to the south west patrol")
		return
	Input.action_press("aim")
	for _i in range(12):
		await physics_frame
	if not await _aim_at(target):
		_fail("Lost the physical patrol sightline while aiming down sights")
		return
	var first_ammo: int = player.ammo
	Input.action_press("fire")
	await physics_frame
	Input.action_release("fire")
	var first_hit: float = player.hit_marker
	_log("first_shot", {"ammo": player.ammo, "kills": director.kills, "hit_marker": first_hit, "target_state": target.state})
	await _capture("combat_02_first_shot")
	if player.ammo >= first_ammo or first_hit <= 0.0:
		_fail("Aimed first shot did not consume a round and hit the physical guard body")
		return
	# Reacquire the moving torso after recoil. Three genuine bullet rays should
	# kill the guard before the rest of the finite magazine is emptied.
	var aimed_shots := 1
	while target.state != "DEAD" and aimed_shots < 8 and not player.dead:
		for _i in range(7):
			await physics_frame
		if not await _aim_at(target):
			_fail("Lost the physical patrol sightline before a kill")
			return
		Input.action_press("fire")
		await physics_frame
		Input.action_release("fire")
		aimed_shots += 1
	if target.state != "DEAD":
		_fail("Aimed physical player rays did not kill the guard")
		return
	_log("guard_killed", {"aimed_shots": aimed_shots, "ammo": player.ammo, "kills": director.kills})

	Input.action_release("aim")
	Input.action_press("fire")
	var fire_seconds := 0.0
	while player.ammo > 0 and fire_seconds < 6.0 and not player.dead:
		await physics_frame
		fire_seconds += 1.0 / 60.0
	Input.action_release("fire")
	if player.dead or player.ammo != 0:
		_fail("Automatic fire did not empty a finite magazine")
		return
	await _capture("combat_03_empty")
	_log("empty_magazine", {"ammo": player.ammo, "kills": director.kills, "fire_seconds": fire_seconds, "guard_states": _guard_states()})
	if director.kills < 1:
		_fail("No guard was killed through actual player bullet rays")
		return

	# An empty trigger must not make an extra shot. Reload goes through the
	# mapped R key event, as in normal player input.
	Input.action_press("fire")
	for _i in range(12):
		await physics_frame
	Input.action_release("fire")
	if player.ammo != 0:
		_fail("Empty trigger changed ammunition without reloading")
		return
	_send_key(KEY_R, true)
	await process_frame
	_send_key(KEY_R, false)
	var reload_seconds := 0.0
	var observed_reloading: bool = player.is_reloading
	while player.ammo == 0 and reload_seconds < 4.0 and not player.dead:
		await physics_frame
		reload_seconds += 1.0 / 60.0
		observed_reloading = observed_reloading or player.is_reloading
	if player.dead or not observed_reloading or player.ammo != 30 or player.is_reloading:
		_fail("Mapped R key did not complete the required reload")
		return
	await _capture("combat_04_reloaded")
	_log("passed", {"position": _position(), "kills": director.kills, "ammo": player.ammo, "reload_seconds": reload_seconds, "health": player.health, "phase": director.phase})
	quit(0)


func _send_key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _aim_at(target: CharacterBody3D) -> bool:
	var camera := player.get_camera() as Camera3D
	for _i in range(120):
		if player.dead or target.state == "DEAD":
			break
		var to_target: Vector3 = target.global_position + Vector3.UP * 1.1 - camera.global_position
		var desired_yaw := atan2(-to_target.x, -to_target.z)
		var yaw_error := wrapf(desired_yaw - player.rotation.y, -PI, PI)
		var desired_pitch := atan2(to_target.y, Vector2(to_target.x, to_target.z).length())
		var current_pitch := asin(clampf(-camera.global_basis.z.y, -1.0, 1.0))
		var pitch_error := desired_pitch - current_pitch
		if absf(yaw_error) < 0.004 and absf(pitch_error) < 0.004:
			var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 90.0)
			query.exclude = [player.get_rid()]
			var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty() and hit["collider"] == target:
				_release_look()
				return true
		if absf(yaw_error) >= 0.004:
			var yaw_strength := clampf(absf(yaw_error) / (1.7 / 60.0), 0.25, 1.0)
			Input.action_press("look_left" if yaw_error > 0.0 else "look_right", yaw_strength)
		if absf(pitch_error) >= 0.004:
			var pitch_strength := clampf(absf(pitch_error) / (1.7 / 60.0), 0.25, 1.0)
			Input.action_press("look_up" if pitch_error > 0.0 else "look_down", pitch_strength)
		await physics_frame
		_release_look()
	return false


func _release_look() -> void:
	for action in ["look_left", "look_right", "look_up", "look_down"]:
		Input.action_release(action)


func _guard_states() -> Array:
	var result := []
	for guard in level.get_guards():
		result.append({"name": guard.name, "state": guard.state})
	return result


func _position() -> Array:
	return [player.global_position.x, player.global_position.y, player.global_position.z]


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := output_dir.path_join(label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	_log("screenshot", {"path": path, "error": error})


func _log(event: String, values: Dictionary = {}) -> void:
	values["event"] = event
	print("RENDERED_COMBAT " + JSON.stringify(values))


func _fail(reason: String) -> void:
	Input.action_release("move_forward")
	Input.action_release("look_down")
	Input.action_release("fire")
	_log("failed", {"reason": reason, "position": _position() if player != null else []})
	quit(1)
