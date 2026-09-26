extends CanvasLayer

var main
var director
var player
var _mode := "briefing"
var _game_layer: Control
var _overlay: ColorRect
var _menu_content: VBoxContainer
var _objective_title: Label
var _objective_detail: Label
var _health: Label
var _ammo: Label
var _awareness: Label
var _noise: Label
var _interaction: Label
var _subtitle: Label
var _crosshair: Label
var _progress: ProgressBar
var _damage_tint: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game_layer = Control.new()
	_game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_game_layer)
	_build_gameplay()
	_build_overlay()


func setup(mission_main, mission_director, mission_player) -> void:
	main = mission_main
	director = mission_director
	player = mission_player


func show_briefing() -> void:
	_mode = "briefing"
	_game_layer.visible = false
	_show_menu("ORDERS / 1944", "A local contact holds copied counterattack plans upstairs in the requisitioned residence. Reach them quietly, then carry the packet to your fellow scout beyond town.\n\nThe town has several routes. Watch the guards' ground vision cones; suspicion can fade after you break sight. Combat is optional. Your contact needs a few safe seconds. Extraction needs one E press, even if guards remain nearby.", [
		["BEGIN MISSION", Callable(main, "start_mission")],
		["QUIT", Callable(main, "quit_game")]
	])


func show_gameplay() -> void:
	_mode = "gameplay"
	_game_layer.visible = true
	_overlay.visible = false


func show_pause() -> void:
	_mode = "pause"
	_game_layer.visible = true
	_show_menu("MISSION PAUSED", "WASD move · mouse or arrow keys look · Shift sprint · Ctrl hold crouch · C toggle crouch · Space jump\n\nLeft click or G fire · right click or H aim · R reload · F quiet rear takedown\n\nHold E at the upstairs contact until the exchange finishes. Press E once at extraction. Esc pauses or resumes. Returning to the mission captures the pointer.", [
		["RESUME", Callable(main, "resume_mission")],
		["RESTART MISSION", Callable(main, "retry_mission")],
		["QUIT", Callable(main, "quit_game")]
	])


func show_result(success: bool) -> void:
	_mode = "result"
	_game_layer.visible = false
	var elapsed := int(director.mission_time)
	var time_text := "%02d:%02d" % [elapsed / 60, elapsed % 60]
	if success:
		_show_menu("PACKET DELIVERED", "The fellow scout has the copied plans. Returning personnel found the cut stair seal and the radio order locked down the town. The contact and the original papers remain in place.\n\nTime  %s     Guards killed  %d\n\n%s" % [time_text, director.kills, "No-kill completion" if director.kills == 0 else "Mission complete"], [
			["PLAY AGAIN", Callable(main, "retry_mission")],
			["QUIT", Callable(main, "quit_game")]
		])
	else:
		_show_menu("MISSION FAILED", "You were killed before the packet could be delivered. A retry starts the whole operation: guards, contact, ammunition and alarm all return to their initial state.\n\nTime  %s     Guards killed  %d" % [time_text, director.kills], [
			["RETRY MISSION", Callable(main, "retry_mission")],
			["QUIT", Callable(main, "quit_game")]
		])


