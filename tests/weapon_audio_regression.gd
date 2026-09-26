extends SceneTree

# Audio playback regression for the real player's gunshot report path. Repeated
# calls emulate its 0.105-second automatic-fire interval without changing ammo,
# damage, AI or mission state. Run with Godot --headless --path . --script
# res://tests/weapon_audio_regression.gd.

const SYNTH := preload("res://scripts/audio/sound_synth.gd")
const SHOT_INTERVAL := 0.105
const EXPECTED_TAIL_VOICES := 16

var _checks := 0
var _player: CharacterBody3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Construct the production player directly. The mission scene includes a
	# large town and imported guard models that are unrelated to this audio path.
	_player = load("res://scripts/player/player.gd").new() as CharacterBody3D
	root.add_child(_player)
	await process_frame
	var tails: Array = _player.get("_tail_players")
	if not _check(tails.size() == EXPECTED_TAIL_VOICES, "Tail pool has 16 bounded voices"):
		return
	var owned_voice_count := 0
	for tail in tails:
		if tail is AudioStreamPlayer and tail.get_parent() == _player:
			owned_voice_count += 1
	if not _check(owned_voice_count == EXPECTED_TAIL_VOICES,
			"All tail voices belong to the real player"):
		return

	# Hold an open-space classification so the 230 ms slap and 1.5 s decay are
	# testable while player movement and the town continue normally.
	_player.set("_space", "open")
	_player.set("_space_timer", 100.0)
	_player.call("_play_shot")
	var first: AudioStreamPlayer = tails[0]
	if not _check(first.stream == SYNTH.get_stream("tail_open") and is_equal_approx(first.volume_db, -10.0),
			"Open shot uses its established stream and gain"):
		return
	# Allow for device startup latency before checking playback position; the
	# first voice has enough lifetime for five subsequent automatic rounds.
	for _i in range(5):
		await create_timer(SHOT_INTERVAL).timeout
		_player.call("_play_shot")
	print("WEAPON AUDIO playback first_playing=%s first_seconds=%.3f concurrent=%d" % [
		first.playing, first.get_playback_position(), _playing_count(tails)])
	if not _check(first.playing and first.get_playback_position() > 0.23,
			"First tail keeps playing past its 230 ms wall slap during automatic fire"):
		return
	if not _check(_playing_count(tails) >= 3,
			"Several environmental tails overlap during a burst"):
		return

	# Check that the pool wraps and remains bounded while preserving the other
	# existing environment choices and gains.
	for _i in range(EXPECTED_TAIL_VOICES + 2):
		await create_timer(SHOT_INTERVAL).timeout
		_player.call("_play_shot")
	if not _check(_playing_count(tails) <= EXPECTED_TAIL_VOICES,
			"Long burst never exceeds the bounded tail pool"):
		return
	for space in ["street", "interior"]:
		_player.set("_space", space)
		_player.set("_space_timer", 100.0)
		var index: int = _player.get("_tail_index")
		_player.call("_play_shot")
		var selected: AudioStreamPlayer = tails[index]
		var expected_gain := -9.0 if space == "street" else -12.0
		if not _check(selected.playing and selected.stream == SYNTH.get_stream("tail_" + space)
				and is_equal_approx(selected.volume_db, expected_gain),
				"%s shot uses its established stream and gain" % space):
			return

	# A deterministic sampled sum of 20 sten_a reports plus environmental tails
	# at the real interval and gains. It catches clipping in this one pre-bus
	# mix, but does not bound random variant/pitch, other game sounds, device
	# output or subjective quality.
	for space in ["open", "street", "interior"]:
		var peak := _burst_peak(space, 20)
		if not _check(peak <= 1.0, "%s sampled burst mix stays below full-scale (peak %.3f)" % [space, peak]):
			return
	print("WEAPON AUDIO PASS checks=%d" % _checks)
	for child in _player.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D:
			child.stop()
	_player.queue_free()
	for _i in range(3):
		await process_frame
	quit(0)


func _playing_count(tails: Array) -> int:
	var count := 0
	for tail in tails:
		if tail.playing:
			count += 1
	return count


func _burst_peak(space: String, shot_count: int) -> float:
	var tail_stream: AudioStreamWAV = SYNTH.get_stream("tail_" + space)
	var shot_stream: AudioStreamWAV = SYNTH.get_stream("sten_a")
	var tail_bytes := tail_stream.data
	var shot_bytes := shot_stream.data
	var interval_samples := roundi(SHOT_INTERVAL * float(tail_stream.mix_rate))
	var tail_samples := int(tail_bytes.size() / 2)
	var shot_samples := int(shot_bytes.size() / 2)
	var mix := PackedFloat32Array()
	mix.resize(maxi(tail_samples, shot_samples) + interval_samples * (shot_count - 1))
	var tail_gain := db_to_linear({"open": -10.0, "street": -9.0, "interior": -12.0}[space])
	var shot_gain := db_to_linear(-7.0)
	for shot in range(shot_count):
		var start := shot * interval_samples
		for sample in range(tail_samples):
			mix[start + sample] += float(tail_bytes.decode_s16(sample * 2)) / 32768.0 * tail_gain
		for sample in range(shot_samples):
			mix[start + sample] += float(shot_bytes.decode_s16(sample * 2)) / 32768.0 * shot_gain
	var peak := 0.0
	for value in mix:
		peak = maxf(peak, absf(value))
	return peak


func _check(condition: bool, message: String) -> bool:
	if condition:
		_checks += 1
		print("WEAPON AUDIO CHECK %d %s" % [_checks, message])
		return true
	push_error("WEAPON AUDIO FAIL: " + message)
	quit(1)
	return false
