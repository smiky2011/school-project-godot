extends CharacterBody3D

const VISION_RANGE := 13.0
const HALF_CONE := deg_to_rad(38.0)
const EYE_HEIGHT := 1.45
const WALK_SPEED := 2.0
const RUN_SPEED := 2.7

var state := "PATROL"
var suspicion := 0.0
var last_seen_position := Vector3.ZERO

var _level: Node3D
var _director: Node
var _player: CharacterBody3D
var _duty_points: Array[Vector3] = []
var _sentry := false
var _home_position := Vector3.ZERO
var _home_rotation := 0.0
var _patrol_index := 0
var _health := 100.0
var _seen_timer := 0.0
var _search_timer := 0.0
var _search_target := Vector3.ZERO
var _path: Array[Vector3] = []
var _path_index := 0
var _path_goal := Vector3.INF
var _repath_timer := 0.0
var _vision_timer := 0.0
var _body_timer := 0.0
var _cone_timer := 0.0
var _shot_timer := 0.35
var _shot_flash_timer := 0.0
var _reported_kill := false
var _seen_corpses: Dictionary = {}
var _visual: Node3D
var _collider: CollisionShape3D
var _flash: MeshInstance3D
var _shot_audio: AudioStreamPlayer3D
var _cone_instance: MeshInstance3D
var _cone_mesh: ArrayMesh
var _cone_material: StandardMaterial3D
var _initialized := false


func setup(town: Node3D, mission_director: Node, mission_player: CharacterBody3D, duty_points: Array[Vector3], sentry: bool, coat_color: Color) -> void:
	_level = town
	_director = mission_director
	_player = mission_player
	_duty_points = duty_points.duplicate()
	_sentry = sentry
	_home_position = global_position
	if _sentry:
		rotation.y = PI # Residence sentry watches the south approach.
	elif _duty_points.size() > 1:
		_face_toward(_duty_points[1])
	_home_rotation = rotation.y
	_build_visuals(coat_color)
	_initialized = true


func is_threatening() -> bool:
	return state == "COMBAT"


func is_searching_near(at: Vector3, radius: float) -> bool:
	return state == "SEARCH" and (global_position.distance_to(at) <= radius or _search_target.distance_to(at) <= radius)


func hear_noise(at: Vector3, loudness: float) -> void:
	if state == "DEAD" or global_position.distance_to(at) > loudness:
		return
	if state != "COMBAT":
		_start_search(at)


func receive_alert(at: Vector3) -> void:
	if state == "DEAD" or state == "COMBAT":
		return
	_start_search(at)


func take_damage(amount: float, source_pos: Vector3 = Vector3.ZERO) -> void:
	if state == "DEAD":
		return
	_health -= amount
	if _health <= 0.0:
		_die()
	else:
		_enter_combat(source_pos)