func _process(_delta: float) -> void:
	if _mode != "gameplay" or director == null or player == null:
		return
	var target: Vector3 = director.get_objective_position()
	var flat := Vector3(target.x - player.global_position.x, 0.0, target.z - player.global_position.z)
	var relative: Vector3 = player.global_transform.basis.inverse() * flat
	var angle := atan2(relative.x, -relative.z)
	var bearing := "AHEAD"
	if angle > PI * 0.75 or angle < -PI * 0.75:
		bearing = "BEHIND"
	elif angle > PI * 0.25:
		bearing = "RIGHT"
	elif angle < -PI * 0.25:
		bearing = "LEFT"
	var height: float = target.y - player.global_position.y
	var elevation := " · ABOVE" if height > 1.5 else (" · BELOW" if height < -1.5 else "")
	_objective_title.text = director.get_objective_title()
	_objective_detail.text = "%s  ·  %d m%s" % [bearing, roundi(flat.length()), elevation]
	_health.text = "HEALTH  %d / 100" % ceili(player.health)
	_health.add_theme_color_override("font_color", Color(1.0, 0.48, 0.42) if player.damage_flash > 0.0 or player.health <= 30.0 else Color(0.91, 0.95, 0.86))
	_damage_tint.color = Color(0.8, 0.045, 0.025, player.damage_flash * 0.35)
	var ammo_status := ("RELOADING %d%%" % roundi(player.get_reload_progress() * 100.0)) if player.is_reloading else ("RELOAD [R]" if player.ammo == 0 else "UNLIMITED RESERVE")
	_ammo.text = "SMG  %02d / 30   %s" % [player.ammo, ammo_status]
	var awareness: Dictionary = director.get_local_awareness()
	_awareness.text = "%s  ·  SUSPICION %d%%" % [awareness["state"], roundi(float(awareness["suspicion"]) * 100.0)]
	_awareness.add_theme_color_override("font_color", Color(1.0, 0.52, 0.37) if awareness["state"] == "COMBAT" else (Color(1.0, 0.77, 0.43) if awareness["state"] != "CLEAR" else Color(0.72, 0.87, 0.79)))
	_noise.text = "NOISE  %s     TOWN  %s" % ["LOUD" if director.last_noise > 0.2 else "QUIET", "LOCKDOWN" if director.lockdown else "NORMAL"]
	_interaction.text = director.interaction_text if director.interaction_text != "" else ("F  Quiet rear takedown" if director.can_stealth_kill_now() else "")
	_progress.visible = director.handoff_progress > 0.0
	_progress.value = director.handoff_progress * 100.0
	_subtitle.text = director.subtitle_text
	_crosshair.text = "×" if player.hit_marker > 0.0 else "+"
	var marker_color := Color(0.91, 0.94, 0.9)
	if player.hit_marker > 0.0:
		marker_color = Color(1.0, 0.3, 0.25) if player.hit_kind == "kill" else (Color(1.0, 0.82, 0.35) if player.hit_kind == "head" else Color(1.0, 1.0, 1.0))
	elif player.shot_flash > 0.0:
		marker_color = Color(1.0, 0.79, 0.48)
	_crosshair.add_theme_color_override("font_color", marker_color)
	# Iron sights replace the crosshair while aiming; hit markers still show.
	_crosshair.modulate.a = 1.0 if player.hit_marker > 0.0 else clampf(1.0 - player.aim_amount * 1.4, 0.0, 1.0)


