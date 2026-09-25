extends Node3D

const GUARD_SCRIPT := preload("res://scripts/actors/guard.gd")
const MIN_X := -64
const MAX_X := 64
const MIN_Z := -204
const MAX_Z := 204

var director: Node
var player: CharacterBody3D
var guards: Array = []
var _obstacles: Array[Rect2] = []
var _path_grid: AStarGrid2D
var _reinforcements_spawned := false
var _stone: StandardMaterial3D
var _dark_stone: StandardMaterial3D
var _plaster: StandardMaterial3D
var _earth: StandardMaterial3D
var _roof: StandardMaterial3D
var _wood: StandardMaterial3D
var _contact_blue: StandardMaterial3D
var _exit_green: StandardMaterial3D
var _mud_track: StandardMaterial3D


func setup(mission_director: Node, mission_player: CharacterBody3D) -> void:
	director = mission_director
	player = mission_player
	_build_materials()
	_build_town()
	_build_path_grid()
	_spawn_initial_guards()


func get_spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(-48.0, 0.08, 198.0))


func get_contact_position() -> Vector3:
	return Vector3(4.6, 3.27, -28.2)


func get_extraction_position() -> Vector3:
	return Vector3(44.0, 0.06, -198.0)


func get_guards() -> Array:
	return guards


func spawn_reinforcements() -> void:
	if _reinforcements_spawned:
		return
	_reinforcements_spawned = true
	# The north crossing lies between the residence and the scout. Both the
	# western rear lane and eastern yard remain open for evasion.
	_spawn_guard("North lane reinforcement", Vector3(12.0, 0.08, -34.7), [Vector3(12.0, 0.0, -34.7), Vector3(16.0, 0.0, -30.5)], false, Color(0.55, 0.35, 0.28))
	_spawn_guard("Courtyard reinforcement", Vector3(5.0, 0.08, -8.0), [Vector3(5.0, 0.0, -8.0), Vector3(-2.0, 0.0, -5.0), Vector3(4.0, 0.0, 2.0)], false, Color(0.55, 0.35, 0.28))
	_spawn_guard("Workers junction reinforcement", Vector3(15.0, 0.08, -105.0), [Vector3(15.0, 0.0, -105.0), Vector3(-16.0, 0.0, -105.0)], false, Color(0.55, 0.35, 0.28))
	_spawn_guard("North edge reinforcement", Vector3(44.0, 0.08, -165.0), [Vector3(44.0, 0.0, -165.0)], true, Color(0.55, 0.35, 0.28))


func get_ground_path(from_position: Vector3, to_position: Vector3) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if _path_grid == null:
		return result
	var from_cell := _nearest_open_cell(_world_to_cell(from_position))
	var to_cell := _nearest_open_cell(_world_to_cell(to_position))
	if from_cell.x < MIN_X or to_cell.x < MIN_X:
		return result
	for cell in _path_grid.get_id_path(from_cell, to_cell):
		result.append(Vector3(float(cell.x), 0.08, float(cell.y)))
	return result


func _build_materials() -> void:
	_stone = _material(Color(0.56, 0.56, 0.52))
	_dark_stone = _material(Color(0.36, 0.38, 0.36))
	_plaster = _material(Color(0.72, 0.70, 0.62))
	_earth = _material(Color(0.39, 0.37, 0.31))
	_roof = _material(Color(0.38, 0.31, 0.29))
	_wood = _material(Color(0.40, 0.28, 0.21))
	_contact_blue = _material(Color(0.24, 0.53, 0.72))
	_exit_green = _material(Color(0.32, 0.67, 0.43))
	# CC0 sample textures are recorded in docs/ASSET_PROVENANCE.md.
	_stone.albedo_texture = load("res://assets/vendor/polyhaven/materials/stone_wall_diff_1k.jpg")
	_stone.albedo_color = Color(0.87, 0.86, 0.82)
	_stone.uv1_triplanar = true
	_stone.uv1_world_triplanar = true
	_stone.uv1_scale = Vector3.ONE / 3.0
	_plaster.albedo_texture = load("res://assets/vendor/polyhaven/materials/plastered_stone_wall_diff_1k.jpg")
	_plaster.albedo_color = Color(0.93, 0.91, 0.84)
	_plaster.uv1_triplanar = true
	_plaster.uv1_world_triplanar = true
	_plaster.uv1_scale = Vector3.ONE / 3.0
	_mud_track = _material(Color(0.93, 0.91, 0.87))
	_mud_track.albedo_texture = load("res://assets/vendor/polyhaven/materials/muddy_tracks_diff_1k.jpg")
	_mud_track.uv1_triplanar = true
	_mud_track.uv1_world_triplanar = true
	_mud_track.uv1_scale = Vector3.ONE / 3.0


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material


