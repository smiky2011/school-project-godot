extends Node3D

# Visual-only viewmodel. Ballistics, magazine capacity and reload time remain in
# Player and weapon_profile.gd. Motion is procedural: springs for recoil kick,
# lagging sway from mouse input, breathing, walk bob and a lowered sprint pose.
const STEN_SCENE: PackedScene = preload("res://assets/vendor/weapon_visual/sten_mk2/runtime/sten_mk2.glb")
const HANDS_SCRIPT: Script = preload("res://assets/player/gloved_hands.gd")
const FX_TEXTURES := preload("res://scripts/fx/fx_textures.gd")
const HIP := Vector3(0.24, -0.255, -0.55)
const ADS := Vector3(0.0, -0.083, -0.58)
const SPRINT_OFFSET := Vector3(0.05, -0.1, 0.04)
const SPRINT_ROTATION := Vector3(-0.32, 0.55, 0.28)
const VIEWMODEL_LAYER := 2
# Muzzle and ejection port measured on the imported mesh before model yaw.
const MUZZLE_LOCAL := Vector3(0.0, 0.061, 0.347)
const EJECTION_LOCAL := Vector3(-0.028, 0.066, 0.03)

var model: Node3D
var magazine: Node3D
var hands: Node3D
var muzzle_light: OmniLight3D
var muzzle_flash: MeshInstance3D
var _flash_side_a: MeshInstance3D
var _flash_side_b: MeshInstance3D
var _ejection: Marker3D
var _smoke: CPUParticles3D
var _magazine_origin := Vector3.ZERO
var _support_from_magazine := Transform3D.IDENTITY
var _aim := 0.0
var _flash_timer := 0.0
var _walk_cycle := 0.0
var _breath := 0.0
var _wall_tuck := 0.0
var _sprint := 0.0
var _heat := 0.0
var _kick_pos := Vector3.ZERO
var _kick_pos_vel := Vector3.ZERO
var _kick_rot := Vector3.ZERO
var _kick_rot_vel := Vector3.ZERO
var _sway := Vector2.ZERO
var _sway_target := Vector2.ZERO


func _ready() -> void:
	name = "StenMkIIViewmodel"
	position = HIP
	model = STEN_SCENE.instantiate() as Node3D
	model.name = "StenModel"
	model.rotation.y = PI # Imported barrel is +Z; first-person forward is -Z.
	add_child(model)
	magazine = model.get_node("StenMagazine") as Node3D
	_magazine_origin = magazine.position
	hands = HANDS_SCRIPT.new() as Node3D
	add_child(hands)
	# Keep the authored grip offset in magazine space for the entire reload.
	_support_from_magazine = magazine.global_transform.affine_inverse() * hands.support_hand.global_transform
	_ejection = Marker3D.new()
	_ejection.name = "EjectionPort"
	_ejection.position = EJECTION_LOCAL
	model.add_child(_ejection)
	_build_muzzle()
	_set_layers(self)


func fired() -> void:
	# Springs receive an impulse; ADS kicks are smaller and more vertical.
	var ads := _aim
	_kick_pos_vel += Vector3(randf_range(-3.0, 3.0) * (1.0 - ads), randf_range(1.5, 3.5), randf_range(32.0, 45.0)) * lerpf(1.0, 0.55, ads)
	_kick_rot_vel += Vector3(randf_range(90.0, 140.0), randf_range(-40.0, 40.0), randf_range(-60.0, 60.0)) * lerpf(1.0, 0.45, ads)
	_flash_timer = 0.05
	_heat = minf(1.0, _heat + 0.09)
	muzzle_flash.rotation.z = randf_range(-PI, PI)
	var s := randf_range(0.75, 1.2)
	muzzle_flash.scale = Vector3(s, s, s)
	_flash_side_a.scale = Vector3(randf_range(0.8, 1.25), 1.0, 1.0)
	_flash_side_b.scale = Vector3(randf_range(0.8, 1.25), 1.0, 1.0)
	muzzle_light.light_energy = randf_range(1.6, 2.4)


func add_look_sway(relative: Vector2) -> void:
	_sway_target += relative * 0.0009


func get_muzzle_position() -> Vector3:
	return muzzle_light.global_position


func get_ejection_transform() -> Transform3D:
	return _ejection.global_transform


