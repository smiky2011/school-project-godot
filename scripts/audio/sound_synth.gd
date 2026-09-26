extends RefCounted

# Procedural, layered combat sounds. Following the layered approach described
# in docs/SHOOTER_BENCHMARKS.md, a shot is built from a transient crack, a
# low-frequency thump, bolt mechanics and a separate environment tail that is
# chosen per space (open, street, interior). Streams are cached statically so
# a mission restart does not synthesize them again.

const RATE := 32000

static var _cache: Dictionary = {}


static func get_stream(key: String) -> AudioStreamWAV:
	if _cache.has(key):
		return _cache[key]
	var data := PackedFloat32Array()
	match key:
		"sten_a":
			data = _shot(11, 1.0)
		"sten_b":
			data = _shot(29, 0.97)
		"sten_c":
			data = _shot(53, 1.03)
		"sten_d":
			data = _shot(71, 0.99)
		"tail_open":
			data = _tail(5, 1.5, 0.23, 520.0, 0.42)
		"tail_street":
			data = _tail(7, 0.95, 0.075, 760.0, 0.28)
		"tail_interior":
			data = _tail(9, 0.55, 0.018, 420.0, 0.14)
		"guard_shot":
			data = _mix(_shot(97, 0.93), _tail(13, 1.1, 0.12, 640.0, 0.32), 0.55)
		"near_miss":
			data = _near_miss(17)
		"dry_click":
			data = _click(19, 0.05, 2600.0, 0.5)
		"mag_out":
			data = _mix(_click(23, 0.06, 1800.0, 0.55), _scrape(24, 0.16, 0.25), 1.0)
		"mag_in":
			data = _mix(_scrape(25, 0.1, 0.22), _offset(_click(26, 0.08, 1400.0, 0.9), 0.09), 1.0)
		"bolt_rack":
			data = _mix(_click(27, 0.06, 2100.0, 0.7), _offset(_click(28, 0.09, 1500.0, 0.95), 0.16), 1.0)
		"impact_stone":
			data = _impact(31, 0.09, 3200.0, 0.6)
		"impact_wood":
			data = _impact(33, 0.12, 900.0, 0.7)
		"impact_dirt":
			data = _impact(35, 0.14, 500.0, 0.55)
		"impact_metal":
			data = _mix(_impact(37, 0.08, 3000.0, 0.5), _ring(38, 0.35, [1850.0, 2710.0, 4120.0], 0.25), 1.0)
		"impact_body":
			data = _impact(39, 0.1, 420.0, 0.75)
		"step_stone":
			data = _step(41, 1600.0, 0.32)
		"step_mud":
			data = _step(43, 520.0, 0.36)
		"step_wood":
			data = _step(45, 850.0, 0.42)
		_:
			push_warning("Unknown synthesized sound: " + key)
			data = PackedFloat32Array([0.0])
	var stream := _to_wav(data)
	_cache[key] = stream
	return stream