func _build_town() -> void:
	_build_lighting()
	_box("Ground", Vector3(0, -0.25, 0), Vector3(130, 0.5, 410), _earth)
	_visual_box("Southern muddy track sample", Vector3(-47, 0.008, 190), Vector3(5.5, 0.018, 11), _mud_track)
	_box("West outer boundary", Vector3(-65, 2, 0), Vector3(1, 4, 410), _dark_stone, true)
	_box("East outer boundary", Vector3(65, 2, 0), Vector3(1, 4, 410), _dark_stone, true)
	_box("South outer boundary", Vector3(0, 2, 205), Vector3(130, 4, 1), _dark_stone, true)
	_box("North outer boundary", Vector3(0, 2, -205), Vector3(130, 4, 1), _dark_stone, true)
	_box("Core west edge", Vector3(-28, 2, 0), Vector3(1, 4, 86), _dark_stone, true)
	_box("Core east edge", Vector3(28, 2, 0), Vector3(1, 4, 86), _dark_stone, true)
	_build_southern_district()
	_build_northern_district()

	# Offset facades preserve a crooked street rather than a regular arena.
	_build_solid_house("Western homes", Vector3(-19, 0, 18), Vector3(9, 6, 15), _plaster)
	_build_solid_house("Western shops", Vector3(-19, 0, -6), Vector3(9, 6, 14), _stone)
	_build_solid_house("Eastern homes", Vector3(18, 0, 19), Vector3(10, 6, 14), _stone)
	_build_passage_house()
	_build_solid_house("North side store", Vector3(-19, 0, -31), Vector3(9, 5, 13), _dark_stone)
	# Detached short walls make the junction observable and cover meaningful.
	_box("South street wall", Vector3(-6.7, 0.65, 11), Vector3(4.2, 1.3, 0.6), _stone, true)
	_box("Courtyard west wall", Vector3(-9, 0.72, -1.5), Vector3(0.7, 1.44, 5.5), _stone, true)
	_box("Courtyard east wall", Vector3(9.2, 0.72, 4.0), Vector3(0.7, 1.44, 4.8), _stone, true)
	_box("Northern lane cover", Vector3(13.6, 0.72, -24.8), Vector3(3.6, 1.44, 0.7), _stone, true)
	_box("East yard rubble", Vector3(10.8, 0.48, 15), Vector3(2.2, 0.96, 2.0), _dark_stone, true)
	# A public pump makes the central crossing readable from both journeys.
	_box("Pump plinth", Vector3(0.2, 0.45, 1.8), Vector3(2.1, 0.9, 2.1), _dark_stone, true)
	_box("Pump column", Vector3(0.2, 1.45, 1.8), Vector3(0.42, 1.2, 0.42), _stone, true)
	_build_residence()
	_build_scout_shelter()
	_build_contact()
	_build_crate_sample()


