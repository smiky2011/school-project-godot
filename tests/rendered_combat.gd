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

	# A one-frame down-look sets the center ray on the distant guard's torso.
	Input.action_press("look_down")
	await physics_frame
	Input.action_release("look_down")
	Input.action_press("fire")
	await physics_frame
	await _capture("combat_02_first_shot")
	var first_ammo: int = player.ammo
	_log("first_shot", {"ammo": first_ammo, "kills": director.kills, "hit_marker": player.hit_marker})
	if first_ammo >= 30:
		Input.action_release("fire")
		_fail("Fire input did not consume a round")
		return

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
