extends SceneTree

# Synthetic fixtures exercise the real town and guard scripts. Run with:
# Godot --headless --path . --script res://tests/guard_regression.gd

const LEVEL_SCRIPT := preload("res://scripts/world/town_level.gd")

class TestPlayer:
	extends CharacterBody3D
	var is_crouching := false
	var dead := false
	var damage_taken := 0.0
	var camera: Camera3D

	func _ready() -> void:
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.28
		capsule.height = 1.7
		var shape := CollisionShape3D.new()
		shape.shape = capsule
		shape.position.y = 0.85
		add_child(shape)
		camera = Camera3D.new()
		camera.position.y = 1.55
		add_child(camera)

	func get_camera() -> Camera3D:
		return camera

	func take_damage(amount: float) -> void:
		damage_taken += amount


class TestDirector:
	extends Node
	var active := true
	var kills := 0
	var detections := 0

	func is_active() -> bool:
		return active

	func report_detection(_position: Vector3, _source_guard: Node) -> void:
		detections += 1

	func guard_killed() -> void:
		kills += 1


var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_gradual_and_recoverable_detection()
	await _test_wall_occlusion_and_fire()
	await _test_last_seen_search()
	await _test_sentry_returns_to_post()
	await _test_corpse_discovery_once()
	await _test_unwitnessed_and_witnessed_kills()
	await _test_finite_reinforcements_and_npcs()
	if _failures.is_empty():
		print("GUARD REGRESSION PASS (", _checks, " checks)")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("GUARD REGRESSION FAIL (", _failures.size(), "/", _checks, " checks)")
		quit(1)


func _fixture() -> Dictionary:
	var level := LEVEL_SCRIPT.new()
	root.add_child(level)
	var player := TestPlayer.new()
	root.add_child(player)
	var director := TestDirector.new()
	root.add_child(director)
	level.setup(director, player)
	player.global_transform = level.get_spawn_transform()
	return {"level": level, "player": player, "director": director}


func _close_fixture(fixture: Dictionary) -> void:
	fixture.level.queue_free()
	fixture.player.queue_free()
	fixture.director.queue_free()
	await process_frame


func _physics_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _hold_sentry(guard: CharacterBody3D, at: Vector3, facing_y: float) -> void:
	guard.global_position = at
	guard.rotation.y = facing_y
	guard._sentry = true
	guard._home_position = at
	guard._home_rotation = facing_y
	guard._path_goal = Vector3.INF


func _test_gradual_and_recoverable_detection() -> void:
	var f := _fixture()
	var guard: CharacterBody3D = f.level.get_guards()[0]
	_hold_sentry(guard, Vector3(0, 0.08, 30), 0.0)
	f.player.global_position = Vector3(0, 0.08, 24.5)
	await _physics_frames(4)
	_expect(guard.state == "SUSPICIOUS" and guard.suspicion > 0.0 and guard.suspicion < 1.0, "Visible player builds suspicion gradually")
	f.player.global_position = Vector3(0, 0.08, 39)
	await _physics_frames(80)
	_expect(guard.state == "PATROL" and guard.suspicion == 0.0 and f.director.detections == 0, "Breaking sight early returns to duty without detection")
	f.player.global_position = Vector3(0, 0.08, 24.5)
	await _physics_frames(180)
	_expect(guard.state == "COMBAT" and guard.suspicion == 1.0, "Sustained visible exposure confirms detection")
	_expect(f.director.detections == 1, "Confirmed sighting reports one local detection event")
	_expect(f.player.damage_taken > 0.0, "Confirmed guard actually fires and damages exposed player")
	await _close_fixture(f)


func _test_wall_occlusion_and_fire() -> void:
	var f := _fixture()
	var guard: CharacterBody3D = f.level.get_guards()[0]
	_hold_sentry(guard, Vector3(-12, 0.08, 18), PI * 0.5)
	f.player.global_position = Vector3(-25, 0.08, 18)
	await _physics_frames(4)
	_expect(not guard._can_see_player(), "Stone house occludes guard sight inside nominal cone")
	var before: float = f.player.damage_taken
	guard._fire_at_player()
	_expect(f.player.damage_taken == before, "Stone house stops guard bullet ray")
	await _close_fixture(f)


func _test_last_seen_search() -> void:
	var f := _fixture()
	var guard: CharacterBody3D = f.level.get_guards()[0]
	_hold_sentry(guard, Vector3(0, 0.08, 30), 0.0)
	f.player.global_position = Vector3(0, 0.08, 25)
	await _physics_frames(2)
	guard._enter_combat(f.player.global_position)
	var evidence: Vector3 = f.player.global_position
	f.player.global_position = Vector3(-25, 0.08, 18)
	await _physics_frames(96)
	_expect(guard.state == "SEARCH", "Guard searches after losing a confirmed sighting")
	_expect(guard._search_target.distance_to(evidence) < 0.2, "Search target is last seen position")
	f.player.global_position = Vector3(-24, 0.08, 25)
	await _physics_frames(6)
	_expect(guard._search_target.distance_to(evidence) < 0.2, "Hidden player movement does not update search target")
	await _close_fixture(f)