func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	world.name = "Cloudy daylight"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color(0.42, 0.52, 0.59)
	atmosphere.sky_horizon_color = Color(0.72, 0.73, 0.69)
	atmosphere.ground_bottom_color = Color(0.34, 0.36, 0.35)
	sky.sky_material = atmosphere
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.52
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Soft afternoon sun"
	sun.rotation_degrees = Vector3(-50, -28, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(0.91, 0.91, 0.84)
	sun.shadow_enabled = true
	add_child(sun)


func _build_southern_district() -> void:
	# Five staggered plot bands form real 8–12 m fronts. Four connected
	# longitudinal lanes and their cross streets stay open for route choice.
	var bands := [
		{"z": 179.0, "depth": 16.0, "offset": 0.0},
		{"z": 145.0, "depth": 16.0, "offset": 1.0},
		{"z": 111.0, "depth": 16.0, "offset": -0.7},
		{"z": 77.0, "depth": 16.0, "offset": 0.6},
		{"z": 50.0, "depth": 10.0, "offset": -0.4},
	]
	var centers := [-59.0, -38.0, -27.0, -9.0, 2.0, 22.0, 32.0, 55.0]
	var widths := [10.0, 9.0, 9.0, 10.0, 10.0, 9.0, 9.0, 10.0]
	for row in range(bands.size()):
		var band: Dictionary = bands[row]
		for column in range(centers.size()):
			if row == 2 and column == 1:
				_build_west_service_passage()
				continue
			if row == 2 and column == 2:
				continue
			if row == 2 and column == 3:
				_build_south_workshop_passage()
				continue
			if row == 3 and column == 6:
				continue # Small yard breaks a continuous facade.
			var x: float = centers[column] + band.offset * (1.0 if column % 2 == 0 else -1.0)
			var z: float = band.z + (1.2 if column % 3 == 0 else -0.6)
			var height := 4.8 + float((row + column) % 3) * 0.55
			var material: Material = _plaster if (row + column) % 3 == 0 else _stone
			_build_solid_house("South plot %d-%d" % [row, column], Vector3(x, 0, z), Vector3(widths[column], height, band.depth), material)
	# At the northern seam the plot edge gives way to the old central street.
	# Modest low walls and a crate create sight breaks without closing lanes.
	_box("South workshop chimney", Vector3(27.0, 4.2, 146), Vector3(1.2, 8.4, 1.2), _dark_stone, true)
	_box("West water trough", Vector3(-59.0, 0.55, 94), Vector3(3.2, 1.1, 1.2), _stone, true)
	_box("Entry lane wall", Vector3(-52.5, 0.75, 192), Vector3(0.6, 1.5, 8.0), _stone, true)
	_sign("COURT  ↑", Vector3(-19, 2.55, 63), Color(0.91, 0.87, 0.69))
	_sign("WEST LANE  ←", Vector3(-20, 2.55, 130), Color(0.91, 0.87, 0.69))
	_sign("WORKSHOP  →", Vector3(12, 2.55, 130), Color(0.91, 0.87, 0.69))
	_sign("COURT  ↑", Vector3(-48, 2.55, 164), Color(0.91, 0.87, 0.69))
	_sign("COVERED ALLEY  ↑", Vector3(-32.5, 2.55, 130), Color(0.91, 0.87, 0.69))


func _build_west_service_passage() -> void:
	# Adjacent plot bays form a roofed 4.6 m lane between the western patrol
	# street and the sentry's middle street. The lane stays connected through
	# the neighboring plot rows, with open cross-street exits at z=164/62.
	_build_solid_house("West service passage bay A", Vector3(-38.3, 0, 111), Vector3(7.0, 5.0, 16), _stone)
	_build_solid_house("West service passage bay B", Vector3(-26.7, 0, 111), Vector3(7.0, 4.8, 16), _plaster)
	_box("West service passage roof", Vector3(-32.5, 4.8, 111), Vector3(4.6, 0.35, 16), _roof)
	_box("West service south lintel", Vector3(-32.5, 3.8, 119), Vector3(4.6, 1.6, 0.35), _stone)
	_box("West service north lintel", Vector3(-32.5, 3.8, 103), Vector3(4.6, 1.6, 0.35), _stone)


func _build_south_workshop_passage() -> void:
	# This roofed shortcut joins two cross streets through a damaged shop.
	_build_solid_house("South workshop west bay", Vector3(-12.5, 0, 111), Vector3(3.0, 5.0, 16), _plaster)
	_build_solid_house("South workshop east bay", Vector3(-5.2, 0, 111), Vector3(3.6, 4.5, 16), _stone)
	_box("South workshop passage roof", Vector3(-8.7, 4.8, 111), Vector3(4.6, 0.35, 16), _roof)
	_box("South workshop south lintel", Vector3(-8.7, 3.7, 119), Vector3(4.3, 1.5, 0.35), _plaster)
	_box("South workshop north lintel", Vector3(-8.7, 3.7, 103), Vector3(4.3, 1.5, 0.35), _plaster)


func _build_northern_district() -> void:
	# Workers' plots continue the town behind the contact. The three wider
	# north lanes are joined by cross streets; small alleys split some plots.
	var bands := [
		{"z": -60.0, "depth": 16.0, "offset": 0.0},
		{"z": -90.0, "depth": 16.0, "offset": -0.6},
		{"z": -120.0, "depth": 16.0, "offset": 0.7},
		{"z": -150.0, "depth": 16.0, "offset": -0.4},
		{"z": -180.0, "depth": 16.0, "offset": 0.3},
	]
	var centers := [-59.0, -40.0, -25.0, -7.0, 5.0, 25.0, 37.0, 57.0]
	var widths := [10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]
	for row in range(bands.size()):
		var band: Dictionary = bands[row]
		for column in range(centers.size()):
			if row == 2 and column == 4:
				_build_north_passage()
				continue
			if row == 3 and column == 1:
				continue # Open service yard beside the western lane.
			var x: float = centers[column] + band.offset * (1.0 if column % 2 == 0 else -1.0)
			var z: float = band.z + (0.9 if column % 3 == 1 else -0.7)
			var height := 4.5 + float((row * 2 + column) % 4) * 0.45
			var material: Material = _stone if (row + column) % 3 == 1 else _plaster
			_build_solid_house("North plot %d-%d" % [row, column], Vector3(x, 0, z), Vector3(widths[column], height, band.depth), material)
	# Building scale and a small public service structure identify crossings.
	_box("North store chimney", Vector3(59, 4.1, -91), Vector3(1.2, 8.2, 1.2), _dark_stone, true)
	_box("Workers trough", Vector3(-58, 0.55, -106), Vector3(3.2, 1.1, 1.2), _stone, true)
	_box("North lane cover", Vector3(18.0, 0.75, -136), Vector3(0.6, 1.5, 4.0), _stone, true)
	_box("West back-lane cover", Vector3(-44.0, 0.72, -164), Vector3(3.0, 1.44, 0.6), _stone, true)
	_sign("NORTH LANE  ↑", Vector3(15, 2.55, -45), Color(0.91, 0.87, 0.69))
	_sign("WEST LANE  ←", Vector3(-16, 2.55, -75), Color(0.91, 0.87, 0.69))
	_sign("WORKERS YARD  →", Vector3(15, 2.55, -105), Color(0.91, 0.87, 0.69))
	_sign("TOWN EDGE  ↑", Vector3(-16, 2.55, -135), Color(0.91, 0.87, 0.69))
	_sign("SCOUT SHELTER  →", Vector3(43, 2.55, -166), Color(0.69, 0.95, 0.72))


func _build_north_passage() -> void:
	# A modest roofed side route through one workers' building.
	_build_solid_house("North passage west bay", Vector3(1.8, 0, -120), Vector3(3.6, 4.7, 16), _stone)
	_build_solid_house("North passage east bay", Vector3(8.4, 0, -120), Vector3(3.2, 4.5, 16), _plaster)
	_box("North passage roof", Vector3(5.1, 4.7, -120), Vector3(3.5, 0.35, 16), _roof)
	_box("North passage south lintel", Vector3(5.1, 3.7, -112), Vector3(3.5, 1.6, 0.35), _stone)
	_box("North passage north lintel", Vector3(5.1, 3.7, -128), Vector3(3.5, 1.6, 0.35), _stone)


func _build_passage_house() -> void:
	# A roofed walk-through at the damaged eastern corner, x=17..20.
	# The two surviving bays occupy the old footprint without closing its
	# courtyard-to-north connection.
	_build_solid_house("Passage west bay", Vector3(15.75, 0, -7), Vector3(2.5, 4.8, 14), _plaster)
	_build_solid_house("Passage east bay", Vector3(21.75, 0, -7), Vector3(3.5, 4.8, 14), _stone)
	_box("Passage roof", Vector3(18.5, 4.75, -7), Vector3(3.7, 0.38, 14.2), _roof)
	_box("Passage south lintel", Vector3(18.5, 3.75, 0.1), Vector3(3.3, 1.8, 0.34), _plaster)
	_box("Passage north lintel", Vector3(18.5, 3.75, -14.1), Vector3(3.3, 1.8, 0.34), _plaster)


func _build_crate_sample() -> void:
	var source: PackedScene = load("res://assets/vendor/polyhaven/wooden_crate_02/wooden_crate_02_1k.gltf")
	if source == null:
		return
	var body := StaticBody3D.new()
	body.name = "CC0 crate sample"
	add_child(body)
	body.position = Vector3(-20.0, 0.0, 31.0)
	var crate := source.instantiate()
	body.add_child(crate)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.58, 0.48, 1.20)
	shape.shape = box
	shape.position.y = 0.23
	body.add_child(shape)