func update_pose(delta: float, aim_amount: float, moving: bool, sprinting: bool, reloading: bool, reload_progress: float, reload_empty: bool = false, suppression: float = 0.0, crouching: bool = false) -> void:
	_wall_tuck = move_toward(_wall_tuck, clampf((0.82 - _wall_distance()) / 0.50, 0.0, 1.0), delta * 7.0)
	_aim = aim_amount if _wall_tuck < 0.15 else move_toward(_aim, 0.0, delta * 8.0)
	_sprint = move_toward(_sprint, 1.0 if sprinting else 0.0, delta * 6.0)
	_flash_timer = maxf(0.0, _flash_timer - delta)
	var flashing := _flash_timer > 0.0
	muzzle_light.visible = flashing
	muzzle_flash.visible = flashing
	_flash_side_a.visible = flashing
	_flash_side_b.visible = flashing
	_heat = maxf(0.0, _heat - delta * 0.35)
	_smoke.emitting = _heat > 0.35 and _flash_timer <= 0.0
	_step_springs(delta)
	# Mouse sway lags behind the view and settles back to center.
	_sway_target = _sway_target.lerp(Vector2.ZERO, minf(1.0, delta * 9.0))
	_sway = _sway.lerp(_sway_target, minf(1.0, delta * 14.0))
	var sway_scale := lerpf(1.0, 0.25, _aim)
	if moving:
		_walk_cycle += delta * (11.0 if sprinting else (5.5 if crouching else 7.5))
	_breath += delta * (1.2 + suppression * 2.5)
	var bob := Vector3.ZERO
	if moving:
		var amp := lerpf(1.0, 0.25, _aim) * (2.2 if sprinting else 1.0)
		bob = Vector3(sin(_walk_cycle) * 0.004, absf(cos(_walk_cycle)) * 0.005, 0.0) * amp
	var breath := Vector3(sin(_breath * 0.9) * 0.0012, sin(_breath * 1.8) * 0.0016, 0.0) * lerpf(1.0, 0.4, _aim) * (1.0 + suppression * 2.0)
	var lower := 0.0
	var roll := 0.0
	var magazine_out := 0.0
	var bolt := 0.0
	if reloading:
		# Tactical: magazine out and in. Empty: the same, then the bolt is
		# pulled back and released (a short sharp jerk of the whole gun).
		var mag_phase := reload_progress / (0.8 if reload_empty else 1.0)
		lower = sin(clampf(mag_phase, 0.0, 1.0) * PI) * 0.025
		roll = sin(clampf(mag_phase, 0.0, 1.0) * PI) * 0.19
		if mag_phase < 0.52:
			magazine_out = smoothstep(0.12, 0.33, mag_phase)
		else:
			magazine_out = 1.0 - smoothstep(0.55, 0.84, mag_phase)
		if reload_empty and reload_progress > 0.78:
			var b := (reload_progress - 0.78) / 0.22
			bolt = sin(clampf(b, 0.0, 1.0) * PI)
			roll += -0.12 * bolt
	var base := HIP.lerp(ADS, _ease(_aim))
	var sprint_pos := SPRINT_OFFSET * _sprint
	var sway_pos := Vector3(-_sway.x * 0.02, _sway.y * 0.016, 0.0) * sway_scale
	position = base + bob + breath + sprint_pos + sway_pos + _kick_pos * 0.01 \
		+ Vector3(0.0, -lower - 0.22 * _wall_tuck - bolt * 0.012, 0.43 * _wall_tuck + bolt * 0.03)
	rotation = Vector3(
		deg_to_rad(_kick_rot.x) + 0.64 * _wall_tuck + SPRINT_ROTATION.x * _sprint + _sway.y * 0.05 * sway_scale,
		deg_to_rad(_kick_rot.y) + SPRINT_ROTATION.y * _sprint - _sway.x * 0.06 * sway_scale,
		deg_to_rad(_kick_rot.z) + roll - 0.14 * _wall_tuck + SPRINT_ROTATION.z * _sprint - _sway.x * 0.08 * sway_scale)
	magazine.position = _magazine_origin + Vector3(0.16 * magazine_out, -0.04 * magazine_out, 0.015 * magazine_out)
	magazine.rotation.z = -0.18 * magazine_out
	hands.support_hand.global_transform = magazine.global_transform * _support_from_magazine