func can_stealth_kill(player_pos: Vector3) -> bool:
	if state == "DEAD" or state == "COMBAT" or _player == null:
		return false
	if global_position.distance_to(player_pos) > 2.2 or absf(global_position.y - player_pos.y) > 1.3:
		return false
	var toward_player := player_pos - global_position
	toward_player.y = 0.0
	if toward_player.length_squared() < 0.01:
		return false
	var forward := -global_basis.z
	forward.y = 0.0
	if forward.normalized().dot(toward_player.normalized()) > -0.4:
		return false
	var camera: Camera3D = _player.get_camera()
	if camera == null:
		return false
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, global_position + Vector3.UP * 1.15)
	query.exclude = [_player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider") == self


func stealth_kill() -> void:
	if state != "DEAD":
		_die()


func _physics_process(delta: float) -> void:
	if not _initialized or state == "DEAD":
		return
	if not _director.is_active():
		return
	if not is_on_floor():
		velocity.y -= 19.0 * delta
	else:
		velocity.y = -0.2
	_shot_timer = maxf(0.0, _shot_timer - delta)
	_repath_timer = maxf(0.0, _repath_timer - delta)
	_seen_timer += delta
	_vision_timer -= delta
	_body_timer -= delta
	_cone_timer -= delta
	if _vision_timer <= 0.0:
		_vision_timer = 0.08
		_update_vision(0.08)
	if _body_timer <= 0.0:
		_body_timer = 0.65
		_notice_bodies()
	if _cone_timer <= 0.0:
		_cone_timer = 0.16
		_update_cone()
	match state:
		"PATROL":
			_do_patrol(delta)
		"SUSPICIOUS":
			velocity.x = 0.0
			velocity.z = 0.0
			_face_toward(last_seen_position)
		"COMBAT":
			_do_combat(delta)
		"SEARCH":
			_do_search(delta)
	move_and_slide()
	if _shot_flash_timer > 0.0:
		_shot_flash_timer -= delta
		_flash.visible = _shot_flash_timer > 0.0


func _update_vision(sample_delta: float) -> void:
	var visible := _can_see_player()
	if visible:
		last_seen_position = _player.global_position
		_seen_timer = 0.0
		if state != "COMBAT":
			state = "SUSPICIOUS"
			var distance := global_position.distance_to(_player.global_position)
			var gain := 0.55 if _player.is_crouching else 0.95
			if distance < 5.0:
				gain *= 1.55
			suspicion = minf(1.0, suspicion + gain * sample_delta)
			if suspicion >= 1.0:
				_enter_combat(last_seen_position)
	elif state == "SUSPICIOUS":
		suspicion = maxf(0.0, suspicion - sample_delta * 0.32)
		if suspicion <= 0.0:
			_return_to_duty()
	elif state == "COMBAT" and _seen_timer > 1.4:
		_start_search(last_seen_position)
	elif state == "PATROL" or state == "SEARCH":
		suspicion = maxf(0.0, suspicion - sample_delta * 0.2)


func _can_see_player() -> bool:
	if _player == null or _player.dead:
		return false
	var delta_to_player := _player.global_position - global_position
	delta_to_player.y = 0.0
	var distance := delta_to_player.length()
	if distance > VISION_RANGE or distance < 0.01:
		return false
	var forward := -global_basis.z
	forward.y = 0.0
	if forward.normalized().angle_to(delta_to_player.normalized()) > HALF_CONE:
		return false
	var eye := global_position + Vector3.UP * EYE_HEIGHT
	var chest := _player.global_position + Vector3.UP * (0.9 if _player.is_crouching else 1.2)
	var query := PhysicsRayQueryParameters3D.create(eye, chest)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).get("collider") == _player


func _enter_combat(evidence_position: Vector3) -> void:
	if state == "DEAD":
		return
	var was_combat := state == "COMBAT"
	state = "COMBAT"
	suspicion = 1.0
	last_seen_position = evidence_position
	_seen_timer = 0.0
	if not was_combat:
		_director.report_detection(evidence_position, self)
		for other in _level.get_guards():
			if other != self and other.state != "DEAD" and other.global_position.distance_to(global_position) < 13.0:
				other.receive_alert(evidence_position)


func _start_search(evidence_position: Vector3) -> void:
	if state == "DEAD":
		return
	state = "SEARCH"
	_search_target = Vector3(evidence_position.x, global_position.y, evidence_position.z)
	last_seen_position = _search_target
	_search_timer = 10.0
	_repath_timer = 0.0
	_path_goal = Vector3.INF
	suspicion = minf(suspicion, 0.45)


func _do_patrol(delta: float) -> void:
	if _sentry:
		if global_position.distance_to(_home_position) > 0.6:
			_move_to(_home_position, delta, WALK_SPEED)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			rotation.y = lerp_angle(rotation.y, _home_rotation, delta * 2.3)
		return
	if _duty_points.is_empty():
		return
	var destination := _duty_points[_patrol_index]
	if global_position.distance_to(destination) < 0.8:
		_patrol_index = (_patrol_index + 1) % _duty_points.size()
		destination = _duty_points[_patrol_index]
	_move_to(destination, delta, WALK_SPEED)


func _do_combat(delta: float) -> void:
	if _can_see_player():
		_face_toward(_player.global_position, delta)
		var distance := global_position.distance_to(_player.global_position)
		if distance > 8.5:
			_move_to(last_seen_position, delta, RUN_SPEED)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
		if _shot_timer <= 0.0 and distance < 16.0:
			_fire_at_player()
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_face_toward(last_seen_position, delta)


func _do_search(delta: float) -> void:
	_search_timer -= delta
	if _search_timer <= 0.0:
		_return_to_duty()
		return
	if global_position.distance_to(_search_target) > 1.4:
		_move_to(_search_target, delta, WALK_SPEED)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		rotation.y += delta * 0.42


func _return_to_duty() -> void:
	state = "PATROL"
	suspicion = 0.0
	_path_goal = Vector3.INF
	_repath_timer = 0.0