func _build_solid_house(label: String, base: Vector3, size: Vector3, wall_material: Material) -> void:
	_box(label, base + Vector3(0, size.y * 0.5, 0), size, wall_material, true)
	_box(label + " roof", base + Vector3(0, size.y + 0.2, 0), Vector3(size.x + 0.5, 0.4, size.z + 0.5), _roof)
	# Window/door tones are legibility cues on a rough stone mass.
	for side in [-1.0, 1.0]:
		_visual_box(label + " shutters", base + Vector3(side * (size.x * 0.5 + 0.015), 2.3, -2), Vector3(0.04, 1.4, 1.1), _wood)
	_obstacles.append(Rect2(Vector2(base.x - size.x * 0.5, base.z - size.z * 0.5), Vector2(size.x, size.z)))


func _build_residence() -> void:
	# Footprint x=-6..8, z=-32..-18. Door on southern facade x=-4.4..-1.
	_box("Residence west wall", Vector3(-6.2, 3.1, -25), Vector3(0.4, 6.2, 14.4), _stone)
	_box("Residence east wall", Vector3(8.2, 3.1, -25), Vector3(0.4, 6.2, 14.4), _stone)
	_box("Residence north wall", Vector3(1, 3.1, -32.2), Vector3(14.8, 6.2, 0.4), _stone)
	_box("Residence south left", Vector3(-5.3, 3.1, -17.8), Vector3(1.8, 6.2, 0.4), _plaster)
	_box("Residence south right", Vector3(3.5, 3.1, -17.8), Vector3(9.4, 6.2, 0.4), _plaster)
	_box("Residence lintel", Vector3(-2.5, 5.55, -17.8), Vector3(3.8, 1.3, 0.4), _stone)
	# The ramp is collision-backed. Its moderate slope works with ordinary
	# CharacterBody3D floor movement and avoids stair-step code in Player.
	var ramp_size := Vector3(3.4, 0.32, 7.08)
	var ramp := _box("Residence stairs ramp", Vector3(-2.55, 1.48, -21.3), ramp_size, _wood)
	ramp.rotation.x = atan2(3.0, 6.4)
	_box("Upper floor", Vector3(1.0, 3.0, -28.25), Vector3(14.0, 0.3, 7.5), _wood)
	_box("Residence ceiling", Vector3(1.0, 6.28, -25), Vector3(14.6, 0.3, 14.6), _roof)
	_box("Entry threshold", Vector3(-2.5, 0.04, -17.55), Vector3(3.7, 0.08, 0.75), _wood)
	_box("Contact desk", Vector3(3.6, 3.62, -29.4), Vector3(2.2, 0.7, 0.8), _wood, true)
	# Guard ground paths avoid house interiors; the player alone can use it.
	_obstacles.append(Rect2(Vector2(-6.45, -32.45), Vector2(14.9, 14.9)))