func _step_springs(delta: float) -> void:
	# Position kick in centimetres, rotation kick in degrees. Slightly
	# under-damped so the gun settles with a small, readable overshoot.
	var k := 320.0
	var c := 22.0
	_kick_pos_vel += (-_kick_pos * k - _kick_pos_vel * c) * delta
	_kick_pos += _kick_pos_vel * delta
	_kick_rot_vel += (-_kick_rot * k - _kick_rot_vel * c) * delta
	_kick_rot += _kick_rot_vel * delta


func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _wall_distance() -> float:
	var camera := get_parent() as Camera3D
	var player := camera.get_parent().get_parent() as CollisionObject3D
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * 0.82
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return 0.82
	return from.distance_to(hit["position"])


func _set_layers(node: Node) -> void:
	# The viewmodel renders on its own layer so world decals never land on it.
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = 1 << (VIEWMODEL_LAYER - 1)
	for child in node.get_children():
		_set_layers(child)


func _build_muzzle() -> void:
	muzzle_light = OmniLight3D.new()
	muzzle_light.name = "MuzzleLight"
	muzzle_light.position = MUZZLE_LOCAL
	muzzle_light.light_color = Color(1.0, 0.7, 0.38)
	muzzle_light.light_energy = 2.0
	muzzle_light.omni_range = 4.5
	muzzle_light.omni_attenuation = 1.6
	muzzle_light.shadow_enabled = false
	muzzle_light.visible = false
	model.add_child(muzzle_light)
	var star := StandardMaterial3D.new()
	star.albedo_texture = FX_TEXTURES.get_texture("flash_star")
	star.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	star.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	star.billboard_keep_scale = true
	star.cull_mode = BaseMaterial3D.CULL_DISABLED
	star.albedo_color = Color(1.0, 0.9, 0.75)
	var star_mesh := QuadMesh.new()
	star_mesh.size = Vector2(0.085, 0.085)
	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.name = "MuzzleFlash"
	muzzle_flash.mesh = star_mesh
	muzzle_flash.material_override = star
	muzzle_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	muzzle_flash.position = MUZZLE_LOCAL + Vector3(0.0, 0.0, 0.02)
	muzzle_flash.visible = false
	model.add_child(muzzle_flash)
	var side := StandardMaterial3D.new()
	side.albedo_texture = FX_TEXTURES.get_texture("flash_side")
	side.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	side.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	side.cull_mode = BaseMaterial3D.CULL_DISABLED
	var side_mesh := QuadMesh.new()
	side_mesh.size = Vector2(0.14, 0.045)
	_flash_side_a = _side_card(side_mesh, side, 0.0)
	_flash_side_b = _side_card(side_mesh, side, PI * 0.5)
	var smoke_material := StandardMaterial3D.new()
	smoke_material.albedo_texture = FX_TEXTURES.get_texture("soft_puff")
	smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_material.vertex_color_use_as_albedo = true
	smoke_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	smoke_material.billboard_keep_scale = true
	var smoke_mesh := QuadMesh.new()
	smoke_mesh.size = Vector2(0.05, 0.05)
	smoke_mesh.material = smoke_material
	_smoke = CPUParticles3D.new()
	_smoke.name = "BarrelSmoke"
	_smoke.mesh = smoke_mesh
	_smoke.amount = 14
	_smoke.lifetime = 1.3
	_smoke.local_coords = false
	_smoke.direction = Vector3.UP
	_smoke.spread = 18.0
	_smoke.gravity = Vector3(0.0, 0.35, 0.0)
	_smoke.initial_velocity_min = 0.04
	_smoke.initial_velocity_max = 0.1
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.5))
	grow.add_point(Vector2(1.0, 2.6))
	_smoke.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(0.8, 0.8, 0.8, 0.22))
	fade.set_color(1, Color(0.8, 0.8, 0.8, 0.0))
	_smoke.color_ramp = fade
	_smoke.emitting = false
	_smoke.position = MUZZLE_LOCAL
	model.add_child(_smoke)


func _side_card(mesh: QuadMesh, material: StandardMaterial3D, roll: float) -> MeshInstance3D:
	# Cards along the barrel axis give the flash length when seen from an angle.
	var card := MeshInstance3D.new()
	card.mesh = mesh
	card.material_override = material
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	card.position = MUZZLE_LOCAL + Vector3(0.0, 0.0, 0.07)
	card.rotation = Vector3(0.0, PI * 0.5, 0.0)
	card.rotate_object_local(Vector3.RIGHT, roll)
	card.visible = false
	model.add_child(card)
	return card
