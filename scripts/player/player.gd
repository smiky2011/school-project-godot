extends CharacterBody3D

const WEAPON := preload("res://scripts/player/weapon_profile.gd")
const SYNTH := preload("res://scripts/audio/sound_synth.gd")
const COMBAT_FX := preload("res://scripts/fx/combat_fx.gd")
const WEAPON_PRESENTATION_SCRIPT: Script = preload("res://scripts/player/weapon_presentation.gd")

const WALK_SPEED := 3.2
const SPRINT_SPEED := 5.2
const CROUCH_SPEED := 1.45
const GROUND_ACCELERATION := 22.0
const GROUND_BRAKING := 26.0
const GROUND_REVERSAL := 38.0
const SHOT_TAIL_VOICES := 16
const JUMP_VELOCITY := 4.6
const MOUSE_SENSITIVITY := 0.0022
const KEYBOARD_LOOK_SPEED := 1.7
# Kept for existing callers; the weapon profile owns the values.
const MAGAZINE_SIZE := WEAPON.MAGAZINE_SIZE
const RELOAD_SECONDS := WEAPON.TACTICAL_RELOAD
const FIRE_INTERVAL := WEAPON.FIRE_INTERVAL
const BULLET_DAMAGE := WEAPON.BODY_DAMAGE

var health := 100.0
var dead := false
var is_crouching := false
var is_sprinting := false
var ammo := MAGAZINE_SIZE
var is_reloading := false
var reload_is_empty := false
var controls_enabled := false
var shot_flash := 0.0
var hit_marker := 0.0
var hit_kind := "hit" # hit, head, kill
var damage_flash := 0.0
var aim_amount := 0.0
var suppression := 0.0
var shots_fired := 0
var hits_landed := 0
var headshots := 0
# Recent incoming damage directions for the HUD: [{"from": Vector3, "time": float}].
var damage_sources: Array[Dictionary] = []
var director

var _camera: Camera3D
var _head: Node3D
var _weapon: Node3D
var _collider: CollisionShape3D
var _capsule: CapsuleShape3D
var _shot_players: Array[AudioStreamPlayer] = []
var _shot_index := 0
var _tail_players: Array[AudioStreamPlayer] = []
var _tail_index := 0
var _foley_player: AudioStreamPlayer
var _step_player: AudioStreamPlayer
var _near_miss_player: AudioStreamPlayer3D
var _pitch := 0.0
var _fire_timer := 0.0
var _reload_timer := 0.0
var _reload_total := WEAPON.TACTICAL_RELOAD
var _reload_cues := {}
var _damage_timer := 0.0
var _crouch_toggled := false
var _rng := RandomNumberGenerator.new()
var _recoil_pitch := 0.0
var _recoil_yaw := 0.0
var _punch := Vector3.ZERO
var _punch_velocity := Vector3.ZERO
var _shot_index_in_burst := 0
var _since_shot := 10.0
var _bloom := 0.0
var _sprint_block := 0.0
var _space := "open"
var _space_timer := 0.0
var _step_distance := 0.0
var _dry_fire_latch := false


func _ready() -> void:
	name = "Player"
	collision_layer = 1
	collision_mask = 1
	_rng.randomize()
	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.32
	_capsule.height = 1.75
	_collider = CollisionShape3D.new()
	_collider.shape = _capsule
	_collider.position.y = 0.9
	add_child(_collider)
	_head = Node3D.new()
	_head.position.y = 1.58
	add_child(_head)
	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = WEAPON.HIP_FOV
	_camera.near = 0.03
	_head.add_child(_camera)
	_weapon = WEAPON_PRESENTATION_SCRIPT.new() as Node3D
	_camera.add_child(_weapon)
	_build_audio()


func setup(mission_director) -> void:
	director = mission_director


func get_camera() -> Camera3D:
	return _camera


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled and not dead
	if not controls_enabled:
		velocity.x = 0.0
		velocity.z = 0.0
		is_sprinting = false


func take_damage(amount: float) -> void:
	if dead or not controls_enabled:
		return
	health = maxf(0.0, health - maxf(amount, 0.0))
	damage_flash = 0.42
	_damage_timer = 0.0
	# A hit jolts the view; the direction indicator is fed by notify_incoming_fire.
	_punch_velocity += Vector3(_rng.randf_range(0.6, 1.0), _rng.randf_range(-0.8, 0.8), _rng.randf_range(-0.6, 0.6)) * 0.9
	if health <= 0.0:
		dead = true
		controls_enabled = false
		velocity = Vector3.ZERO
		if director != null:
			director.player_died()


