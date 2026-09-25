extends Node3D

const LevelScript = preload("res://scripts/world/town_level.gd")
const PlayerScript = preload("res://scripts/player/player.gd")
const DirectorScript = preload("res://scripts/core/mission_director.gd")
const HudScript = preload("res://scripts/ui/hud.gd")

var level
var player
var director
var hud
var _story_audio: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()
	level = LevelScript.new()
	level.name = "TownLevel"
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)
	player = PlayerScript.new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	director = DirectorScript.new()
	director.name = "MissionDirector"
	director.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(director)
	director.setup(player, level)
	player.setup(director)
	level.setup(director, player)
	player.global_transform = level.get_spawn_transform()
	director.mission_finished.connect(_on_mission_finished)
	director.story_cue.connect(_on_story_cue)
	hud = HudScript.new()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	hud.setup(self, director, player)
	hud.show_briefing()
	_story_audio = AudioStreamPlayer.new()
	_story_audio.process_mode = Node.PROCESS_MODE_PAUSABLE
	_story_audio.volume_db = -15.0
	add_child(_story_audio)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func start_mission() -> void:
	get_tree().paused = false
	director.start_mission()
	player.set_controls_enabled(true)
	hud.show_gameplay()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func resume_mission() -> void:
	get_tree().paused = false
	hud.show_gameplay()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func retry_mission() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()


func quit_game() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and not event.is_echo() and director != null and director.is_active():
		if get_tree().paused:
			resume_mission()
		else:
			get_tree().paused = true
			hud.show_pause()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()


func _on_mission_finished(success: bool) -> void:
	player.set_controls_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_result(success)


func _on_story_cue(kind: String) -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var samples := PackedByteArray()
	var length := 11025 if kind == "arrival" else 15435
	var frequency := 75.0 if kind == "arrival" else 620.0
	for i in range(length):
		var t := float(i) / 22050.0
		var envelope := minf(1.0, t * 20.0) * minf(1.0, (float(length - i) / 22050.0) * 8.0)
		var modulated := sin(TAU * frequency * t) * (0.7 if kind == "arrival" else 0.24)
		var radio_static := sin(TAU * 3900.0 * t) * 0.06 if kind == "radio" else 0.0
		var value := int(clampf((modulated + radio_static) * envelope, -1.0, 1.0) * 17000.0)
		samples.append(value & 255)
		samples.append((value >> 8) & 255)
	wav.data = samples
	_story_audio.stream = wav
	_story_audio.play()


func _register_inputs() -> void:
	_bind_key("move_forward", KEY_W)
	_bind_key("move_back", KEY_S)
	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)
	_bind_key("look_left", KEY_LEFT)
	_bind_key("look_right", KEY_RIGHT)
	_bind_key("look_up", KEY_UP)
	_bind_key("look_down", KEY_DOWN)
	_bind_key("jump", KEY_SPACE)
	_bind_key("sprint", KEY_SHIFT)
	_bind_key("hold_crouch", KEY_CTRL)
	_bind_key("toggle_crouch", KEY_C)
	_bind_key("reload", KEY_R)
	_bind_key("interact", KEY_E)
	_bind_key("stealth_kill", KEY_F)
	_bind_key("pause_game", KEY_ESCAPE)
	_bind_mouse("fire", MOUSE_BUTTON_LEFT)
	_add_key("fire", KEY_G)
	_bind_mouse("aim", MOUSE_BUTTON_RIGHT)
	_add_key("aim", KEY_H)


func _bind_key(action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	_add_key(action, key)


func _add_key(action: StringName, key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


func _bind_mouse(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
