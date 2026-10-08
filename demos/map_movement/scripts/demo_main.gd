extends Node3D

const DEMO_MAP := preload("res://scripts/demo_map.gd")
const DEMO_PLAYER := preload("res://scripts/demo_player.gd")

var town: Node3D
var player: CharacterBody3D


func _ready() -> void:
	town = DEMO_MAP.new()
	town.name = "Town"
	add_child(town)
	town.build()

	player = DEMO_PLAYER.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.08, 34.0)
	add_child(player)
	_build_controls_overlay()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.controls_active = false
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.controls_active = true
		get_viewport().set_input_as_handled()


func _build_controls_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Controls"
	add_child(layer)
	var label := Label.new()
	label.text = "TOWN MAP + MOVEMENT   WASD move   Mouse look   Shift sprint   Space jump   Esc release   Click recapture"
	label.position = Vector2(18, 16)
	label.add_theme_color_override("font_color", Color(0.97, 0.96, 0.90))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)
