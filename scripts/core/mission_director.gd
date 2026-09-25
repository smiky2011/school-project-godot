extends Node

signal mission_finished(success: bool)
signal story_cue(kind: String)

const CONTACT_RANGE := 3.0
const EXTRACTION_RANGE := 3.0
const CONTACT_SECONDS := 3.0
const CONTACT_SEARCH_RADIUS := 24.0
const LOCAL_ALERT_RADIUS := 22.0
const EXPOSURE_DELAY := 7.0

var phase := "INFILTRATE"
var lockdown := false
var handoff_progress := 0.0
var interaction_text := ""
var subtitle_text := ""
var mission_time := 0.0
var kills := 0
var last_noise := 0.0
var running := false
var player
var level

var _subtitle_timer := 0.0
var _exposure_timer := 0.0
var _exposure_stage := 0
var _stage_timer := 0.0
var _pending_interact_press := false


func setup(mission_player, mission_level) -> void:
	player = mission_player
	level = mission_level
	phase = "INFILTRATE"
	lockdown = false
	handoff_progress = 0.0
	_exposure_stage = 0
	_exposure_timer = 0.0
	_pending_interact_press = false
	running = false


func start_mission() -> void:
	if phase != "INFILTRATE":
		return
	running = true
	say("Find the local contact upstairs. The extraction scout waits beyond town.", 7.0)


func is_active() -> bool:
	return running and (phase == "INFILTRATE" or phase == "INTEL_SECURED")


func has_active_threat() -> bool:
	if level == null:
		return false
	for guard in level.get_guards():
		if is_instance_valid(guard) and guard.is_threatening():
			return true
	return false


func report_noise(pos: Vector3, loudness: float) -> void:
	if not is_active():
		return
	last_noise = 1.0
	for guard in level.get_guards():
		if is_instance_valid(guard) and guard.global_position.distance_to(pos) <= loudness:
			guard.hear_noise(pos, loudness)


func report_detection(pos: Vector3, source_guard) -> void:
	if not is_active():
		return
	for guard in level.get_guards():
		if is_instance_valid(guard) and guard != source_guard and guard.global_position.distance_to(pos) <= LOCAL_ALERT_RADIUS:
			guard.receive_alert(pos)


func guard_killed() -> void:
	kills += 1


func player_died() -> void:
	if not is_active():
		return
	phase = "FAILED"
	running = false
	handoff_progress = 0.0
	interaction_text = ""
	mission_finished.emit(false)


func get_objective_position() -> Vector3:
	if level == null:
		return Vector3.ZERO
	if phase == "INFILTRATE":
		return level.get_contact_position()
	return level.get_extraction_position()


func get_objective_title() -> String:
	if phase == "INFILTRATE":
		return "MEET THE CONTACT"
	return "REACH THE EXTRACTION SCOUT"


func get_local_awareness() -> Dictionary:
	var result := {"state": "CLEAR", "suspicion": 0.0}
	if level == null or player == null:
		return result
	for guard in level.get_guards():
		if not is_instance_valid(guard) or guard.state == "DEAD":
			continue
		if guard.global_position.distance_to(player.global_position) > 32.0:
			continue
		result.suspicion = maxf(float(result.suspicion), guard.suspicion)
		if guard.state == "COMBAT":
			result.state = "COMBAT"
		elif guard.state == "SEARCH" and result.state != "COMBAT":
			result.state = "SEARCHING"
		elif guard.state == "SUSPICIOUS" and result.state == "CLEAR":
			result.state = "WATCHFUL"
	return result


func try_stealth_kill() -> void:
	if not is_active():
		return
	var candidate = _get_stealth_target()
	if candidate != null:
		candidate.stealth_kill()
		say("Guard neutralized quietly.", 2.2)


func can_stealth_kill_now() -> bool:
	return is_active() and _get_stealth_target() != null


func _get_stealth_target():
	var candidate = null
	var best_distance := 2.25
	for guard in level.get_guards():
		if not is_instance_valid(guard) or guard.state == "DEAD":
			continue
		var distance: float = player.global_position.distance_to(guard.global_position)
		if distance < best_distance and absf(player.global_position.y - guard.global_position.y) < 1.5 and guard.can_stealth_kill(player.global_position) and _clear_line_to_guard(guard):
			candidate = guard
			best_distance = distance
	return candidate


func say(message: String, seconds: float = 4.0) -> void:
	subtitle_text = message
	_subtitle_timer = seconds


