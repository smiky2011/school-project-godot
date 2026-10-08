extends CharacterBody3D

const WALK_SPEED := 4.0
const SPRINT_SPEED := 6.3
const JUMP_SPEED := 4.7
const MOUSE_SENSITIVITY := 0.0021
const GROUND_ACCELERATION := 18.0
const AIR_ACCELERATION := 4.0

var head: Node3D
var camera: Camera3D
var controls_active := true
var _pitch := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 0.25
	_install_input_actions()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.75
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 0.9
	add_child(collider)
	head = Node3D.new()
	head.position.y = 1.58
	add_child(head)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 75.0
	camera.near = 0.03
	head.add_child(camera)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENSITIVITY, -1.45, 1.45)
		head.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	elif controls_active and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_SPEED

	var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if controls_active else Vector2.ZERO
	var direction := (global_transform.basis * Vector3(movement.x, 0.0, movement.y)).normalized()
	var speed := SPRINT_SPEED if controls_active and Input.is_action_pressed("sprint") else WALK_SPEED
	var acceleration := GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	move_and_slide()


func _install_input_actions() -> void:
	var bindings := {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"sprint": KEY_SHIFT,
		"jump": KEY_SPACE,
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = bindings[action]
		InputMap.action_add_event(action, key)