static func _to_wav(data: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in range(data.size()):
		var value := int(clampf(data[i], -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, value)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = bytes
	return wav


static func _noise_source(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func _shot(seed_value: int, pitch: float) -> PackedFloat32Array:
	# Close, dry report of a 9 mm open-bolt SMG.
	var length := int(RATE * 0.34)
	var out := PackedFloat32Array()
	out.resize(length)
	var rng := _noise_source(seed_value)
	var low := 0.0
	var high_prev := 0.0
	var high := 0.0
	var phase := 0.0
	for i in range(length):
		var t := float(i) / RATE
		var n := rng.randf_range(-1.0, 1.0)
		# High-passed crack: very fast decay.
		high = 0.86 * (high + n - high_prev)
		high_prev = n
		var crack := high * exp(-t / 0.009) * 1.1
		# Body: low-passed noise.
		low += (n - low) * 0.14
		var body := low * exp(-t / 0.05) * 2.4
		# Thump: falling sine for weight.
		var freq := (62.0 + 70.0 * exp(-t / 0.03)) * pitch
		phase += TAU * freq / RATE
		var thump := sin(phase) * exp(-t / 0.075) * 0.85
		# Bolt: metallic ring as the open bolt slams home and cycles.
		var mech := 0.0
		if t > 0.028:
			var tm := t - 0.028
			mech = (sin(TAU * 2140.0 * pitch * tm) + 0.6 * sin(TAU * 3380.0 * pitch * tm) + 0.4 * sin(TAU * 5110.0 * tm)) * exp(-tm / 0.018) * 0.12
		var attack := minf(1.0, t / 0.0006)
		out[i] = _soft_clip((crack + body + thump + mech) * attack * 0.9)
	return out


static func _tail(seed_value: int, seconds: float, slap_delay: float, cutoff: float, level: float) -> PackedFloat32Array:
	# Space response: a delayed slap off nearby walls plus a decaying wash.
	var length := int(RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(length)
	var rng := _noise_source(seed_value)
	var alpha := clampf(TAU * cutoff / RATE, 0.0, 1.0)
	var low := 0.0
	var low2 := 0.0
	for i in range(length):
		var t := float(i) / RATE
		var n := rng.randf_range(-1.0, 1.0)
		low += (n - low) * alpha
		low2 += (low - low2) * alpha
		var wash := low2 * exp(-t / (seconds * 0.28)) * minf(1.0, t / 0.02)
		var slap := 0.0
		var ts := t - slap_delay
		if ts > 0.0:
			slap = low * exp(-ts / 0.03) * 1.3
		out[i] = _soft_clip((wash * 3.2 + slap) * level)
	return out


static func _near_miss(seed_value: int) -> PackedFloat32Array:
	# Supersonic snap followed by a short falling whiz.
	var length := int(RATE * 0.22)
	var out := PackedFloat32Array()
	out.resize(length)
	var rng := _noise_source(seed_value)
	var band := 0.0
	var prev := 0.0
	var hp := 0.0
	for i in range(length):
		var t := float(i) / RATE
		var n := rng.randf_range(-1.0, 1.0)
		hp = 0.8 * (hp + n - prev)
		prev = n
		var snap := hp * exp(-t / 0.004) * 1.2
		var sweep := 3800.0 - 2600.0 * clampf(t / 0.18, 0.0, 1.0)
		band += (hp - band) * clampf(TAU * sweep / RATE, 0.0, 1.0)
		var whiz := band * sin(PI * clampf(t / 0.2, 0.0, 1.0)) * 0.9
		out[i] = _soft_clip(snap + whiz)
	return out


static func _click(seed_value: int, seconds: float, ring_freq: float, level: float) -> PackedFloat32Array:
	var length := int(RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(length)
	var rng := _noise_source(seed_value)
	for i in range(length):
		var t := float(i) / RATE
		var n := rng.randf_range(-1.0, 1.0)
		var body := n * exp(-t / 0.003)
		var ring := sin(TAU * ring_freq * t) * exp(-t / 0.012) * 0.6
		out[i] = _soft_clip((body + ring) * level)
	return out


static func _scrape(seed_value: int, seconds: float, level: float) -> PackedFloat32Array:
	var length := int(RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(length)
	var rng := _noise_source(seed_value)
	var low := 0.0
	for i in range(length):
		var t := float(i) / RATE
		low += (rng.randf_range(-1.0, 1.0) - low) * 0.35
		out[i] = low * sin(PI * t / seconds) * level
	return out


static func _ring(seed_value: int, seconds: float, freqs: Array, level: float) -> PackedFloat32Array:
	var length := int(RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(length)
	var rng := _noise_source(seed_value)
	var detune := rng.randf_range(0.97, 1.03)
	for i in range(length):
		var t := float(i) / RATE
		var v := 0.0
		for f in freqs:
			v += sin(TAU * float(f) * detune * t)
		out[i] = v / float(freqs.size()) * exp(-t / (seconds * 0.3)) * level
	return out


static func _impact(seed_value: int, seconds: float, cutoff: float, level: float) -> PackedFloat32Array:
	var length := int(RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(length)
	var rng := _noise_source(seed_value)
	var alpha := clampf(TAU * cutoff / RATE, 0.0, 1.0)
	var low := 0.0
	for i in range(length):
		var t := float(i) / RATE
		low += (rng.randf_range(-1.0, 1.0) - low) * alpha
		out[i] = _soft_clip(low * exp(-t / (seconds * 0.22)) * level * 3.0)
	return out


static func _step(seed_value: int, cutoff: float, level: float) -> PackedFloat32Array:
	# Heel then toe contact.
	var heel := _impact(seed_value, 0.07, cutoff, level)
	var toe := _impact(seed_value + 1, 0.06, cutoff * 1.3, level * 0.6)
	return _mix(heel, _offset(toe, 0.045), 1.0)


static func _offset(data: PackedFloat32Array, seconds: float) -> PackedFloat32Array:
	var pad := int(RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(pad + data.size())
	for i in range(data.size()):
		out[pad + i] = data[i]
	return out


static func _mix(a: PackedFloat32Array, b: PackedFloat32Array, b_gain: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(maxi(a.size(), b.size()))
	for i in range(out.size()):
		var v := 0.0
		if i < a.size():
			v += a[i]
		if i < b.size():
			v += b[i] * b_gain
		out[i] = _soft_clip(v)
	return out


static func _soft_clip(v: float) -> float:
	# tanh-style limiter keeps layered peaks from hard clipping.
	return v / (1.0 + absf(v) * 0.6)