func notify_incoming_fire(from: Vector3, hit: bool, passing_point: Vector3) -> void:
	# Guards report every shot aimed at the player, hit or miss.
	if dead:
		return
	suppression = minf(1.0, suppression + (0.22 if hit else 0.34))
	damage_sources.append({"from": from, "time": 1.4 if hit else 0.8, "hit": hit})
	if damage_sources.size() > 6:
		damage_sources.pop_front()
	if not hit:
		_near_miss_player.global_position = passing_point
		_near_miss_player.pitch_scale = _rng.randf_range(0.9, 1.1)
		_near_miss_player.play()
		_punch_velocity += Vector3(_rng.randf_range(-0.25, 0.25), _rng.randf_range(-0.3, 0.3), 0.0)


func get_spread_degrees() -> float:
	var moving := Vector2(velocity.x, velocity.z).length() > 0.4
	var base := lerpf(WEAPON.SPREAD_HIP, WEAPON.SPREAD_ADS, aim_amount)
	if moving:
		base += lerpf(WEAPON.SPREAD_MOVE_HIP, WEAPON.SPREAD_MOVE_ADS, aim_amount)
	if not is_on_floor():
		base += WEAPON.SPREAD_AIR
	var spread := base + _bloom + suppression * 0.4
	if is_crouching:
		spread *= WEAPON.CROUCH_SPREAD_SCALE
	return spread


