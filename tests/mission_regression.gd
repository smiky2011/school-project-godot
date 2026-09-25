extends SceneTree

# Standalone integration runner: Godot --headless --path . --script res://tests/mission_regression.gd
# Synthetic positioning and guard states exercise the real mission scene and input
# paths. Rendered route traversal remains a separate manual acceptance requirement.

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	_check(main != null and main.director != null and main.level != null and main.player != null, "Main creates its real scene graph")
	if main == null:
		_finish()
		return
	var director = main.director
	var player = main.player
	var level = main.level
	var initial_guards: int = level.get_guards().size()
	_check(initial_guards >= 1 and director.phase == "INFILTRATE" and not director.lockdown, "New mission has initial guards and infiltration phase")
	main.start_mission()
	for guard in level.get_guards():
		guard.process_mode = Node.PROCESS_MODE_DISABLED
		guard.state = "PATROL"
		guard.suspicion = 0.0
	var time_before_pause: float = director.mission_time
	var position_before_pause: Vector3 = player.global_position
	Input.action_press("move_forward")
	paused = true
	await create_timer(0.25, true).timeout
	_check(is_equal_approx(director.mission_time, time_before_pause), "Pause freezes mission clock")
	_check(player.global_position.distance_to(position_before_pause) < 0.001, "Pause freezes player physics")
	paused = false
	Input.action_release("move_forward")
	player.global_position = level.get_contact_position() + Vector3(0.0, 0.0, 2.0)
	player.velocity = Vector3.ZERO
	await physics_frame
	await process_frame
	_check(director.interaction_text.contains("Hold E"), "Upstairs contact is reachable by the real interaction check")

	# A partial handoff must not produce the packet; release cancels progress.
	Input.action_press("interact")
	await create_timer(0.35).timeout
	_check(director.handoff_progress > 0.0 and director.phase == "INFILTRATE", "Partial safe hold progresses without awarding packet")
	Input.action_release("interact")
	await create_timer(0.05).timeout
	_check(director.handoff_progress == 0.0 and director.phase == "INFILTRATE", "Release resets the entire handoff")
	Input.action_press("interact")
	await create_timer(0.3).timeout
	_check(director.handoff_progress > 0.0, "Second contact attempt begins normally")
	var guard = level.get_guards()[0]
	guard.state = "COMBAT"
	await create_timer(0.08).timeout
	_check(director.handoff_progress == 0.0 and director.phase == "INFILTRATE", "Pursuit resuming mid-handoff discards partial exchange")
	Input.action_release("interact")

	# Even within range, active pursuit or a search near contact blocks exchange.
	Input.action_press("interact")
	await create_timer(0.2).timeout
	_check(director.handoff_progress == 0.0 and director.phase == "INFILTRATE", "Combat blocks contact handoff")
	guard.state = "SEARCH"
	guard.global_position = level.get_contact_position() + Vector3(4.0, -3.2, 0.0)
	await create_timer(0.2).timeout
	_check(director.handoff_progress == 0.0, "Nearby search blocks contact handoff")
	guard.state = "PATROL"
	guard.suspicion = 0.0
	Input.action_release("interact")
	await process_frame

	# A physics blocker between the actual camera and noncolliding NPC blocks E.
	var blocker := StaticBody3D.new()
	var block_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 2.0, 0.2)
	block_shape.shape = shape
	blocker.add_child(block_shape)
	main.add_child(blocker)
	blocker.global_position = level.get_contact_position() + Vector3(0.0, 1.2, 1.0)
	await physics_frame
	Input.action_press("interact")
	await create_timer(0.2).timeout
	_check(director.handoff_progress == 0.0 and director.interaction_text.contains("room"), "Solid blocker prevents handoff through wall")
	Input.action_release("interact")
	blocker.queue_free()
	await physics_frame
	await process_frame

	# Same horizontal spot below the upstairs contact must not interact through floor.
	player.global_position = Vector3(level.get_contact_position().x, 0.8, level.get_contact_position().z)
	player.velocity = Vector3.ZERO
	Input.action_press("interact")
	await create_timer(0.2).timeout
	_check(director.handoff_progress == 0.0 and director.phase == "INFILTRATE", "Different floor cannot acquire packet")
	Input.action_release("interact")
	player.global_position = level.get_contact_position() + Vector3(0.0, 0.0, 2.0)
	player.velocity = Vector3.ZERO
	await physics_frame
	await process_frame

	# The full uninterrupted hold advances the objective before narrative alarm.
	Input.action_press("interact")
	await create_timer(3.3).timeout
	Input.action_release("interact")
	_check(director.phase == "INTEL_SECURED" and not director.lockdown, "Complete hold gives packet and changes objective before alarm")
	_check(director.get_objective_position().distance_to(level.get_extraction_position()) < 0.01, "Objective now points to extraction")
	await create_timer(9.0).timeout
	_check(director.lockdown and level.get_guards().size() > initial_guards, "Discovery and radio order trigger finite reinforcement")
	var reinforced_count: int = level.get_guards().size()
	await create_timer(0.2).timeout
	_check(level.get_guards().size() == reinforced_count, "Lockdown does not spawn guards repeatedly")

	# Lockdown alone does not disable recovery; dead players cannot recover.
	for current_guard in level.get_guards():
		current_guard.process_mode = Node.PROCESS_MODE_DISABLED
		current_guard.state = "PATROL"
	player.health = 50.0
	player._damage_timer = 7.1
	await create_timer(0.25).timeout
	_check(player.health > 50.0, "Health regenerates during lockdown when no guard threatens")
	player.health = 0.0
	player.dead = true
	player.set_controls_enabled(false)
	await create_timer(0.2).timeout
	_check(player.health == 0.0, "Dead player does not regenerate")
	player.dead = false
	player.health = 80.0
	player.set_controls_enabled(true)

	# Ammo is finite per magazine; pressing reload refills from unlimited reserve.
	player.ammo = 30
	Input.action_press("fire")
	await create_timer(3.4).timeout
	Input.action_release("fire")
	_check(player.ammo == 0, "Sustained automatic fire consumes the finite magazine")
	await create_timer(0.2).timeout
	director.last_noise = 0.0
	Input.action_press("fire")
	await create_timer(0.15).timeout
	Input.action_release("fire")
	_check(player.ammo == 0 and director.last_noise == 0.0 and player.shot_flash == 0.0, "Empty magazine produces no shot or noise")
	var reload_press := InputEventKey.new()
	reload_press.physical_keycode = KEY_R
	reload_press.pressed = true
	Input.parse_input_event(reload_press)
	await process_frame
	_check(player.is_reloading, "R starts reload")
	var reload_release := InputEventKey.new()
	reload_release.physical_keycode = KEY_R
	reload_release.pressed = false
	Input.parse_input_event(reload_release)
	await create_timer(2.1).timeout
	_check(player.ammo == 30 and not player.is_reloading, "Reload restores magazine")

	# The final interaction remains one press even while local combat is active.
	guard.state = "COMBAT"
	player.global_position = level.get_extraction_position() + Vector3(-1.4, 0.0, 0.0)
	player.velocity = Vector3.ZERO
	await physics_frame
	await create_timer(0.08).timeout
	_check(director.interaction_text.contains("Press E"), "Scout remains available under combat")
	_send_key(KEY_E, true)
	await create_timer(0.08).timeout
	_send_key(KEY_E, false)
	_check(director.phase == "EXTRACTED" and not director.running, "Single extraction press completes under combat")

	# Two full reloads must clear bodies, searches, packet, alarm, health and ammo.
	for cycle in range(2):
		main.retry_mission()
		await process_frame
		await process_frame
		main = current_scene
		_check(main != null, "Full restart %d loads a new Main" % (cycle + 1))
		if main == null:
			break
		director = main.director
		player = main.player
		level = main.level
		_check(director.phase == "INFILTRATE" and not director.lockdown and director.kills == 0, "Restart %d clears mission and alarm" % (cycle + 1))
		_check(player.health == 100.0 and player.ammo == 30 and not player.dead, "Restart %d restores health and ammunition" % (cycle + 1))
		_check(level.get_guards().size() == initial_guards and _all_guards_fresh(level), "Restart %d clears bodies, search and reinforcement" % (cycle + 1))
		main.start_mission()
		var victim = level.get_guards()[0]
		victim.process_mode = Node.PROCESS_MODE_DISABLED
		victim.stealth_kill()
		_check(victim.state == "DEAD" and director.kills == 1, "Guard death counts exactly once in cycle %d" % (cycle + 1))
		if cycle == 1:
			director.lockdown = true
		player.take_damage(200.0)
		_check(director.phase == "FAILED" and player.dead and not player.controls_enabled, "Lethal damage fails the mission %s lockdown" % ("after" if cycle == 1 else "before"))

	# The rare short route to extraction still performs exposure and finishes
	# on the first press, without a second interaction or a waiting death window.
	main.retry_mission()
	await process_frame
	await process_frame
	main = current_scene
	director = main.director
	player = main.player
	level = main.level
	for current_guard in level.get_guards():
		current_guard.process_mode = Node.PROCESS_MODE_DISABLED
		current_guard.state = "PATROL"
	main.start_mission()
	player.global_position = level.get_contact_position() + Vector3(0.0, 0.0, 2.0)
	await physics_frame
	Input.action_press("interact")
	await create_timer(3.3).timeout
	Input.action_release("interact")
	_check(director.phase == "INTEL_SECURED" and not director.lockdown, "Early exit setup has packet before scheduled alarm")
	_send_key(KEY_E, true)
	await create_timer(0.08).timeout
	_send_key(KEY_E, false)
	player.global_position = level.get_extraction_position() + Vector3(-1.4, 0.0, 0.0)
	await physics_frame
	await create_timer(0.25).timeout
	_check(director.phase == "INTEL_SECURED", "Old E press outside scout range cannot trigger later delivery")
	_send_key(KEY_E, true)
	await create_timer(0.08).timeout
	_send_key(KEY_E, false)
	_check(director.phase == "EXTRACTED" and director.lockdown and level.get_guards().size() > initial_guards, "Early single press resolves seal discovery and order before victory")
	_finish()


func _all_guards_fresh(level) -> bool:
	for guard in level.get_guards():
		if guard.state != "PATROL" or guard.suspicion > 0.0:
			return false
	return true


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS  ", label)
	else:
		failures += 1
		push_error("FAIL  " + label)


func _send_key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)


func _finish() -> void:
	Input.action_release("interact")
	Input.action_release("fire")
	if failures == 0:
		print("MISSION REGRESSION PASS")
		quit(0)
	else:
		print("MISSION REGRESSION FAIL: %d assertions" % failures)
		quit(1)
