extends Node3D

# Visual-only viewmodel. Ballistics, magazine capacity and reload time remain in Player.
const STEN_SCENE: PackedScene = preload("res://assets/vendor/weapon_visual/sten_mk2/runtime/sten_mk2.glb")
const HANDS_SCRIPT: Script = preload("res://assets/player/gloved_hands.gd")
const HIP := Vector3(0.24, -0.255, -0.55)
const ADS := Vector3(0.0, -0.083, -0.58)

var model: Node3D
var magazine: Node3D
var hands: Node3D
var muzzle_light: OmniLight3D
var muzzle_flash: MeshInstance3D
var _magazine_origin := Vector3.ZERO
var _support_from_magazine := Transform3D.IDENTITY
var _aim := 0.0
var _recoil := 0.0
var _flash_timer := 0.0
var _walk_cycle := 0.0
var _wall_tuck := 0.0


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
	_build_muzzle()


func fired() -> void:
	_recoil = minf(_recoil + 0.023, 0.07)
	_flash_timer = 0.085
	muzzle_flash.rotation.z = randf_range(-PI, PI)


func update_pose(delta: float, aiming: bool, moving: bool, sprinting: bool, reloading: bool, reload_progress: float) -> void:
	_wall_tuck = move_toward(_wall_tuck, clampf((0.82 - _wall_distance()) / 0.50, 0.0, 1.0), delta * 7.0)
	_aim = move_toward(_aim, 1.0 if aiming and not reloading and _wall_tuck < 0.15 else 0.0, delta * 8.0)
	_recoil = move_toward(_recoil, 0.0, delta * 0.23)
	_flash_timer = maxf(0.0, _flash_timer - delta)
	muzzle_light.visible = _flash_timer > 0.0
	muzzle_flash.visible = _flash_timer > 0.0
	if moving:
		_walk_cycle += delta * (10.0 if sprinting else 7.0)
	var bob := Vector3.ZERO
	if moving:
		bob = Vector3(sin(_walk_cycle) * 0.0035, absf(cos(_walk_cycle)) * 0.0045, 0.0)
	var lower := 0.0
	var roll := 0.0
	var magazine_out := 0.0
	if reloading:
		lower = sin(reload_progress * PI) * 0.025
		roll = sin(reload_progress * PI) * 0.19
		if reload_progress < 0.52:
			magazine_out = smoothstep(0.12, 0.33, reload_progress)
		else:
			magazine_out = 1.0 - smoothstep(0.55, 0.84, reload_progress)
	position = HIP.lerp(ADS, _aim) + bob + Vector3(0.0, -lower - 0.22 * _wall_tuck, _recoil + 0.43 * _wall_tuck)
	rotation = Vector3(_recoil * 0.45 + 0.64 * _wall_tuck, 0.0, roll - 0.14 * _wall_tuck)
	magazine.position = _magazine_origin + Vector3(0.16 * magazine_out, -0.04 * magazine_out, 0.015 * magazine_out)
	magazine.rotation.z = -0.18 * magazine_out
	hands.support_hand.global_transform = magazine.global_transform * _support_from_magazine


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


func _build_muzzle() -> void:
	# Muzzle position measured on the imported mesh before model yaw.
	muzzle_light = OmniLight3D.new()
	muzzle_light.name = "MuzzleLight"
	muzzle_light.position = Vector3(0.0, 0.061, 0.321)
	muzzle_light.light_color = Color(1.0, 0.67, 0.31)
	muzzle_light.light_energy = 0.72
	muzzle_light.omni_range = 1.45
	muzzle_light.shadow_enabled = false
	muzzle_light.visible = false
	model.add_child(muzzle_light)
	var flash_material := StandardMaterial3D.new()
	flash_material.albedo_color = Color(1.0, 0.74, 0.36)
	flash_material.emission_enabled = true
	flash_material.emission = Color(1.0, 0.48, 0.15)
	flash_material.emission_energy_multiplier = 3.5
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var shape := SphereMesh.new()
	shape.radius = 0.036
	shape.height = 0.10
	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.name = "MuzzleFlash"
	muzzle_flash.mesh = shape
	muzzle_flash.material_override = flash_material
	muzzle_flash.position = Vector3(0.0, 0.061, 0.347)
	muzzle_flash.scale = Vector3(1.0, 1.0, 1.7)
	muzzle_flash.visible = false
	model.add_child(muzzle_flash)