func get_reload_progress() -> float:
	if not is_reloading:
		return 0.0
	return clampf(1.0 - _reload_timer / _reload_total, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity := MOUSE_SENSITIVITY * lerpf(1.0, 0.82, aim_amount)
		rotation.y -= event.relative.x * sensitivity
		_pitch = clampf(_pitch - event.relative.y * sensitivity, -1.45, 1.45)
		_weapon.call("add_look_sway", event.relative)
	if event.is_action_pressed("toggle_crouch") and not event.is_echo():
		_crouch_toggled = not _crouch_toggled
	if event.is_action_pressed("reload") and not event.is_echo():
		_start_reload()


func _physics_process(delta: float) -> void:
	if not controls_enabled:
		return
	_fire_timer = maxf(0.0, _fire_timer - delta)
	shot_flash = maxf(0.0, shot_flash - delta)
	hit_marker = maxf(0.0, hit_marker - delta)
	damage_flash = maxf(0.0, damage_flash - delta)
	suppression = maxf(0.0, suppression - delta * 0.55)
	_since_shot += delta
	_space_timer -= delta
	for i in range(damage_sources.size() - 1, -1, -1):
		damage_sources[i].time -= delta
		if damage_sources[i].time <= 0.0:
			damage_sources.remove_at(i)
	_update_reload(delta)
	_damage_timer += delta
	if _damage_timer >= 7.0 and health < 100.0 and director != null and not director.has_active_threat():
		health = minf(100.0, health + 10.0 * delta)
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	rotation.y -= look.x * KEYBOARD_LOOK_SPEED * delta
	_pitch = clampf(_pitch - look.y * KEYBOARD_LOOK_SPEED * delta, -1.45, 1.45)
	var wants_crouch := _crouch_toggled or Input.is_action_pressed("hold_crouch")
	if wants_crouch != is_crouching:
		if wants_crouch or _can_stand():
			is_crouching = wants_crouch
			_capsule.height = 1.1 if is_crouching else 1.75
			_collider.position.y = 0.58 if is_crouching else 0.9
	_head.position.y = lerpf(_head.position.y, 1.09 if is_crouching else 1.58, minf(1.0, delta * 12.0))
	var direction_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wants_aim := Input.is_action_pressed("aim")
	var wants_fire := Input.is_action_pressed("fire")
	# Sprint only forward, standing and not aiming; holding fire drops sprint
	# first, then the sprint-to-fire delay must pass before the first round.
	var was_sprinting := is_sprinting
	is_sprinting = Input.is_action_pressed("sprint") and direction_2d.y < -0.3 and not is_crouching \
		and not wants_aim and not wants_fire and not is_reloading and is_on_floor()
	if was_sprinting and not is_sprinting:
		_sprint_block = WEAPON.SPRINT_TO_FIRE
	_sprint_block = maxf(0.0, _sprint_block - delta)
	var aim_target := 1.0 if wants_aim and not is_reloading and not is_sprinting else 0.0
	aim_amount = move_toward(aim_amount, aim_target, delta / WEAPON.ADS_TIME)
	var direction := (global_transform.basis * Vector3(direction_2d.x, 0.0, direction_2d.y)).normalized()
	var speed := CROUCH_SPEED if is_crouching else (SPRINT_SPEED if is_sprinting else WALK_SPEED)
	speed *= lerpf(1.0, WEAPON.ADS_MOVE_SCALE, aim_amount)
	var horizontal := Vector2(velocity.x, velocity.z)
	var target := Vector2(direction.x, direction.z) * speed
	var acceleration := GROUND_ACCELERATION
	if target.is_zero_approx():
		acceleration = GROUND_BRAKING
	elif horizontal.dot(target) < 0.0:
		acceleration = GROUND_REVERSAL
	horizontal = horizontal.move_toward(target, acceleration * delta)
	# Changing to crouch or ADS must apply its speed cap immediately.
	horizontal = horizontal.limit_length(speed)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	elif Input.is_action_just_pressed("jump") and not is_crouching:
		velocity.y = JUMP_VELOCITY
	else:
		velocity.y = minf(velocity.y, 0.0)
	var before_move := global_position
	move_and_slide()
	var ground_travel := Vector2(global_position.x - before_move.x, global_position.z - before_move.z).length() if is_on_floor() else 0.0
	_update_footsteps(ground_travel)
	if wants_fire and _fire_timer <= 0.0 and not is_sprinting and _sprint_block <= 0.0:
		_fire()
	if not wants_fire:
		_dry_fire_latch = false
	if Input.is_action_just_pressed("stealth_kill") and director != null:
		director.try_stealth_kill()
	_update_recoil(delta)
	_camera.fov = lerpf(WEAPON.HIP_FOV, WEAPON.ADS_FOV, _ease(aim_amount))
	_weapon.call("update_pose", delta, aim_amount, ground_travel, is_sprinting, is_reloading, get_reload_progress(), reload_is_empty, suppression, is_crouching)


func _update_reload(delta: float) -> void:
	if not is_reloading:
		return
	_reload_timer -= delta
	var progress := get_reload_progress()
	for cue in _reload_cues.keys():
		if progress >= float(cue) and not _reload_cues[cue][1]:
			_reload_cues[cue][1] = true
			_play_foley(_reload_cues[cue][0])
	if _reload_timer <= 0.0:
		is_reloading = false
		ammo = MAGAZINE_SIZE


func _start_reload() -> void:
	if is_reloading or ammo == MAGAZINE_SIZE or dead:
		return
	is_reloading = true
	reload_is_empty = ammo == 0
	_reload_total = WEAPON.EMPTY_RELOAD if reload_is_empty else WEAPON.TACTICAL_RELOAD
	_reload_timer = _reload_total
	# Progress points match the viewmodel's magazine and bolt motion.
	_reload_cues = {0.22: ["mag_out", false], 0.62: ["mag_in", false]}
	if reload_is_empty:
		_reload_cues[0.83] = ["bolt_rack", false]


func _fire() -> void:
	_fire_timer = WEAPON.FIRE_INTERVAL
	if is_reloading:
		return
	if ammo <= 0:
		if not _dry_fire_latch:
			_dry_fire_latch = true
			_play_foley("dry_click")
		return
	ammo -= 1
	shots_fired += 1
	shot_flash = 0.085
	if _since_shot > WEAPON.RECOIL_RESET_TIME:
		_shot_index_in_burst = 0
		_bloom = 0.0
	var spread := get_spread_degrees()
	_since_shot = 0.0
	_play_shot()
	if director != null:
		director.report_noise(global_position, WEAPON.NOISE_RADIUS)
	var from := _camera.global_position
	var forward := -_camera.global_transform.basis.z
	var shot_dir := _spread_direction(forward, deg_to_rad(spread))
	var to := from + shot_dir * WEAPON.RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var muzzle: Vector3 = _weapon.call("get_muzzle_position")
	var fx := COMBAT_FX.find(get_tree())
	var end_point := to
	if not hit.is_empty():
		end_point = hit.position
		_resolve_hit(hit, from, shot_dir, fx)
	if fx != null:
		fx.tracer(muzzle, end_point, Color(1.0, 0.85, 0.6, 0.28), 420.0, 0.012, 2.2)
		var eject: Transform3D = _weapon.call("get_ejection_transform")
		var right := _camera.global_transform.basis.x
		var up := _camera.global_transform.basis.y
		fx.eject_shell(eject, right * _rng.randf_range(1.6, 2.4) + up * _rng.randf_range(1.2, 1.9) - forward * 0.3 + velocity)
	_apply_recoil()
	_weapon.call("fired")


func _resolve_hit(hit: Dictionary, from: Vector3, shot_dir: Vector3, fx: Node) -> void:
	var body: Object = hit["collider"]
	var distance := from.distance_to(hit.position)
	if body.has_method("take_damage"):
		var headshot := false
		if body.has_method("get_head_center"):
			var head: Vector3 = body.call("get_head_center")
			var along := (head - from).dot(shot_dir)
			var closest := from + shot_dir * along
			headshot = along > 0.0 and closest.distance_to(head) <= WEAPON.HEAD_RADIUS
		var damage := WEAPON.damage_at(distance, headshot)
		if body.has_method("get_head_center"):
			body.call("take_damage", damage, global_position, {"position": hit.position, "direction": shot_dir, "headshot": headshot})
		else:
			body.call("take_damage", damage, global_position)
		hits_landed += 1
		if headshot:
			headshots += 1
		hit_marker = 0.22
		var killed: bool = "state" in body and body.state == "DEAD"
		hit_kind = "kill" if killed else ("head" if headshot else "hit")
		if fx != null:
			fx.body_hit(hit.position, hit.normal)
	elif fx != null:
		fx.impact(hit.position, hit.normal, _surface_of(body), true, body, shot_dir)


func _surface_of(body: Object) -> String:
	if body is Node and (body as Node).has_meta("surface"):
		return str((body as Node).get_meta("surface"))
	if body is Node:
		var label := String((body as Node).name).to_lower()
		for token in ["wood", "timber", "crate", "desk", "stair", "floor", "door", "chair", "support", "canopy", "threshold"]:
			if label.contains(token):
				return "wood"
		if label.contains("barrel") or label.contains("jerrycan"):
			return "metal"
		if label.contains("ground"):
			return "dirt"
	return "stone"


func _spread_direction(forward: Vector3, half_angle: float) -> Vector3:
	if half_angle <= 0.0:
		return forward
	# Uniform over the cone's disc: sqrt keeps shots from bunching at the rim.
	var radius := tan(half_angle) * sqrt(_rng.randf())
	var theta := _rng.randf() * TAU
	var basis := _camera.global_transform.basis
	return (forward + basis.x * cos(theta) * radius + basis.y * sin(theta) * radius).normalized()


func _apply_recoil() -> void:
	var scale := lerpf(1.0, WEAPON.RECOIL_ADS_SCALE, aim_amount)
	if is_crouching:
		scale *= WEAPON.RECOIL_CROUCH_SCALE
	var vertical := WEAPON.vertical_kick(_shot_index_in_burst) * scale
	var horizontal := WEAPON.horizontal_kick(_shot_index_in_burst, _rng) * scale
	_recoil_pitch += deg_to_rad(vertical)
	_recoil_yaw -= deg_to_rad(horizontal)
	_shot_index_in_burst += 1
	var bloom_max := lerpf(WEAPON.BLOOM_MAX_HIP, WEAPON.BLOOM_MAX_ADS, aim_amount)
	_bloom = minf(bloom_max, _bloom + WEAPON.BLOOM_PER_SHOT)
	# Visual-only camera punch: fast, springs back, never moves the aim point.
	_punch_velocity += Vector3(_rng.randf_range(0.9, 1.3), _rng.randf_range(-0.35, 0.35), _rng.randf_range(-0.8, 0.8)) * lerpf(1.0, 0.55, aim_amount)


func _update_recoil(delta: float) -> void:
	# Recoil offsets recover toward the player's own aim once firing pauses;
	# while spraying they recover slowly, so the authored climb is still felt.
	var rate := WEAPON.RECOIL_RECOVERY if _since_shot > 0.12 else 1.8
	var k := 1.0 - exp(-rate * delta)
	_recoil_pitch -= _recoil_pitch * k
	_recoil_yaw -= _recoil_yaw * k
	if _since_shot > 0.12:
		_bloom = maxf(0.0, _bloom - WEAPON.BLOOM_RECOVERY * delta)
	# Critically damped spring for the camera punch (degrees).
	var stiffness := 260.0
	var damping := 2.0 * sqrt(stiffness)
	_punch_velocity += (-_punch * stiffness - _punch_velocity * damping) * delta
	_punch += _punch_velocity * delta
	_head.rotation.x = clampf(_pitch + _recoil_pitch, -1.5, 1.5)
	_head.rotation.y = _recoil_yaw
	_camera.rotation = Vector3(deg_to_rad(_punch.x), deg_to_rad(_punch.y), deg_to_rad(_punch.z))


func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _can_stand() -> bool:
	# Check only the space the taller stance would newly occupy. Testing the
	# entire standing capsule can detect the floor beneath a settled crouched
	# player and permanently prevent standing.
	var headroom := CylinderShape3D.new()
	headroom.radius = 0.32
	headroom.height = 0.68
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = headroom
	query.transform = Transform3D(global_transform.basis, global_position + Vector3.UP * 1.43)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _build_audio() -> void:
	for i in range(4):
		var p := AudioStreamPlayer.new()
		p.name = "StenReport%d" % i
		p.volume_db = -7.0
		add_child(p)
		_shot_players.append(p)
	# Automatic fire is faster than the longest (open-air) reflection. Keep
	# enough fixed voices for each shot's tail to finish without retriggering it.
	for i in range(SHOT_TAIL_VOICES):
		var tail := AudioStreamPlayer.new()
		tail.name = "StenTail%d" % i
		tail.volume_db = -11.0
		add_child(tail)
		_tail_players.append(tail)
	_foley_player = AudioStreamPlayer.new()
	_foley_player.name = "WeaponFoley"
	_foley_player.volume_db = -12.0
	add_child(_foley_player)
	_step_player = AudioStreamPlayer.new()
	_step_player.name = "Footsteps"
	_step_player.volume_db = -22.0
	add_child(_step_player)
	_near_miss_player = AudioStreamPlayer3D.new()
	_near_miss_player.name = "NearMiss"
	_near_miss_player.stream = SYNTH.get_stream("near_miss")
	_near_miss_player.volume_db = -4.0
	_near_miss_player.unit_size = 3.0
	add_child(_near_miss_player)
	# Build the shot variants now so the first trigger pull has no hitch.
	for key in ["sten_a", "sten_b", "sten_c", "sten_d", "tail_open", "tail_street", "tail_interior", "mag_out", "mag_in", "bolt_rack", "dry_click"]:
		SYNTH.get_stream(key)


func _play_shot() -> void:
	var variants := ["sten_a", "sten_b", "sten_c", "sten_d"]
	var p := _shot_players[_shot_index]
	_shot_index = (_shot_index + 1) % _shot_players.size()
	p.stream = SYNTH.get_stream(variants[_rng.randi() % variants.size()])
	p.pitch_scale = _rng.randf_range(0.96, 1.04)
	p.play()
	if _space_timer <= 0.0:
		_space_timer = 0.3
		_space = _probe_space()
	var tail := _tail_players[_tail_index]
	_tail_index = (_tail_index + 1) % _tail_players.size()
	tail.stream = SYNTH.get_stream("tail_" + _space)
	tail.volume_db = {"open": -10.0, "street": -9.0, "interior": -12.0}[_space]
	tail.pitch_scale = _rng.randf_range(0.97, 1.03)
	tail.play()


func _probe_space() -> String:
	# A few rays classify the shooter's surroundings, like a cheap version of
	# a reflection system: roofed and enclosed, walled street, or open ground.
	var space_state := get_world_3d().direct_space_state
	var origin := _camera.global_position
	var near_hits := 0
	var total := 0.0
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * 25.0)
		query.exclude = [get_rid()]
		var hit := space_state.intersect_ray(query)
		var d := 25.0 if hit.is_empty() else origin.distance_to(hit.position)
		total += d
		if d < 12.0:
			near_hits += 1
	var up := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.UP * 6.0)
	up.exclude = [get_rid()]
	var roofed := not space_state.intersect_ray(up).is_empty()
	if roofed and total / 8.0 < 9.0:
		return "interior"
	if near_hits >= 3:
		return "street"
	return "open"


func _play_foley(key: String) -> void:
	_foley_player.stream = SYNTH.get_stream(key)
	_foley_player.pitch_scale = _rng.randf_range(0.97, 1.03)
	_foley_player.play()


func _update_footsteps(ground_travel: float) -> void:
	if ground_travel <= 0.0:
		return
	_step_distance += ground_travel
	var stride := 1.55 if is_sprinting else (0.95 if is_crouching else 1.25)
	if _step_distance < stride:
		return
	_step_distance = fmod(_step_distance, stride)
	var surface := "step_mud"
	var level := get_parent().get_node_or_null("TownLevel")
	if level != null and level.has_method("get_ground_surface"):
		surface = "step_" + str(level.call("get_ground_surface", global_position))
	_step_player.stream = SYNTH.get_stream(surface)
	_step_player.volume_db = -27.0 if is_crouching else (-17.0 if is_sprinting else -21.0)
	_step_player.pitch_scale = _rng.randf_range(0.9, 1.1)
	_step_player.play()