func _move_to(destination: Vector3, delta: float, speed: float) -> void:
	if _repath_timer <= 0.0 or _path_goal.distance_to(destination) > 1.5:
		_path = _level.get_ground_path(global_position, destination)
		_path_index = 0
		_path_goal = destination
		_repath_timer = 1.3
	while _path_index < _path.size() and global_position.distance_to(_path[_path_index]) < 0.65:
		_path_index += 1
	var target := destination
	if _path_index < _path.size():
		target = _path[_path_index]
	var travel := target - global_position
	travel.y = 0.0
	if travel.length() < 0.18:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var horizontal := travel.normalized() * speed
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	_face_toward(target, delta)


func _face_toward(target: Vector3, delta: float = 1.0) -> void:
	var direction := target - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.01:
		var angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, angle, minf(1.0, delta * 6.0))


func _fire_at_player() -> void:
	_shot_timer = 1.15
	var eye := global_position + Vector3.UP * 1.4
	var target := _player.global_position + Vector3.UP * (0.9 if _player.is_crouching else 1.15)
	var query := PhysicsRayQueryParameters3D.create(eye, target)
	query.exclude = [get_rid()]
	if get_world_3d().direct_space_state.intersect_ray(query).get("collider") == _player:
		_player.take_damage(9.0)
	_flash.visible = true
	_shot_flash_timer = 0.13
	_shot_audio.play()


func _notice_bodies() -> void:
	if state == "COMBAT":
		return
	for corpse in _level.get_guards():
		if corpse == self or corpse.state != "DEAD":
			continue
		var id: int = corpse.get_instance_id()
		if _seen_corpses.has(id) or global_position.distance_to(corpse.global_position) > 8.0:
			continue
		var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * EYE_HEIGHT, corpse.global_position + Vector3.UP * 0.35)
		query.exclude = [get_rid()]
		if get_world_3d().direct_space_state.intersect_ray(query).get("collider") == corpse:
			_seen_corpses[id] = true
			_start_search(corpse.global_position)
			return


func _die() -> void:
	if state == "DEAD":
		return
	_notify_witnesses()
	state = "DEAD"
	velocity = Vector3.ZERO
	_cone_instance.visible = false
	_flash.visible = false
	_visual.rotation.z = PI * 0.5
	_visual.position = Vector3(0.0, 0.2, 0.0)
	# Keep the body discoverable as the Guard collider, but lie it down so it
	# does not remain an invisible standing obstacle in a route.
	_collider.set_deferred("rotation", Vector3(0.0, 0.0, PI * 0.5))
	_collider.set_deferred("position", Vector3(0.0, 0.32, 0.0))
	if not _reported_kill:
		_reported_kill = true
		_director.guard_killed()


func _notify_witnesses() -> void:
	# Seeing a corpse later is weaker evidence. A witness needs a clear view
	# of the act and the player before being told the attacker's position.
	for observer in _level.get_guards():
		if observer == self or observer.state == "DEAD" or not observer._can_see_victim(self):
			continue
		if observer._can_see_attacker_around(self):
			observer._enter_combat(_player.global_position)


func _can_see_attacker_around(victim: CharacterBody3D) -> bool:
	# Ignore the victim's own capsule while testing the attacker. A solid
	# wall still blocks the ray, so no witness learns through masonry.
	var toward := _player.global_position - global_position
	toward.y = 0.0
	if toward.length() > VISION_RANGE or toward.length_squared() < 0.01:
		return false
	var forward := -global_basis.z
	forward.y = 0.0
	if forward.normalized().angle_to(toward.normalized()) > HALF_CONE:
		return false
	var eye := global_position + Vector3.UP * EYE_HEIGHT
	var chest := _player.global_position + Vector3.UP * (0.9 if _player.is_crouching else 1.2)
	var query := PhysicsRayQueryParameters3D.create(eye, chest)
	query.exclude = [get_rid(), victim.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).get("collider") == _player


func _can_see_victim(victim: CharacterBody3D) -> bool:
	var toward := victim.global_position - global_position
	toward.y = 0.0
	if toward.length() > VISION_RANGE or toward.length_squared() < 0.01:
		return false
	var forward := -global_basis.z
	forward.y = 0.0
	if forward.normalized().angle_to(toward.normalized()) > HALF_CONE:
		return false
	var eye := global_position + Vector3.UP * EYE_HEIGHT
	var query := PhysicsRayQueryParameters3D.create(eye, victim.global_position + Vector3.UP * 1.0)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).get("collider") == victim


