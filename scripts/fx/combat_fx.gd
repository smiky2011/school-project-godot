extends Node3D

# World-space combat feedback: impact decals and debris, body-hit puffs,
# travelling tracers, ejected shells and positional one-shot sounds.
# Visual and audio only; no function here changes damage, noise or AI.

const FX_TEXTURES := preload("res://scripts/fx/fx_textures.gd")
const SYNTH := preload("res://scripts/audio/sound_synth.gd")

const MAX_DECALS := 96
const MAX_SHELLS := 40
const WORLD_LAYER := 1

var _decals: Array[Decal] = []
var _decal_index := 0
var _tracers: Array[Dictionary] = []
var _shells: Array[Dictionary] = []
var _audio_pool: Array[AudioStreamPlayer3D] = []
var _audio_index := 0
var _puff_material: StandardMaterial3D
var _chip_material: StandardMaterial3D
var _spark_material: StandardMaterial3D
var _tracer_material: StandardMaterial3D
var _shell_material: StandardMaterial3D
var _shell_mesh: CylinderMesh
var _puff_mesh: QuadMesh
var _chip_mesh: BoxMesh
var _spark_mesh: QuadMesh


static func find(tree: SceneTree) -> Node:
	if tree == null:
		return null
	return tree.get_first_node_in_group("combat_fx")


func _ready() -> void:
	name = "CombatFx"
	add_to_group("combat_fx")
	_puff_material = StandardMaterial3D.new()
	_puff_material.albedo_texture = FX_TEXTURES.get_texture("soft_puff")
	_puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_puff_material.vertex_color_use_as_albedo = true
	_puff_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_puff_material.billboard_keep_scale = true
	_puff_material.roughness = 1.0
	_puff_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_puff_mesh = QuadMesh.new()
	_puff_mesh.size = Vector2(0.28, 0.28)
	_puff_mesh.material = _puff_material
	_chip_material = StandardMaterial3D.new()
	_chip_material.vertex_color_use_as_albedo = true
	_chip_material.roughness = 0.95
	_chip_mesh = BoxMesh.new()
	_chip_mesh.size = Vector3(0.018, 0.012, 0.014)
	_chip_mesh.material = _chip_material
	_spark_material = StandardMaterial3D.new()
	_spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_spark_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_spark_material.albedo_color = Color(1.0, 0.72, 0.35)
	_spark_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_spark_mesh = QuadMesh.new()
	_spark_mesh.size = Vector2(0.012, 0.05)
	_spark_mesh.material = _spark_material
	_tracer_material = StandardMaterial3D.new()
	_tracer_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tracer_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_tracer_material.albedo_texture = FX_TEXTURES.get_texture("tracer")
	_tracer_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_tracer_material.vertex_color_use_as_albedo = true
	_shell_material = StandardMaterial3D.new()
	_shell_material.albedo_color = Color(0.74, 0.56, 0.24)
	_shell_material.metallic = 1.0
	_shell_material.roughness = 0.32
	_shell_mesh = CylinderMesh.new()
	_shell_mesh.top_radius = 0.0048
	_shell_mesh.bottom_radius = 0.005
	_shell_mesh.height = 0.019
	_shell_mesh.radial_segments = 8
	_shell_mesh.rings = 1
	_shell_mesh.material = _shell_material
	for i in range(12):
		var player := AudioStreamPlayer3D.new()
		player.name = "FxAudio%d" % i
		player.max_distance = 60.0
		player.unit_size = 4.0
		player.bus = &"Master"
		add_child(player)
		_audio_pool.append(player)


