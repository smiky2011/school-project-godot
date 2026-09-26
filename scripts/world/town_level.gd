extends Node3D

const GUARD_SCRIPT := preload("res://scripts/actors/guard.gd")
const TOWN_PRESENTATION := preload("res://scripts/world/town_presentation.gd")
const COMBAT_FX := preload("res://scripts/fx/combat_fx.gd")
const CONTACT_VISUAL: PackedScene = preload("res://assets/vendor/character_visual/makehuman/runtime/contact_idle.glb")
const SCOUT_VISUAL: PackedScene = preload("res://assets/vendor/character_visual/makehuman/runtime/scout_idle.glb")
const CONTACT_DESK_SURFACE_Y := 3.825
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
var _slate_roof: StandardMaterial3D
var _wood: StandardMaterial3D
var _glass: StandardMaterial3D
var _contact_blue: StandardMaterial3D
var _mud_track: StandardMaterial3D


func setup(mission_director: Node, mission_player: CharacterBody3D) -> void:
	director = mission_director
	player = mission_player
	var fx := COMBAT_FX.new()
	add_child(fx)
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


func get_ground_surface(at: Vector3) -> String:
	# Footstep surface: timber upstairs, setts on the paved streets, else mud.
	if at.y > 0.6:
		return "wood"
	if absf(at.x - 12.0) < 3.1 or absf(at.x + 48.0) < 2.9:
		return "stone"
	if absf(at.x + 3.0) < 15.5 and (absf(at.z - 34.0) < 2.8 or absf(at.z + 44.0) < 2.6):
		return "stone"
	return "mud"


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
	_slate_roof = _material(Color(0.68, 0.71, 0.73))
	_slate_roof.albedo_texture = load("res://assets/environment/textures/slate_base.png")
	_slate_roof.normal_enabled = true
	_slate_roof.normal_texture = load("res://assets/environment/textures/slate_normal.png")
	_slate_roof.roughness_texture = load("res://assets/environment/textures/slate_rough.png")
	_slate_roof.uv1_triplanar = true
	_slate_roof.uv1_world_triplanar = true
	_slate_roof.uv1_scale = Vector3.ONE / 1.5
	_wood = _material(Color(0.40, 0.28, 0.21))
	_wood.albedo_texture = load("res://assets/environment/textures/oak_base.jpg")
	_wood.albedo_color = Color(0.82, 0.78, 0.72)
	_wood.normal_enabled = true
	_wood.normal_texture = load("res://assets/environment/textures/oak_normal.png")
	_wood.roughness_texture = load("res://assets/environment/textures/oak_rough.png")
	_wood.uv1_triplanar = true
	_wood.uv1_world_triplanar = true
	_wood.uv1_scale = Vector3.ONE / 2.0
	_glass = _material(Color(0.19, 0.23, 0.25, 0.72))
	_glass.roughness = 0.27
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_contact_blue = _material(Color(0.24, 0.53, 0.72))
	# CC0 sample textures are recorded in docs/ASSET_PROVENANCE.md.
	_stone.albedo_texture = load("res://assets/vendor/polyhaven/materials/stone_wall_diff_1k.jpg")
	_stone.albedo_color = Color(0.87, 0.86, 0.82)
	_stone.uv1_triplanar = true
	_stone.uv1_world_triplanar = true
	_stone.uv1_scale = Vector3.ONE / 3.0
	_dark_stone.albedo_texture = load("res://assets/environment/textures/stone_base.jpg")
	_dark_stone.albedo_color = Color(0.70, 0.71, 0.68)
	_dark_stone.normal_enabled = true
	_dark_stone.normal_texture = load("res://assets/environment/textures/stone_normal.png")
	_dark_stone.normal_scale = 0.55
	_dark_stone.roughness_texture = load("res://assets/environment/textures/stone_rough.png")
	_dark_stone.uv1_triplanar = true
	_dark_stone.uv1_world_triplanar = true
	_dark_stone.uv1_scale = Vector3.ONE / 2.4
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
	TOWN_PRESENTATION.add_street_surfaces(self, _obstacles)
	_visual_box("Southern muddy track sample", Vector3(-47, 0.008, 190), Vector3(5.5, 0.018, 11), _mud_track)
	_box("West outer boundary", Vector3(-65, 2, 0), Vector3(1, 4, 410), _dark_stone, true)
	_box("East outer boundary", Vector3(65, 2, 0), Vector3(1, 4, 410), _dark_stone, true)
	_box("South outer boundary", Vector3(0, 2, 205), Vector3(130, 4, 1), _dark_stone, true)
	_box("North outer boundary", Vector3(0, 2, -205), Vector3(130, 4, 1), _dark_stone, true)
	for x in [-65.0, 65.0]:
		_visual_box("Boundary stone coping", Vector3(x, 4.04, 0), Vector3(1.25, 0.16, 410), _stone)
		_visual_box("Boundary foot course", Vector3(x, 0.15, 0), Vector3(1.10, 0.3, 410), _stone)
	for z in [-205.0, 205.0]:
		_visual_box("Boundary stone coping", Vector3(0, 4.04, z), Vector3(130, 0.16, 1.25), _stone)
		_visual_box("Boundary foot course", Vector3(0, 0.15, z), Vector3(130, 0.3, 1.10), _stone)
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
	var atmosphere := PanoramaSkyMaterial.new()
	atmosphere.panorama = load("res://assets/vendor/environment_visual/polyhaven/overcast_soil_puresky/overcast_soil_puresky_1k.hdr")
	atmosphere.energy_multiplier = 0.28
	sky.sky_material = atmosphere
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.48
	environment.ssao_enabled = true
	environment.ssao_radius = 1.45
	environment.ssao_intensity = 1.1
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Soft afternoon sun"
	sun.rotation_degrees = Vector3(-50, -28, 0)
	sun.light_energy = 0.82
	sun.light_color = Color(0.88, 0.90, 0.91)
	sun.light_angular_distance = 0.8
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
	var plaster := wall_material == _plaster
	var shell_added: bool = TOWN_PRESENTATION.add_plot_shell(self, label, base, size, plaster)
	# Preserve the human-sized doors/windows: shell height is fixed in metres.
	# The old rectangular collision still owns the same horizontal footprint.
	var body_height: float = TOWN_PRESENTATION.shell_eaves_height(plaster, size) if shell_added else size.y
	var mass := _box(label, base + Vector3(0, body_height * 0.5, 0), Vector3(size.x, body_height, size.z), wall_material, true)
	if shell_added:
		for child in mass.get_children():
			if child is MeshInstance3D:
				child.visible = false
		var roof_body := _box(label + " legacy roof collision", base + Vector3(0, body_height + 0.2, 0), Vector3(size.x + 0.5, 0.4, size.z + 0.5), _roof)
		for child in roof_body.get_children():
			if child is MeshInstance3D:
				child.visible = false
	else:
		_box(label + " roof", base + Vector3(0, size.y + 0.2, 0), Vector3(size.x + 0.5, 0.4, size.z + 0.5), _roof)
	# Window/door tones are legibility cues on a rough stone mass.
	if not shell_added:
		for side in [-1.0, 1.0]:
			_visual_box(label + " shutters", base + Vector3(side * (size.x * 0.5 + 0.015), 2.3, -2), Vector3(0.04, 1.4, 1.1), _wood)
	_obstacles.append(Rect2(Vector2(base.x - size.x * 0.5, base.z - size.z * 0.5), Vector2(size.x, size.z)))


