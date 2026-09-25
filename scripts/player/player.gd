extends CharacterBody3D

const WALK_SPEED := 3.2
const SPRINT_SPEED := 5.2
const CROUCH_SPEED := 1.45
const JUMP_VELOCITY := 4.6
const MOUSE_SENSITIVITY := 0.0022
const KEYBOARD_LOOK_SPEED := 1.7
const MAGAZINE_SIZE := 30
const RELOAD_SECONDS := 1.9
const FIRE_INTERVAL := 0.105
const BULLET_DAMAGE := 34.0
const WEAPON_PRESENTATION_SCRIPT: Script = preload("res://scripts/player/weapon_presentation.gd")

var health := 100.0
var dead := false
var is_crouching := false
var ammo := MAGAZINE_SIZE
var is_reloading := false
var controls_enabled := false
var shot_flash := 0.0
var hit_marker := 0.0
var damage_flash := 0.0
var director

var _camera: Camera3D
var _head: Node3D
var _weapon: Node3D
var _collider: CollisionShape3D
var _capsule: CapsuleShape3D
var _shot_audio: AudioStreamPlayer
var _pitch := 0.0
var _fire_timer := 0.0
var _reload_timer := 0.0
var _damage_timer := 0.0
var _crouch_toggled := false


func _ready() -> void:
	name = "Player"
	collision_layer = 1
	collision_mask = 1
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
	_camera.fov = 76.0
	_camera.near = 0.05
	_head.add_child(_camera)
	_weapon = WEAPON_PRESENTATION_SCRIPT.new() as Node3D
	_camera.add_child(_weapon)
	_build_shot_sound()


func setup(mission_director) -> void:
	director = mission_director


func get_camera() -> Camera3D:
	return _camera


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled and not dead
	if not controls_enabled:
		velocity.x = 0.0
		velocity.z = 0.0


func take_damage(amount: float) -> void:
	if dead or not controls_enabled:
		return
	health = maxf(0.0, health - maxf(amount, 0.0))
	damage_flash = 0.42
	_damage_timer = 0.0
	if health <= 0.0:
		dead = true
		controls_enabled = false
		velocity = Vector3.ZERO
		if director != null:
			director.player_died()


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENSITIVITY, -1.45, 1.45)
		_head.rotation.x = _pitch
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
	if is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			is_reloading = false
			ammo = MAGAZINE_SIZE
	_damage_timer += delta
	if _damage_timer >= 7.0 and health < 100.0 and director != null and not director.has_active_threat():
		health = minf(100.0, health + 10.0 * delta)
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	rotation.y -= look.x * KEYBOARD_LOOK_SPEED * delta
	_pitch = clampf(_pitch - look.y * KEYBOARD_LOOK_SPEED * delta, -1.45, 1.45)
	_head.rotation.x = _pitch
	var wants_crouch := _crouch_toggled or Input.is_action_pressed("hold_crouch")
	if wants_crouch != is_crouching:
		if wants_crouch or _can_stand():
			is_crouching = wants_crouch
			_capsule.height = 1.1 if is_crouching else 1.75
			_collider.position.y = 0.58 if is_crouching else 0.9
	_head.position.y = lerpf(_head.position.y, 1.09 if is_crouching else 1.58, minf(1.0, delta * 12.0))
	var direction_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (global_transform.basis * Vector3(direction_2d.x, 0.0, direction_2d.y)).normalized()
	var speed := CROUCH_SPEED if is_crouching else (SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	elif Input.is_action_just_pressed("jump") and not is_crouching:
		velocity.y = JUMP_VELOCITY
	else:
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()
	if Input.is_action_pressed("fire") and _fire_timer <= 0.0:
		_fire()
	if Input.is_action_just_pressed("stealth_kill") and director != null:
		director.try_stealth_kill()
	_camera.fov = lerpf(_camera.fov, 62.0 if Input.is_action_pressed("aim") else 76.0, minf(1.0, delta * 12.0))
	_weapon.call("update_pose", delta, Input.is_action_pressed("aim"), direction_2d.length() > 0.01, Input.is_action_pressed("sprint"), is_reloading, get_reload_progress())


func _start_reload() -> void:
	if is_reloading or ammo == MAGAZINE_SIZE or dead:
		return
	is_reloading = true
	_reload_timer = RELOAD_SECONDS


func _fire() -> void:
	_fire_timer = FIRE_INTERVAL
	if is_reloading or ammo <= 0:
		return
	ammo -= 1
	shot_flash = 0.085
	_weapon.call("fired")
	_pitch = clampf(_pitch + 0.008, -1.45, 1.45)
	_shot_audio.play()
	if director != null:
		director.report_noise(global_position, 24.0)
	var from := _camera.global_position
	var to := from - _camera.global_transform.basis.z * 90.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var body: Object = hit["collider"]
	if body.has_method("take_damage"):
		body.call("take_damage", BULLET_DAMAGE, global_position)
		hit_marker = 0.17


func get_reload_progress() -> float:
	if not is_reloading:
		return 0.0
	return clampf(1.0 - _reload_timer / RELOAD_SECONDS, 0.0, 1.0)


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


func _build_shot_sound() -> void:
	var sample := AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = 22050
	var bytes := PackedByteArray()
	var seed_value := 47891
	for i in range(2600):
		seed_value = (seed_value * 16807) % 2147483647
		var noise := (float(seed_value % 20000) / 10000.0) - 1.0
		var envelope := exp(-float(i) / 620.0)
		var wave := sin(float(i) * 0.22) * 0.2
		var sample_value := int(clampf((noise * 0.7 + wave) * envelope, -1.0, 1.0) * 17000.0)
		bytes.append(sample_value & 255)
		bytes.append((sample_value >> 8) & 255)
	sample.data = bytes
	_shot_audio = AudioStreamPlayer.new()
	_shot_audio.stream = sample
	_shot_audio.volume_db = -13.0
	add_child(_shot_audio)