func play_3d(key: String, at: Vector3, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> void:
	if _audio_pool.is_empty():
		return
	var player := _audio_pool[_audio_index]
	_audio_index = (_audio_index + 1) % _audio_pool.size()
	player.stream = SYNTH.get_stream(key)
	player.global_position = at
	player.volume_db = volume_db
	player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	player.play()


func impact(at: Vector3, normal: Vector3, surface: String, with_decal: bool = true) -> void:
	var dust := Color(0.62, 0.6, 0.56)
	var chips := Color(0.55, 0.53, 0.5)
	var sound := "impact_stone"
	match surface:
		"plaster":
			dust = Color(0.8, 0.77, 0.7)
			chips = Color(0.78, 0.75, 0.68)
		"wood":
			dust = Color(0.5, 0.4, 0.3)
			chips = Color(0.52, 0.38, 0.24)
			sound = "impact_wood"
		"dirt":
			dust = Color(0.38, 0.33, 0.27)
			chips = Color(0.3, 0.26, 0.2)
			sound = "impact_dirt"
		"metal":
			dust = Color(0.45, 0.45, 0.45)
			sound = "impact_metal"
	_spawn_puff(at, normal, dust, 7, 0.9, 1.4)
	if surface != "metal":
		_spawn_chips(at, normal, chips)
	else:
		_spawn_sparks(at, normal)
	if with_decal and surface != "dirt":
		_place_decal(at, normal, "bullet_hole_wood" if surface == "wood" else "bullet_hole", 0.13)
	elif with_decal:
		_place_decal(at, normal, "scorch", 0.16, Color(0.35, 0.3, 0.25, 0.8))
	play_3d(sound, at, -9.0, 0.12)


func body_hit(at: Vector3, normal: Vector3) -> void:
	# Restrained: a dark cloth-and-blood mist, no gore geometry.
	_spawn_puff(at, normal, Color(0.32, 0.08, 0.06, 0.9), 6, 0.45, 0.9)
	play_3d("impact_body", at, -6.0, 0.1)


func tracer(from: Vector3, to: Vector3, color: Color = Color(1.0, 0.86, 0.62, 0.55), speed: float = 380.0, width: float = 0.018, length: float = 2.6) -> void:
	var distance := from.distance_to(to)
	if distance < 1.0:
		return
	var instance := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	instance.mesh = mesh
	var material := _tracer_material.duplicate() as StandardMaterial3D
	material.albedo_color = color
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	_tracers.append({"node": instance, "from": from, "dir": (to - from) / distance, "distance": distance, "travel": 0.0, "speed": speed, "width": width, "length": minf(length, distance)})


func eject_shell(at: Transform3D, velocity: Vector3) -> void:
	var shell := MeshInstance3D.new()
	shell.mesh = _shell_mesh
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shell)
	shell.global_transform = at
	var floor_y := at.origin.y - 1.6
	var query := PhysicsRayQueryParameters3D.create(at.origin, at.origin + Vector3.DOWN * 3.0)
	query.collision_mask = WORLD_LAYER
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		floor_y = hit.position.y + 0.005
	_shells.append({"node": shell, "vel": velocity, "spin": Vector3(randf_range(-30, 30), randf_range(-30, 30), randf_range(-30, 30)), "floor": floor_y, "age": 0.0, "resting": false, "bounced": false})
	while _shells.size() > MAX_SHELLS:
		var old: Dictionary = _shells.pop_front()
		if is_instance_valid(old.node):
			old.node.queue_free()


func place_static_decal(at: Vector3, normal: Vector3, key: String, size: float, modulate: Color = Color.WHITE) -> void:
	# Pre-placed war damage (not pooled, never recycled). Distance fade keeps
	# hundreds of small scars from costing anything far away.
	var decal := _make_decal(key, size, modulate)
	decal.distance_fade_enabled = true
	decal.distance_fade_begin = 45.0 if size < 0.5 else 110.0
	decal.distance_fade_length = 10.0
	add_child(decal)
	_orient_decal(decal, at, normal)


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	for i in range(_tracers.size() - 1, -1, -1):
		var t: Dictionary = _tracers[i]
		t.travel += t.speed * delta
		var node: MeshInstance3D = t.node
		if t.travel - t.length > t.distance or camera == null:
			node.queue_free()
			_tracers.remove_at(i)
			continue
		var head_d: float = minf(t.travel, t.distance)
		var tail_d: float = maxf(0.0, t.travel - t.length)
		var head: Vector3 = t.from + t.dir * head_d
		var tail: Vector3 = t.from + t.dir * tail_d
		var seg := head - tail
		if seg.length() < 0.01:
			node.visible = false
			continue
		node.visible = true
		var mid := (head + tail) * 0.5
		var to_camera := (camera.global_position - mid).normalized()
		var side: Vector3 = t.dir.cross(to_camera)
		if side.length_squared() < 0.0001:
			side = Vector3.UP
		side = side.normalized() * float(t.width)
		var normal := seg.cross(side).normalized()
		node.global_transform = Transform3D(Basis(seg, side, normal), mid)
	for i in range(_shells.size() - 1, -1, -1):
		var s: Dictionary = _shells[i]
		var shell: MeshInstance3D = s.node
		if not is_instance_valid(shell):
			_shells.remove_at(i)
			continue
		s.age += delta
		if s.resting:
			continue
		s.vel.y -= 9.8 * delta
		var p: Vector3 = shell.global_position + s.vel * delta
		shell.rotate_object_local(Vector3.RIGHT, s.spin.x * delta)
		shell.rotate_object_local(Vector3.FORWARD, s.spin.z * delta)
		if p.y <= s.floor:
			p.y = s.floor
			if not s.bounced and s.vel.length() > 1.0:
				s.bounced = true
				s.vel = Vector3(s.vel.x * 0.35, -s.vel.y * 0.3, s.vel.z * 0.35)
				s.spin *= 0.4
				if randf() < 0.5:
					play_3d("dry_click", p, -26.0, 0.25)
			else:
				s.resting = true
				shell.global_transform.basis = Basis(Vector3.UP, randf() * TAU) * Basis(Vector3.FORWARD, PI * 0.5)
		shell.global_position = p