func _build_residence() -> void:
	# Footprint x=-6..8, z=-32..-18. Door on southern facade x=-4.4..-1.
	_box("Residence west wall", Vector3(-6.2, 3.1, -25), Vector3(0.4, 6.2, 14.4), _stone)
	_box("Residence east wall", Vector3(8.2, 3.1, -25), Vector3(0.4, 6.2, 14.4), _stone)
	_box("Residence north wall", Vector3(1, 3.1, -32.2), Vector3(14.8, 6.2, 0.4), _stone)
	_box("Residence south left", Vector3(-5.3, 3.1, -17.8), Vector3(1.8, 6.2, 0.4), _plaster)
	# The two south windows admit daylight and have physical glass. The door
	# opening at x=-4.4..-1 remains exactly as the mission route requires.
	for span in [[-1.2, 0.4], [1.7, 4.65], [5.95, 8.2]]:
		_box("Residence south pier", Vector3((span[0]+span[1])*0.5, 3.1, -17.8),
			Vector3(span[1]-span[0], 6.2, 0.4), _plaster)
	for span in [[0.4, 1.7], [4.65, 5.95]]:
		var cx: float = (span[0]+span[1])*0.5
		for band in [[0.0, 1.25], [2.45, 4.0], [5.2, 6.2]]:
			_box("Residence window wall band", Vector3(cx, (band[0]+band[1])*0.5, -17.8),
				Vector3(span[1]-span[0], band[1]-band[0], 0.4), _plaster)
		for cy in [1.85, 4.6]:
			_box("Residence window glass", Vector3(cx, cy, -17.85), Vector3(1.28, 1.16, 0.07), _glass)
			_visual_box("Residence dressed stone sill", Vector3(cx, cy-0.68, -17.55), Vector3(1.58, 0.12, 0.31), _stone)
			_visual_box("Residence dressed stone lintel", Vector3(cx, cy+0.68, -17.59), Vector3(1.55, 0.15, 0.23), _stone)
			for side in [-1.0, 1.0]:
				_visual_box("Residence window jamb", Vector3(cx+side*0.66, cy, -17.58), Vector3(0.11, 1.22, 0.20), _stone)
			_visual_box("Residence timber mullion", Vector3(cx, cy, -17.61), Vector3(0.055, 1.13, 0.08), _wood)
			_visual_box("Residence timber transom", Vector3(cx, cy, -17.61), Vector3(1.23, 0.055, 0.08), _wood)
	_box("Residence lintel", Vector3(-2.5, 5.55, -17.8), Vector3(3.8, 1.3, 0.4), _stone)
	# The ramp is collision-backed. Its moderate slope works with ordinary
	# CharacterBody3D floor movement and avoids stair-step code in Player.
	var ramp_size := Vector3(3.4, 0.32, 7.08)
	var ramp := _box("Residence stairs ramp", Vector3(-2.55, 1.48, -21.3), ramp_size, _wood)
	ramp.rotation.x = atan2(3.0, 6.4)
	# Thirteen horizontal timber treads show where each step is. They are
	# visual-only: the smooth collision ramp remains the traversable surface.
	for step in range(13):
		_visual_box("Residence timber stair tread", Vector3(-2.55, 0.13 + float(step)*0.245, -17.94-float(step)*0.535),
			Vector3(3.18, 0.045, 0.51), _wood)
	_box("Upper floor", Vector3(1.0, 3.0, -28.25), Vector3(14.0, 0.3, 7.5), _wood)
	_add_contact_floor_plank_seams()
	_box("Residence ceiling", Vector3(1.0, 6.28, -25), Vector3(14.6, 0.3, 14.6), _roof)
	# Plastered interior faces, a timber wall band, and a pitched exterior
	# roof make this contact space legible without moving its route geometry.
	for x in [-5.96, 7.96]:
		_visual_box("Interior plaster", Vector3(x, 3.1, -25), Vector3(0.045, 6.1, 13.8), _plaster)
		_visual_box("Interior timber dado", Vector3(x, 0.76, -25), Vector3(0.09, 0.14, 13.6), _wood)
	var room_light := OmniLight3D.new()
	room_light.name = "Window-bounce contact room light"
	room_light.position = Vector3(0.5, 4.9, -24.0)
	room_light.light_color = Color(0.81, 0.84, 0.86)
	room_light.light_energy = 2.0
	room_light.omni_range = 11.0
	room_light.shadow_enabled = false
	add_child(room_light)
	for roof_spec in [[-2.62, 0.257], [4.62, -0.257]]:
		var roof_plane := MeshInstance3D.new()
		roof_plane.name = "Residence pitched slate roof"
		var roof_mesh := BoxMesh.new()
		roof_mesh.size = Vector3(7.52, 0.22, 14.9)
		roof_plane.mesh = roof_mesh
		roof_plane.material_override = _slate_roof
		roof_plane.position = Vector3(roof_spec[0], 7.24, -25)
		roof_plane.rotation.z = roof_spec[1]
		add_child(roof_plane)
	_add_residence_gables()
	_box("Entry threshold", Vector3(-2.5, 0.04, -17.55), Vector3(3.7, 0.08, 0.75), _wood)
	_box("Contact desk top", Vector3(3.6, CONTACT_DESK_SURFACE_Y-0.065, -29.4), Vector3(2.2, 0.13, 0.83), _wood, true)
	for x in [2.63, 4.57]:
		for z in [-29.72, -29.08]:
			_visual_box("Contact desk timber leg", Vector3(x, 3.43, z), Vector3(0.12, 0.64, 0.12), _wood)
	_visual_box("Contact chair seat", Vector3(5.34, 3.48, -30.28), Vector3(0.65, 0.09, 0.62), _wood)
	_visual_box("Contact chair back", Vector3(5.34, 3.85, -30.61), Vector3(0.65, 0.79, 0.09), _wood)
	for x in [5.08, 5.60]:
		for z in [-30.50, -30.05]:
			_visual_box("Contact chair leg", Vector3(x, 3.26, z), Vector3(0.07, 0.42, 0.07), _wood)
	# Guard ground paths avoid house interiors; the player alone can use it.
	_obstacles.append(Rect2(Vector2(-6.45, -32.45), Vector2(14.9, 14.9)))