func _build_contact() -> void:
	var at := get_contact_position()
	_visual_box("Contact coat", at + Vector3(0, 0.95, 0), Vector3(0.65, 1.7, 0.5), _contact_blue)
	_sphere("Contact head", at + Vector3(0, 1.95, 0), 0.27, _plaster)
	_visual_box("Copied packet", Vector3(3.6, 4.02, -29.3), Vector3(0.45, 0.04, 0.34), _contact_blue)
	_sign("CONTACT", at + Vector3(0, 2.65, 0), Color(0.73, 0.88, 1.0))


func _build_scout_shelter() -> void:
	# Three walls and a canopy face west: a player may interact under fire.
	var at := get_extraction_position()
	_box("Shelter back", at + Vector3(4.0, 1.35, 0.2), Vector3(0.65, 2.7, 7.4), _dark_stone, true)
	_box("Shelter north wing", at + Vector3(1.7, 1.35, -3.3), Vector3(5.2, 2.7, 0.65), _dark_stone, true)
	_box("Shelter south wing", at + Vector3(2.6, 1.35, 3.7), Vector3(3.2, 2.7, 0.65), _dark_stone, true)
	_box("Shelter canopy", at + Vector3(1.8, 2.9, 0.2), Vector3(5.2, 0.25, 7.7), _wood)
	_visual_box("Scout coat", at + Vector3(0, 0.9, 0), Vector3(0.72, 1.65, 0.55), _exit_green)
	_sphere("Scout head", at + Vector3(0, 1.9, 0), 0.27, _plaster)
	_sign("SCOUT", at + Vector3(0, 2.6, 0), Color(0.68, 1.0, 0.75))