func _build_visuals(coat_color: Color) -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.30
	capsule.height = 1.75
	_collider = CollisionShape3D.new()
	_collider.shape = capsule
	_collider.position.y = 0.9
	add_child(_collider)
	_visual = Node3D.new()
	_visual.name = "GuardVisual"
	add_child(_visual)
	_mesh_box("Coat", Vector3(0, 0.95, 0), Vector3(0.66, 1.25, 0.42), coat_color)
	_mesh_sphere("Head", Vector3(0, 1.72, 0), 0.27, Color(0.72, 0.61, 0.51))
	_mesh_box("Helmet", Vector3(0, 1.94, 0), Vector3(0.58, 0.18, 0.58), Color(0.27, 0.29, 0.25))
	_mesh_box("Arm", Vector3(0.45, 1.13, -0.05), Vector3(0.19, 0.8, 0.25), coat_color)
	_mesh_box("Weapon", Vector3(0.28, 1.03, -0.48), Vector3(0.16, 0.16, 0.87), Color(0.18, 0.18, 0.17))
	_flash = MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.19
	flash_mesh.height = 0.38
	_flash.mesh = flash_mesh
	var flash_material := StandardMaterial3D.new()
	flash_material.albedo_color = Color(1.0, 0.48, 0.14)
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.material_override = flash_material
	_visual.add_child(_flash)
	_flash.position = Vector3(0.28, 1.03, -0.93)
	_flash.visible = false
	_shot_audio = AudioStreamPlayer3D.new()
	_shot_audio.name = "GunshotCue"
	_shot_audio.position = Vector3(0.28, 1.03, -0.93)
	_shot_audio.max_distance = 42.0
	_shot_audio.volume_db = -6.0
	_shot_audio.stream = _build_shot_sound()
	add_child(_shot_audio)
	_cone_instance = MeshInstance3D.new()
	_cone_instance.name = "VisionCone"
	add_child(_cone_instance)
	_cone_mesh = ArrayMesh.new()
	_cone_instance.mesh = _cone_mesh
	_cone_material = StandardMaterial3D.new()
	_cone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cone_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cone_material.albedo_color = Color(1.0, 0.92, 0.37, 0.20)
	_cone_instance.material_override = _cone_material


func _build_shot_sound() -> AudioStreamWAV:
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var samples := PackedByteArray()
	var seed := 1151
	for i in range(3308):
		seed = (seed * 1103515245 + 12345) & 0x7fffffff
		var t := float(i) / 22050.0
		var noise := float(seed % 65536) / 32768.0 - 1.0
		var envelope := pow(maxf(0.0, 1.0 - t / 0.15), 3.0)
		var pulse := sin(TAU * 83.0 * t) * 0.22
		var value := int(clampf((noise * 0.75 + pulse) * envelope, -1.0, 1.0) * 25000.0)
		samples.append(value & 255)
		samples.append((value >> 8) & 255)
	sound.data = samples
	return sound


func _mesh_box(label: String, center: Vector3, size: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	_visual.add_child(visual)
	visual.position = center


func _mesh_sphere(label: String, center: Vector3, radius: float, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	_visual.add_child(visual)
	visual.position = center


func _update_cone() -> void:
	if state == "DEAD":
		return
	var tint := Color(1.0, 0.92, 0.37, 0.20)
	if state == "COMBAT":
		tint = Color(1.0, 0.18, 0.10, 0.22)
	elif state == "SUSPICIOUS" or state == "SEARCH":
		tint = Color(1.0, 0.52, 0.18, 0.23)
	_cone_material.albedo_color = tint
	_cone_mesh.clear_surfaces()
	var vertices := PackedVector3Array()
	var previous := Vector3.ZERO
	for index in range(25):
		var angle := lerpf(-HALF_CONE, HALF_CONE, float(index) / 24.0)
		var local_dir := Vector3(sin(angle), 0.0, -cos(angle))
		var world_dir := global_basis * local_dir
		var eye := global_position + Vector3.UP * EYE_HEIGHT
		var query := PhysicsRayQueryParameters3D.create(eye, eye + world_dir * VISION_RANGE)
		query.exclude = [get_rid(), _player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		var length := VISION_RANGE
		if not hit.is_empty():
			length = maxf(0.0, eye.distance_to(hit.position) - 0.1)
		var tip := local_dir * length
		tip.y = 0.06
		if index > 0:
			vertices.append(Vector3(0, 0.06, 0))
			vertices.append(previous)
			vertices.append(tip)
		previous = tip
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	_cone_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