func _spawn_puff(at: Vector3, normal: Vector3, color: Color, amount: int, lifetime: float, spread_speed: float) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.amount = amount
	particles.lifetime = lifetime
	particles.mesh = _puff_mesh
	particles.local_coords = false
	particles.direction = Vector3.UP
	particles.spread = 38.0
	particles.initial_velocity_min = spread_speed * 0.35
	particles.initial_velocity_max = spread_speed
	particles.gravity = Vector3(0.0, -0.6, 0.0)
	particles.damping_min = 2.5
	particles.damping_max = 4.0
	particles.angle_min = -180.0
	particles.angle_max = 180.0
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.35))
	curve.add_point(Vector2(1.0, 1.8))
	particles.scale_amount_curve = curve
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.r, color.g, color.b, color.a * 0.85))
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	particles.color_ramp = ramp
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_emit(particles, at + normal * 0.03, normal, lifetime)


func _spawn_chips(at: Vector3, normal: Vector3, color: Color) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 6
	particles.lifetime = 0.7
	particles.mesh = _chip_mesh
	particles.local_coords = false
	particles.direction = Vector3.UP
	particles.spread = 50.0
	particles.initial_velocity_min = 1.6
	particles.initial_velocity_max = 3.8
	particles.gravity = Vector3(0.0, -9.8, 0.0)
	particles.angular_velocity_min = -600.0
	particles.angular_velocity_max = 600.0
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.6
	particles.color = color
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_emit(particles, at + normal * 0.02, normal, 0.7)


func _spawn_sparks(at: Vector3, normal: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 10
	particles.lifetime = 0.25
	particles.mesh = _spark_mesh
	particles.local_coords = false
	particles.direction = Vector3.UP
	particles.spread = 60.0
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 6.0
	particles.gravity = Vector3(0.0, -9.8, 0.0)
	particles.particle_flag_align_y = true
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_emit(particles, at + normal * 0.02, normal, 0.25)


func _emit(particles: CPUParticles3D, at: Vector3, normal: Vector3, lifetime: float) -> void:
	add_child(particles)
	var up := normal.normalized()
	var reference := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := reference.cross(up).normalized()
	var z := x.cross(up).normalized()
	particles.global_transform = Transform3D(Basis(x, up, z), at)
	particles.emitting = true
	get_tree().create_timer(lifetime + 0.4, false).timeout.connect(particles.queue_free)


func _place_decal(at: Vector3, normal: Vector3, key: String, size: float, modulate: Color = Color.WHITE) -> void:
	var decal: Decal
	if _decals.size() < MAX_DECALS:
		decal = _make_decal(key, size, modulate)
		add_child(decal)
		_decals.append(decal)
	else:
		decal = _decals[_decal_index]
		_decal_index = (_decal_index + 1) % MAX_DECALS
		decal.texture_albedo = FX_TEXTURES.get_texture(key)
		decal.modulate = modulate
		decal.size = Vector3(size, 0.12, size)
	_orient_decal(decal, at, normal)


func _make_decal(key: String, size: float, modulate: Color) -> Decal:
	var decal := Decal.new()
	decal.texture_albedo = FX_TEXTURES.get_texture(key)
	decal.modulate = modulate
	decal.size = Vector3(size, 0.12, size)
	decal.cull_mask = WORLD_LAYER
	decal.normal_fade = 0.35
	decal.upper_fade = 0.1
	decal.lower_fade = 0.1
	return decal


func _orient_decal(decal: Decal, at: Vector3, normal: Vector3) -> void:
	# A decal projects along its local -Y axis, so +Y faces out of the surface.
	var up := normal.normalized()
	var reference := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := reference.cross(up).normalized()
	var z := x.cross(up).normalized()
	var basis := Basis(x, up, z) * Basis(Vector3.UP, randf() * TAU)
	decal.global_transform = Transform3D(basis, at)