func _add_contact_floor_plank_seams() -> void:
	# Thin visible joints break the tiled oak noise into human-scale boards.
	# One MultiMesh keeps the whole upper floor to a single additional draw.
	var seam_material := _material(Color(0.15, 0.11, 0.09))
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.012, 0.005, 7.47)
	mesh.material = seam_material
	var seams := MultiMesh.new()
	seams.transform_format = MultiMesh.TRANSFORM_3D
	seams.mesh = mesh
	seams.instance_count = 55
	for i in range(55):
		seams.set_instance_transform(i, Transform3D(Basis.IDENTITY,
			Vector3(-5.75 + float(i) * 0.245, 3.153, -28.25)))
	var visual := MultiMeshInstance3D.new()
	visual.name = "Contact room oak plank joints"
	visual.multimesh = seams
	add_child(visual)


func _add_residence_gables() -> void:
	for side in [1.0, -1.0]:
		var z: float = -17.8 if side > 0.0 else -32.2
		var points := [Vector3(-6.2, 6.19, z), Vector3(8.2, 6.19, z), Vector3(1.0, 8.11, z)]
		# SurfaceTool's outward front faces use clockwise winding in Godot.
		if side > 0.0:
			points.reverse()
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(_plaster if side > 0.0 else _stone)
		for point in points:
			surface.set_normal(Vector3(0, 0, side))
			surface.set_uv(Vector2(point.x / 2.4, point.y / 2.4))
			surface.add_vertex(point)
		var gable := MeshInstance3D.new()
		gable.name = "Residence plaster gable" if side > 0.0 else "Residence stone gable"
		gable.mesh = surface.commit()
		add_child(gable)