func _test_sentry_returns_to_post() -> void:
	var f := _fixture()
	var guard: CharacterBody3D = f.level.get_guards()[1]
	f.player.global_position = Vector3(0, 0.08, 36)
	var post: Vector3 = guard._home_position
	var heading: float = guard._home_rotation
	guard.global_position = Vector3(6, 0.08, -13)
	guard._start_search(Vector3(6, 0, -13))
	guard._search_timer = 0.01
	await _physics_frames(150)
	_expect(guard.state == "PATROL" and guard.global_position.distance_to(post) < 0.9, "Fixed sentry returns to its post")
	_expect(absf(wrapf(guard.rotation.y - heading, -PI, PI)) < 0.2, "Fixed sentry restores its heading")
	await _close_fixture(f)


func _test_corpse_discovery_once() -> void:
	var f := _fixture()
	var victim: CharacterBody3D = f.level.get_guards()[0]
	var observer: CharacterBody3D = f.level.get_guards()[1]
	_hold_sentry(victim, Vector3(0, 0.08, 25), PI)
	_hold_sentry(observer, Vector3(0, 0.08, 31), 0.0)
	f.player.global_position = Vector3(-25, 0.08, 33)
	await _physics_frames(2)
	victim.take_damage(200.0, f.player.global_position)
	_expect(observer.state != "COMBAT", "Unwitnessed death does not reveal hidden player")
	await _physics_frames(48)
	_expect(observer.state == "SEARCH" and observer._search_target.distance_to(victim.global_position) < 0.2, "Visible body starts a search at corpse, not player")
	observer._search_timer = 0.01
	await _physics_frames(80)
	_expect(observer.state == "PATROL" and observer._seen_corpses.has(victim.get_instance_id()), "Same corpse cannot restart search after expiry")
	var collider := _find_collider(victim)
	_expect(collider != null and absf(collider.rotation.z - PI * 0.5) < 0.01 and collider.position.y < 0.5, "Corpse collider lies at ground level")
	_expect(f.director.kills == 1, "Fatal shot calls kill counter once")
	victim.take_damage(200.0, f.player.global_position)
	_expect(f.director.kills == 1, "Repeated corpse hits do not count another kill")
	await _close_fixture(f)


func _test_unwitnessed_and_witnessed_kills() -> void:
	var quiet := _fixture()
	var victim: CharacterBody3D = quiet.level.get_guards()[0]
	var observer: CharacterBody3D = quiet.level.get_guards()[1]
	_hold_sentry(victim, Vector3(0, 0.08, 25), PI)
	_hold_sentry(observer, Vector3(0, 0.08, 31), PI)
	quiet.player.global_position = Vector3(0, 0.08, 23.3)
	await _physics_frames(2)
	_expect(victim.can_stealth_kill(quiet.player.global_position), "Unseen rear approach qualifies for close kill")
	victim.stealth_kill()
	_expect(observer.state != "COMBAT" and quiet.director.kills == 1, "Unwitnessed takedown is quiet and counts once")
	await _close_fixture(quiet)

	var seen := _fixture()
	victim = seen.level.get_guards()[0]
	observer = seen.level.get_guards()[1]
	_hold_sentry(victim, Vector3(0, 0.08, 25), PI)
	_hold_sentry(observer, Vector3(0, 0.08, 31), 0.0)
	seen.player.global_position = Vector3(0, 0.08, 23.3)
	await _physics_frames(2)
	victim.stealth_kill()
	_expect(observer.state == "COMBAT" and seen.director.detections >= 1, "Clear witness to attacker and victim triggers local combat")
	await _close_fixture(seen)


func _test_finite_reinforcements_and_npcs() -> void:
	var f := _fixture()
	_expect(f.level.get_guards().size() == 6, "Six initial guards across central and southern districts")
	_expect(f.level.get_ground_path(f.level.get_spawn_transform().origin, Vector3(-19, 0, 41)).size() > 100, "Southern entry connects to the tested central district")
	f.level.spawn_reinforcements()
	f.level.spawn_reinforcements()
	_expect(f.level.get_guards().size() == 8, "One finite two-guard reinforcement contingent in southern stage")
	var npc_has_collider := false
	var npc_has_damage_method := false
	var contact_found := false
	var scout_found := false
	for child in f.level.get_children():
		if child.name == "Contact coat":
			contact_found = true
		if child.name == "Scout coat":
			scout_found = true
		if child.name == "Contact coat" or child.name == "Scout coat":
			npc_has_collider = npc_has_collider or child is CollisionObject3D
			npc_has_damage_method = npc_has_damage_method or child.has_method("take_damage")
	_expect(contact_found and scout_found, "Both protected mission NPCs exist")
	_expect(not npc_has_collider, "Protected NPC visuals are noncolliding")
	_expect(not npc_has_damage_method, "Protected NPC visuals have no damage handler")
	_expect(f.director.detections == 0, "NPC spawn creates no awareness event")
	await _close_fixture(f)


func _find_collider(node: Node) -> CollisionShape3D:
	for child in node.get_children():
		if child is CollisionShape3D:
			return child
	return null