func _unhandled_input(event: InputEvent) -> void:
	if is_active() and event.is_action_pressed("interact") and not event.is_echo():
		_pending_interact_press = true


func _process(delta: float) -> void:
	if not is_active():
		_pending_interact_press = false
		return
	mission_time += delta
	last_noise = maxf(0.0, last_noise - delta * 0.7)
	if _subtitle_timer > 0.0:
		_subtitle_timer -= delta
		if _subtitle_timer <= 0.0:
			subtitle_text = ""
	if phase == "INFILTRATE":
		_update_contact(delta)
	elif phase == "INTEL_SECURED":
		_update_exposure(delta)
		_update_extraction()
	_pending_interact_press = false


func _update_contact(delta: float) -> void:
	var contact_pos: Vector3 = level.get_contact_position()
	if player.global_position.distance_to(contact_pos) > CONTACT_RANGE or absf(player.global_position.y - contact_pos.y) > 1.75:
		interaction_text = ""
		handoff_progress = 0.0
		return
	if not _clear_line_to_point(contact_pos):
		interaction_text = "Move into the room to speak with the contact"
		handoff_progress = 0.0
		return
	if not _contact_safe():
		interaction_text = "Contact is working. Lose pursuit and wait for nearby searches to end"
		handoff_progress = 0.0
		return
	interaction_text = "Hold E to receive copied plans"
	if Input.is_action_pressed("interact"):
		handoff_progress += delta / CONTACT_SECONDS
		if handoff_progress >= 1.0:
			_complete_handoff()
	else:
		handoff_progress = 0.0


func _contact_safe() -> bool:
	var contact_pos: Vector3 = level.get_contact_position()
	for guard in level.get_guards():
		if not is_instance_valid(guard) or guard.state == "DEAD":
			continue
		if guard.state == "COMBAT":
			return false
		if guard.is_searching_near(contact_pos, CONTACT_SEARCH_RADIUS):
			return false
		if guard.global_position.distance_to(contact_pos) <= CONTACT_SEARCH_RADIUS and guard.suspicion > 0.35:
			return false
	return true


func _complete_handoff() -> void:
	phase = "INTEL_SECURED"
	handoff_progress = 0.0
	interaction_text = ""
	_exposure_timer = 0.0
	say("Contact: These are copies. The originals remain here. Get them to the scout.", 6.0)


func _update_exposure(delta: float) -> void:
	if _exposure_stage == 0:
		_exposure_timer += delta
		if _exposure_timer >= EXPOSURE_DELAY:
			_announce_discovery()
	elif _exposure_stage == 1:
		_stage_timer -= delta
		if _stage_timer <= 0.0:
			_issue_order()


func _announce_discovery() -> void:
	if _exposure_stage != 0:
		return
	_exposure_stage = 1
	_stage_timer = 1.7
	say("Returning personnel: The stair security seal has been cut!", 2.1)
	story_cue.emit("arrival")


func _issue_order() -> void:
	if _exposure_stage != 1:
		return
	_exposure_stage = 2
	lockdown = true
	level.spawn_reinforcements()
	say("Radio order: Seal the town. All posts, report and search the approaches.", 5.0)
	story_cue.emit("radio")


func _update_extraction() -> void:
	var extraction_pos: Vector3 = level.get_extraction_position()
	if player.global_position.distance_to(extraction_pos) > EXTRACTION_RANGE or absf(player.global_position.y - extraction_pos.y) > 1.75:
		interaction_text = ""
		return
	if not _clear_line_to_point(extraction_pos):
		interaction_text = "Enter the shelter to reach the scout"
		return
	interaction_text = "Press E to deliver the packet"
	if _pending_interact_press or Input.is_action_just_pressed("interact"):
		if _exposure_stage == 0:
			_announce_discovery()
		if _exposure_stage == 1:
			_issue_order()
		_finish_mission()


func _finish_mission() -> void:
	if phase != "INTEL_SECURED":
		return
	phase = "EXTRACTED"
	running = false
	interaction_text = ""
	mission_finished.emit(true)


func _clear_line_to_point(point: Vector3) -> bool:
	var from: Vector3 = player.get_camera().global_position
	var to := point + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _clear_line_to_guard(guard) -> bool:
	var from: Vector3 = player.get_camera().global_position
	var to: Vector3 = guard.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit["collider"] == guard
