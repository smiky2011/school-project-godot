extends RefCounted

# Small procedural textures for combat effects. Generated once and cached, so
# no external image file or license record is needed for them.

static var _cache: Dictionary = {}


static func get_texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var image: Image
	match key:
		"flash_star":
			image = _flash_star()
		"flash_side":
			image = _flash_side()
		"soft_puff":
			image = _soft_puff()
		"bullet_hole":
			image = _bullet_hole(false)
		"bullet_hole_wood":
			image = _bullet_hole(true)
		"scorch":
			image = _scorch()
		"tracer":
			image = _tracer()
		_:
			image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture


static func _hash_noise(x: int, y: int, seed_value: int) -> float:
	var h := (x * 374761393 + y * 668265263 + seed_value * 2147483647) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0


static func _value_noise(u: float, v: float, scale: float, seed_value: int) -> float:
	var x := u * scale
	var y := v * scale
	var x0 := int(floor(x))
	var y0 := int(floor(y))
	var fx := x - x0
	var fy := y - y0
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _hash_noise(x0, y0, seed_value)
	var b := _hash_noise(x0 + 1, y0, seed_value)
	var c := _hash_noise(x0, y0 + 1, seed_value)
	var d := _hash_noise(x0 + 1, y0 + 1, seed_value)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


static func _flash_star() -> Image:
	var size := 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rays := [0.1, 1.35, 2.2, 3.3, 4.4, 5.35]
	for y in range(size):
		for x in range(size):
			var p := Vector2(x + 0.5, y + 0.5) / size * 2.0 - Vector2.ONE
			var r := p.length()
			var angle := atan2(p.y, p.x)
			var ray := 0.0
			for a in rays:
				var diff := absf(wrapf(angle - float(a), -PI, PI))
				ray = maxf(ray, pow(maxf(0.0, 1.0 - diff / 0.22), 3.0) * maxf(0.0, 1.0 - r))
			var core := pow(maxf(0.0, 1.0 - r / 0.42), 2.2)
			var v := clampf(core * 1.2 + ray * 0.9, 0.0, 1.0)
			# Premultiplied: additive blending ignores alpha, so dark = invisible.
			image.set_pixel(x, y, Color(v, (0.82 + 0.18 * core) * v, (0.52 + 0.45 * core) * v, v))
	return image


static func _flash_side() -> Image:
	var w := 128
	var h := 64
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var u := (x + 0.5) / w
			var v := absf((y + 0.5) / h * 2.0 - 1.0)
			var width := 0.15 + 0.85 * sin(PI * clampf(u * 1.2, 0.0, 1.0))
			var n := _value_noise(u, v, 9.0, 3)
			var a := clampf((1.0 - v / maxf(width, 0.01)) * (1.0 - u) * (0.6 + 0.6 * n), 0.0, 1.0)
			image.set_pixel(x, y, Color(a, 0.78 * a, 0.45 * a, a))
	return image


static func _soft_puff() -> Image:
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var p := Vector2(x + 0.5, y + 0.5) / size * 2.0 - Vector2.ONE
			var r := p.length()
			var n := _value_noise(float(x) / size, float(y) / size, 5.0, 7) * 0.6 + _value_noise(float(x) / size, float(y) / size, 11.0, 9) * 0.4
			var a := clampf((1.0 - r) * 1.6 - 0.2 + (n - 0.5) * 0.7, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, a * a))
	return image


static func _bullet_hole(wood: bool) -> Image:
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var p := Vector2(x + 0.5, y + 0.5) / size * 2.0 - Vector2.ONE
			var r := p.length()
			var angle := atan2(p.y, p.x)
			var jag := _value_noise(angle / TAU + 0.5, 0.3, 12.0, 21) * 0.18
			var hole := 1.0 - smoothstep(0.14, 0.2, r - jag * 0.4)
			var chip := (1.0 - smoothstep(0.3 + jag, 0.62 + jag, r)) * (0.55 + 0.45 * _value_noise(float(x) / size, float(y) / size, 14.0, 5))
			var color: Color
			if wood:
				color = Color(0.07, 0.05, 0.035).lerp(Color(0.62, 0.48, 0.32), clampf(chip - hole, 0.0, 1.0) * 0.8)
			else:
				color = Color(0.05, 0.05, 0.05).lerp(Color(0.78, 0.76, 0.72), clampf(chip - hole, 0.0, 1.0) * 0.7)
			var alpha := clampf(maxf(hole, chip * 0.75), 0.0, 1.0)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	return image


static func _scorch() -> Image:
	var size := 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var p := Vector2(x + 0.5, y + 0.5) / size * 2.0 - Vector2.ONE
			var r := p.length()
			var n := _value_noise(float(x) / size, float(y) / size, 6.0, 13)
			var a := clampf((1.0 - r) * 1.3 + (n - 0.5) * 0.8 - 0.1, 0.0, 1.0)
			image.set_pixel(x, y, Color(0.04, 0.035, 0.03, a * 0.85))
	return image


static func _tracer() -> Image:
	var w := 64
	var h := 8
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var u := (x + 0.5) / w
			var v := absf((y + 0.5) / h * 2.0 - 1.0)
			var a := (1.0 - v) * (1.0 - v) * pow(u, 1.5)
			image.set_pixel(x, y, Color(a, 0.9 * a, 0.7 * a, a))
	return image