func _spawn_initial_guards() -> void:
	_spawn_guard("Courtyard patrol", Vector3(2.5, 0.08, 7.0), [Vector3(2.5, 0, 7), Vector3(5.4, 0, 0), Vector3(2.5, 0, -10), Vector3(-2.2, 0, -6)], false, Color(0.35, 0.41, 0.37))
	_spawn_guard("Residence sentry", Vector3(3.0, 0.08, -13.0), [Vector3(3, 0, -13)], true, Color(0.33, 0.40, 0.37))
	_spawn_guard("Eastern patrol", Vector3(10.0, 0.08, 24.0), [Vector3(10, 0, 24), Vector3(10, 0, 5), Vector3(11, 0, -13)], false, Color(0.37, 0.42, 0.38))
	_spawn_guard("South west patrol", Vector3(-48, 0.08, 150), [Vector3(-48, 0, 150), Vector3(-48, 0, 116), Vector3(-20, 0, 128), Vector3(-20, 0, 162)], false, Color(0.35, 0.41, 0.37))
	_spawn_guard("South middle sentry", Vector3(-19, 0.08, 92), [Vector3(-19, 0, 92)], true, Color(0.33, 0.40, 0.37))
	_spawn_guard("South east patrol", Vector3(12, 0.08, 150), [Vector3(12, 0, 150), Vector3(12, 0, 100), Vector3(12, 0, 69)], false, Color(0.37, 0.42, 0.38))
	_spawn_guard("North west patrol", Vector3(-48, 0.08, -90), [Vector3(-48, 0, -90), Vector3(-48, 0, -120), Vector3(-16, 0, -105), Vector3(-16, 0, -75)], false, Color(0.35, 0.41, 0.37))
	_spawn_guard("North east sentry", Vector3(15, 0.08, -150), [Vector3(15, 0, -150)], true, Color(0.33, 0.40, 0.37))


func _spawn_guard(label: String, position: Vector3, points: Array[Vector3], sentry: bool, color: Color) -> void:
	var guard := CharacterBody3D.new()
	guard.set_script(GUARD_SCRIPT)
	guard.name = label
	add_child(guard)
	guard.global_position = position
	guard.setup(self, director, player, points, sentry, color)
	guards.append(guard)


func _box(label: String, center: Vector3, size: Vector3, material: Material, navigation_blocker: bool = false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	add_child(body)
	body.position = center
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if navigation_blocker:
		_obstacles.append(Rect2(Vector2(center.x - size.x * 0.5, center.z - size.z * 0.5), Vector2(size.x, size.z)))
	return body


func _visual_box(label: String, center: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	add_child(visual)
	visual.position = center


func _sphere(label: String, at: Vector3, radius: float, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	visual.mesh = mesh
	visual.material_override = material
	add_child(visual)
	visual.position = at


func _sign(label: String, at: Vector3, color: Color) -> void:
	var text := Label3D.new()
	text.text = label
	text.name = label + " marker"
	text.font_size = 48
	text.pixel_size = 0.003
	text.modulate = color
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.no_depth_test = true
	add_child(text)
	text.position = at


func _build_path_grid() -> void:
	_path_grid = AStarGrid2D.new()
	_path_grid.region = Rect2i(MIN_X, MIN_Z, MAX_X - MIN_X + 1, MAX_Z - MIN_Z + 1)
	_path_grid.cell_size = Vector2.ONE
	_path_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_path_grid.update()
	for x in range(MIN_X, MAX_X + 1):
		for z in range(MIN_Z, MAX_Z + 1):
			var point := Vector2(float(x), float(z))
			for obstacle in _obstacles:
				if obstacle.grow(0.55).has_point(point):
					_path_grid.set_point_solid(Vector2i(x, z), true)
					break


func _world_to_cell(at: Vector3) -> Vector2i:
	return Vector2i(clampi(roundi(at.x), MIN_X, MAX_X), clampi(roundi(at.z), MIN_Z, MAX_Z))


func _nearest_open_cell(cell: Vector2i) -> Vector2i:
	if not _path_grid.is_point_solid(cell):
		return cell
	for radius in range(1, 14):
		for x in range(cell.x - radius, cell.x + radius + 1):
			for z in range(cell.y - radius, cell.y + radius + 1):
				var candidate := Vector2i(x, z)
				if _path_grid.is_in_boundsv(candidate) and not _path_grid.is_point_solid(candidate):
					return candidate
	return Vector2i(MIN_X - 1, MIN_Z - 1)