func _build_contact() -> void:
	var at := get_contact_position()
	var contact_model := CONTACT_VISUAL.instantiate()
	contact_model.name = "Contact civilian visual"
	contact_model.position = Vector3(at.x, 3.15, at.z)
	add_child(contact_model)
	_visual_box("Copied packet", Vector3(3.6, CONTACT_DESK_SURFACE_Y+0.022, -29.3), Vector3(0.45, 0.04, 0.34), _contact_blue)
	_sign("CONTACT", at + Vector3(0, 2.65, 0), Color(0.73, 0.88, 1.0))


func _build_scout_shelter() -> void:
	# Three walls and a canopy face west: a player may interact under fire.
	var at := get_extraction_position()
	_box("Shelter back", at + Vector3(4.0, 1.35, 0.2), Vector3(0.65, 2.7, 7.4), _dark_stone, true)
	_box("Shelter north wing", at + Vector3(1.7, 1.35, -3.3), Vector3(5.2, 2.7, 0.65), _dark_stone, true)
	_box("Shelter south wing", at + Vector3(2.6, 1.35, 3.7), Vector3(3.2, 2.7, 0.65), _dark_stone, true)
	var canopy := _box("Shelter canopy collision", at + Vector3(1.8, 2.9, 0.2), Vector3(5.2, 0.25, 7.7), _wood)
	for child in canopy.get_children():
		if child is MeshInstance3D:
			child.visible = false
	var roof_visual := MeshInstance3D.new()
	roof_visual.name = "Scout shelter low slate roof"
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(5.5, 0.18, 8.0)
	roof_visual.mesh = roof_mesh
	roof_visual.material_override = _slate_roof
	roof_visual.position = at + Vector3(1.8, 3.15, 0.2)
	roof_visual.rotation.z = 0.06
	add_child(roof_visual)
	for z in [-3.1, 3.4]:
		_box("Shelter timber support", at + Vector3(-0.8, 1.38, z), Vector3(0.16, 2.76, 0.18), _wood, true)
		_visual_box("Shelter eave brace", at + Vector3(1.75, 2.70, z), Vector3(5.1, 0.16, 0.13), _wood)
	var scout_model := SCOUT_VISUAL.instantiate()
	scout_model.name = "Scout field visual"
	# The interaction anchor is 6 cm above ground; the static model's shoe
	# soles are at its origin and rest on the actual ground plane instead.
	scout_model.position = Vector3(at.x, 0.0, at.z)
	add_child(scout_model)
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
	# Impact effects read this to pick dust, chips and sound.
	if material == _wood or material == _roof:
		body.set_meta("surface", "wood")
	elif material == _earth:
		body.set_meta("surface", "dirt")
	elif material == _plaster:
		body.set_meta("surface", "plaster")
	else:
		body.set_meta("surface", "stone")
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