func _build_gameplay() -> void:
	_damage_tint = ColorRect.new()
	_damage_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_tint.color = Color.TRANSPARENT
	_damage_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_layer.add_child(_damage_tint)
	# Compact plates hugging the corners; the scene carries the frame.
	var objective_panel := _panel(_game_layer, 22, 20, 330, 66, false)
	_objective_title = _label(objective_panel, "MEET THE CONTACT", 22, Color(0.96, 0.9, 0.7), Vector2(14, 8), Vector2(305, 28))
	_objective_detail = _label(objective_panel, "AHEAD", 15, Color(0.78, 0.84, 0.79), Vector2(15, 37), Vector2(305, 22))
	var status_panel := _panel(_game_layer, -292, 20, 270, 66, true)
	_awareness = _label(status_panel, "CLEAR", 16, Color(0.72, 0.87, 0.79), Vector2(12, 9), Vector2(250, 24))
	_noise = _label(status_panel, "NOISE  QUIET     TOWN  NORMAL", 13, Color(0.78, 0.83, 0.76), Vector2(12, 38), Vector2(250, 22))
	var health_panel := _panel(_game_layer, 22, -64, 210, 44, false, true)
	_health = _label(health_panel, "HEALTH  100 / 100", 20, Color(0.91, 0.95, 0.86), Vector2(13, 9), Vector2(190, 28))
	var ammo_panel := _panel(_game_layer, -312, -64, 290, 44, true, true)
	_ammo = _label(ammo_panel, "SMG  30 / 30", 17, Color(0.91, 0.95, 0.86), Vector2(13, 11), Vector2(270, 24))
	_crosshair = _label(_game_layer, "+", 26, Color(0.91, 0.94, 0.9), Vector2.ZERO, Vector2(30, 30))
	_crosshair.anchor_left = 0.5
	_crosshair.anchor_right = 0.5
	_crosshair.anchor_top = 0.5
	_crosshair.anchor_bottom = 0.5
	_crosshair.offset_left = -11
	_crosshair.offset_right = 19
	_crosshair.offset_top = -17
	_crosshair.offset_bottom = 13
	_crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction = _label(_game_layer, "", 19, Color(0.99, 0.91, 0.69), Vector2.ZERO, Vector2(730, 32))
	_interaction.anchor_left = 0.5
	_interaction.anchor_right = 0.5
	_interaction.anchor_top = 0.72
	_interaction.anchor_bottom = 0.72
	_interaction.offset_left = -365
	_interaction.offset_right = 365
	_interaction.offset_top = 0
	_interaction.offset_bottom = 38
	_interaction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress = ProgressBar.new()
	_progress.anchor_left = 0.5
	_progress.anchor_right = 0.5
	_progress.anchor_top = 0.79
	_progress.anchor_bottom = 0.79
	_progress.offset_left = -170
	_progress.offset_right = 170
	_progress.offset_top = 0
	_progress.offset_bottom = 9
	_progress.show_percentage = false
	_progress.visible = false
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_layer.add_child(_progress)
	_subtitle = _label(_game_layer, "", 19, Color(0.98, 0.96, 0.86), Vector2.ZERO, Vector2(850, 48))
	_subtitle.anchor_left = 0.5
	_subtitle.anchor_right = 0.5
	_subtitle.anchor_top = 0.84
	_subtitle.anchor_bottom = 0.84
	_subtitle.offset_left = -425
	_subtitle.offset_right = 425
	_subtitle.offset_top = 0
	_subtitle.offset_bottom = 58
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _build_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.025, 0.035, 0.035, 0.94)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	var frame := Panel.new()
	frame.anchor_left = 0.5
	frame.anchor_right = 0.5
	frame.anchor_top = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -340
	frame.offset_right = 340
	frame.offset_top = -260
	frame.offset_bottom = 260
	frame.add_theme_stylebox_override("panel", _style(Color(0.09, 0.12, 0.115, 0.98), Color(0.37, 0.43, 0.37)))
	_overlay.add_child(frame)
	_menu_content = VBoxContainer.new()
	_menu_content.anchor_right = 1.0
	_menu_content.anchor_bottom = 1.0
	_menu_content.offset_left = 36
	_menu_content.offset_top = 31
	_menu_content.offset_right = -36
	_menu_content.offset_bottom = -30
	_menu_content.add_theme_constant_override("separation", 14)
	frame.add_child(_menu_content)


func _show_menu(title: String, body: String, buttons: Array) -> void:
	_overlay.visible = true
	for child in _menu_content.get_children():
		child.queue_free()
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color(0.95, 0.85, 0.62))
	_menu_content.add_child(heading)
	var divider := HSeparator.new()
	_menu_content.add_child(divider)
	var description := Label.new()
	description.text = body
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", Color(0.83, 0.87, 0.82))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(570, 175)
	_menu_content.add_child(description)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_menu_content.add_child(spacer)
	for entry in buttons:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(0, 43)
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(entry[1])
		_menu_content.add_child(button)


func _panel(parent: Control, left: float, top: float, width: float, height: float, right_anchor: bool, bottom_anchor: bool = false) -> Panel:
	var panel := Panel.new()
	panel.anchor_left = 1.0 if right_anchor else 0.0
	panel.anchor_right = panel.anchor_left
	panel.anchor_top = 1.0 if bottom_anchor else 0.0
	panel.anchor_bottom = panel.anchor_top
	panel.offset_left = left
	panel.offset_right = left + width
	panel.offset_top = top
	panel.offset_bottom = top + height
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Light, film-like HUD: translucent plates without hard borders.
	var plate := _style(Color(0.02, 0.025, 0.022, 0.34), Color(0, 0, 0, 0))
	plate.set_border_width_all(0)
	plate.set_corner_radius_all(2)
	panel.add_theme_stylebox_override("panel", plate)
	parent.add_child(panel)
	return panel


func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style


func _label(parent: Control, content: String, font_size: int, color: Color, at: Vector2, dimensions: Vector2) -> Label:
	var label := Label.new()
	label.text = content
	label.position = at
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", maxi(11, roundi(font_size * 0.86)))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	return label
