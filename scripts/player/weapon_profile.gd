extends RefCounted

# StG 44 handling data. Gameplay code reads these values instead of
# scattering numbers through Player; see docs/SHOOTER_BENCHMARKS.md for the
# AAA patterns (authored recoil, separate spread, tactical/empty reloads).
# Magazine size and unlimited reserve are confirmed design rules; every other
# number here is provisional tuning awaiting human playtest.

const NAME := "StG 44"
const MAGAZINE_SIZE := 30
const FIRE_INTERVAL := 0.105 # About 570 rounds per minute.
const RANGE := 120.0
const NOISE_RADIUS := 24.0

# Damage: three body hits or one head hit drop a 100-health guard at town
# ranges. Falloff starts beyond typical street distances.
const BODY_DAMAGE := 34.0
const HEAD_MULTIPLIER := 3.0
const FALLOFF_START := 30.0
const FALLOFF_END := 80.0
const FALLOFF_MIN_SCALE := 0.7
const HEAD_RADIUS := 0.14

# Reloads. The empty-magazine animation includes a charging-handle pull.
const TACTICAL_RELOAD := 1.9
const EMPTY_RELOAD := 2.45

# Aiming and handling.
const HIP_FOV := 76.0
const ADS_FOV := 60.0
const ADS_TIME := 0.22
const ADS_MOVE_SCALE := 0.62
const SPRINT_TO_FIRE := 0.2

# Spread is a random cone half-angle in degrees, separate from recoil.
const SPREAD_HIP := 1.5
const SPREAD_ADS := 0.22
const SPREAD_MOVE_HIP := 1.6
const SPREAD_MOVE_ADS := 0.45
const SPREAD_AIR := 3.0
const CROUCH_SPREAD_SCALE := 0.7
const BLOOM_PER_SHOT := 0.16
const BLOOM_MAX_HIP := 1.8
const BLOOM_MAX_ADS := 0.55
const BLOOM_RECOVERY := 4.5 # Degrees per second.

# Recoil is an authored, learnable pattern in degrees per shot. The first shot
# goes exactly where the player aims; the pattern index resets after a pause.
const RECOIL_VERTICAL := [0.0, 0.42, 0.46, 0.5, 0.52, 0.55, 0.55, 0.52, 0.5, 0.48]
const RECOIL_HORIZONTAL := [0.0, 0.06, 0.1, 0.12, -0.05, -0.12, 0.08, 0.14, -0.1, 0.05]
const RECOIL_TAIL_VERTICAL := 0.46
const RECOIL_TAIL_HORIZONTAL := 0.16
const RECOIL_ADS_SCALE := 0.7
const RECOIL_CROUCH_SCALE := 0.85
const RECOIL_RESET_TIME := 0.32
const RECOIL_RECOVERY := 7.5 # Fraction of the offset returned per second.


static func vertical_kick(shot_index: int) -> float:
	if shot_index < RECOIL_VERTICAL.size():
		return RECOIL_VERTICAL[shot_index]
	return RECOIL_TAIL_VERTICAL


static func horizontal_kick(shot_index: int, rng: RandomNumberGenerator) -> float:
	if shot_index < RECOIL_HORIZONTAL.size():
		return RECOIL_HORIZONTAL[shot_index]
	# Beyond the authored opening, a bounded wander keeps long sprays honest.
	return rng.randf_range(-RECOIL_TAIL_HORIZONTAL, RECOIL_TAIL_HORIZONTAL)


static func damage_at(distance: float, headshot: bool) -> float:
	var scale := 1.0
	if distance > FALLOFF_START:
		var t := clampf((distance - FALLOFF_START) / (FALLOFF_END - FALLOFF_START), 0.0, 1.0)
		scale = lerpf(1.0, FALLOFF_MIN_SCALE, t)
	return BODY_DAMAGE * scale * (HEAD_MULTIPLIER if headshot else 1.0)
