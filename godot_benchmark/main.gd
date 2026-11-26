extends Node2D

const MotionControllerScript = preload("res://motion_controller.gd")
const CelAnimeScript = preload("res://characters/character_cel_anime.gd")
const SemiRealisticScript = preload("res://characters/character_semi_realistic.gd")
const NoirComicScript = preload("res://characters/character_noir_comic.gd")

const STAGE_W: float = 1280.0
const STAGE_H: float = 720.0
const FLOOR_Y: float = 556.0
const GRID_POSITIONS: Array[float] = [250.0, 640.0, 1030.0]

enum ViewMode {
	GRID,
	SINGLE,
}

var motion_controller: MotionController
var characters: Array[Node2D] = []
var char_titles: Array[String] = [
	"Cel-Shaded Anime",
	"Graphic Semi-Realistic",
	"Bold Noir Comic Ink",
]
var char_subtitles: Array[String] = [
	"2-Step Hard Shadows · Variable Ink · Rim Highlights",
	"7.5-Head Anatomy · Planar Shadows · Tapered Linework",
	"Chiaroscuro Shadows · Thick Brush Strokes · 1 Accent",
]

var view_mode: int = ViewMode.GRID
var selected_char_idx: int = 0
var hovered_char_idx: int = -1

# Pedestal click ripple feedback: { "pos": Vector2, "age": float }
var _ripples: Array[Dictionary] = []

# Bottom HUD controls
var _hud_layer: CanvasLayer
var _motion_buttons: Dictionary = {}
var _view_toggle_btn: Button
var _single_char_bar: HBoxContainer
var _char_buttons: Array[Button] = []

var _btn_normal: StyleBoxFlat
var _btn_hover: StyleBoxFlat
var _btn_active: StyleBoxFlat
var _btn_secondary_active: StyleBoxFlat


func _ready() -> void:
	motion_controller = MotionControllerScript.new() as MotionController
	motion_controller.name = "MotionController"
	add_child(motion_controller)

	var c1: Node2D = CelAnimeScript.new()
	c1.name = "CharacterCelAnime"
	var c2: Node2D = SemiRealisticScript.new()
	c2.name = "CharacterSemiRealistic"
	var c3: Node2D = NoirComicScript.new()
	c3.name = "CharacterNoirComic"

	characters = [c1, c2, c3]
	for ch in characters:
		add_child(ch)

	_build_button_styles()
	_build_bottom_hud()
	_apply_layout()
	_sync_button_states()

	var initial_anchors: MotionController.RigAnchors = motion_controller.step(0.016)
	for ch in characters:
		ch.call("set_anchors", initial_anchors)


func _process(delta: float) -> void:
	var anchors: MotionController.RigAnchors = motion_controller.step(delta)
	for ch in characters:
		if ch.visible:
			ch.call("set_anchors", anchors)

	# Update click ripples
	if _ripples.size() > 0:
		var i: int = _ripples.size() - 1
		while i >= 0:
			_ripples[i]["age"] = float(_ripples[i]["age"]) + delta
			if float(_ripples[i]["age"]) >= 0.45:
				_ripples.remove_at(i)
			i -= 1

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mpos: Vector2 = get_global_mouse_position()
		var hit_idx: int = _hit_test_characters(mpos)
		if hit_idx != hovered_char_idx:
			hovered_char_idx = hit_idx
			Input.set_default_cursor_shape(
				Input.CURSOR_POINTING_HAND if hovered_char_idx != -1 else Input.CURSOR_ARROW
			)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var mpos: Vector2 = get_global_mouse_position()
			var hit_idx: int = _hit_test_characters(mpos)
			if hit_idx != -1:
				motion_controller.next_motion()
				_sync_button_states()
				_ripples.append({"pos": characters[hit_idx].position, "age": 0.0})
				get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var kev := event as InputEventKey
		match kev.keycode:
			KEY_1:
				_select_motion(MotionController.Motion.IDLE)
			KEY_2:
				_select_motion(MotionController.Motion.NOD_LOOK)
			KEY_3:
				_select_motion(MotionController.Motion.WAVE)
			KEY_4:
				_select_motion(MotionController.Motion.JUMP)
			KEY_5:
				_select_motion(MotionController.Motion.SHOCK)
			KEY_SPACE:
				motion_controller.next_motion()
				_sync_button_states()
			KEY_TAB:
				_toggle_view_mode()


func _hit_test_characters(mpos: Vector2) -> int:
	# Iterate front-to-back in case of overlap
	for i in range(characters.size() - 1, -1, -1):
		var ch: Node2D = characters[i]
		if ch.visible:
			var rect: Rect2 = ch.call("get_hit_rect")
			if rect.has_point(mpos):
				return i
	return -1


func _draw() -> void:
	# Clean dark studio backdrop (drawn directly on Node2D so it NEVER swallows clicks)
	draw_rect(Rect2(0.0, 0.0, STAGE_W, STAGE_H), Color(0.055, 0.067, 0.090), true)
	# Subtle upper studio wall band
	draw_rect(Rect2(0.0, 0.0, STAGE_W, FLOOR_Y - 36.0), Color(0.075, 0.090, 0.122), true)
	# Horizon floor transition band
	draw_line(Vector2(0.0, FLOOR_Y - 36.0), Vector2(STAGE_W, FLOOR_Y - 36.0), Color(0.145, 0.173, 0.227, 0.55), 1.5, true)

	# Subtle architectural grid guides on floor plane
	for gx in range(160, 1280, 160):
		draw_line(
			Vector2(float(gx), FLOOR_Y - 36.0),
			Vector2(float(gx) + (float(gx) - 640.0) * 0.28, STAGE_H),
			Color(0.14, 0.165, 0.22, 0.25),
			1.0,
			true
		)

	var font: Font = ThemeDB.fallback_font

	# Draw pedestals and non-intrusive style labels for visible characters
	for i in range(characters.size()):
		var ch: Node2D = characters[i]
		if not ch.visible:
			continue

		var px: float = ch.position.x
		var py: float = ch.position.y
		var is_hovered: bool = (i == hovered_char_idx)
		var ped_rx: float = 96.0 if view_mode == ViewMode.SINGLE else 82.0
		var ped_ry: float = 18.0 if view_mode == ViewMode.SINGLE else 15.0

		# Pedestal plate
		_draw_ellipse_fill(Vector2(px, py + 4.0), ped_rx, ped_ry, Color(0.105, 0.125, 0.169))
		_draw_ellipse_ring(
			Vector2(px, py + 4.0),
			ped_rx,
			ped_ry,
			Color(0.961, 0.620, 0.043, 0.85) if is_hovered else Color(0.24, 0.28, 0.36, 0.65),
			2.0 if is_hovered else 1.2
		)

		# Labels directly under pedestal
		var label_w: float = 340.0
		draw_string(
			font,
			Vector2(px - label_w * 0.5, py + 42.0),
			char_titles[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			label_w,
			15,
			Color(0.945, 0.961, 0.976)
		)
		draw_string(
			font,
			Vector2(px - label_w * 0.5, py + 60.0),
			char_subtitles[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			label_w,
			11,
			Color(0.580, 0.639, 0.722)
		)

	# Click feedback ripples
	for rip in _ripples:
		var pos: Vector2 = rip["pos"]
		var p: float = clampf(float(rip["age"]) / 0.45, 0.0, 1.0)
		var rx: float = lerpf(62.0, 128.0, p)
		var ry: float = lerpf(12.0, 26.0, p)
		_draw_ellipse_ring(pos + Vector2(0.0, 4.0), rx, ry, Color(0.961, 0.620, 0.043, (1.0 - p) * 0.85), 2.2)


func _draw_ellipse_fill(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var segs: int = 32
	for i in range(segs):
		var a: float = (float(i) / float(segs)) * TAU
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


func _draw_ellipse_ring(center: Vector2, rx: float, ry: float, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	var segs: int = 32
	for i in range(segs + 1):
		var a: float = (float(i % segs) / float(segs)) * TAU
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, col, width, true)


func _build_button_styles() -> void:
	_btn_normal = StyleBoxFlat.new()
	_btn_normal.bg_color = Color(0.118, 0.141, 0.188, 0.95)
	_btn_normal.border_color = Color(0.220, 0.259, 0.333, 0.9)
	_btn_normal.set_border_width_all(1)
	_btn_normal.set_corner_radius_all(6)
	_btn_normal.content_margin_left = 14
	_btn_normal.content_margin_right = 14
	_btn_normal.content_margin_top = 8
	_btn_normal.content_margin_bottom = 8

	_btn_hover = _btn_normal.duplicate() as StyleBoxFlat
	_btn_hover.bg_color = Color(0.165, 0.196, 0.259, 0.98)
	_btn_hover.border_color = Color(0.360, 0.420, 0.520, 1.0)

	_btn_active = _btn_normal.duplicate() as StyleBoxFlat
	_btn_active.bg_color = Color(0.961, 0.620, 0.043, 1.0) # #F59E0B amber accent
	_btn_active.border_color = Color(0.988, 0.749, 0.141, 1.0)

	_btn_secondary_active = _btn_normal.duplicate() as StyleBoxFlat
	_btn_secondary_active.bg_color = Color(0.240, 0.290, 0.380, 1.0)
	_btn_secondary_active.border_color = Color(0.550, 0.640, 0.780, 1.0)


func _style_button(btn: Button, is_active: bool, primary: bool = true) -> void:
	var active_sb: StyleBoxFlat = _btn_active if primary else _btn_secondary_active
	btn.add_theme_stylebox_override("normal", active_sb if is_active else _btn_normal)
	btn.add_theme_stylebox_override("hover", active_sb if is_active else _btn_hover)
	btn.add_theme_stylebox_override("pressed", active_sb)
	btn.add_theme_stylebox_override("focus", active_sb if is_active else _btn_hover)

	if is_active and primary:
		btn.add_theme_color_override("font_color", Color(0.055, 0.067, 0.090))
		btn.add_theme_color_override("font_hover_color", Color(0.055, 0.067, 0.090))
		btn.add_theme_color_override("font_focus_color", Color(0.055, 0.067, 0.090))
	else:
		btn.add_theme_color_override("font_color", Color(0.925, 0.945, 0.969))
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_focus_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 13)


func _build_bottom_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "BottomHUD"
	add_child(_hud_layer)

	# Fullscreen wrapper with MOUSE_FILTER_IGNORE so stage clicks NEVER get swallowed
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(root_ctrl)

	var bar_anchor := HBoxContainer.new()
	bar_anchor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar_anchor.offset_top = -62.0
	bar_anchor.offset_bottom = -14.0
	bar_anchor.alignment = BoxContainer.ALIGNMENT_CENTER
	bar_anchor.add_theme_constant_override("separation", 18)
	bar_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(bar_anchor)

	# 5 Motion Buttons
	var motion_group := HBoxContainer.new()
	motion_group.add_theme_constant_override("separation", 8)
	motion_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_anchor.add_child(motion_group)

	for motion_id in MotionController.MOTION_ORDER:
		var btn := Button.new()
		btn.text = String(MotionController.MOTION_LABELS[motion_id])
		btn.custom_minimum_size = Vector2(92.0, 38.0)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(_select_motion.bind(motion_id))
		motion_group.add_child(btn)
		_motion_buttons[motion_id] = btn

	# Subtle divider line
	var sep := VSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_anchor.add_child(sep)

	# View Mode Switch + Single-View Character Selector
	var view_group := HBoxContainer.new()
	view_group.add_theme_constant_override("separation", 8)
	view_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_anchor.add_child(view_group)

	_view_toggle_btn = Button.new()
	_view_toggle_btn.custom_minimum_size = Vector2(126.0, 38.0)
	_view_toggle_btn.focus_mode = Control.FOCUS_NONE
	_view_toggle_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_view_toggle_btn.pressed.connect(_toggle_view_mode)
	view_group.add_child(_view_toggle_btn)

	_single_char_bar = HBoxContainer.new()
	_single_char_bar.add_theme_constant_override("separation", 6)
	_single_char_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view_group.add_child(_single_char_bar)

	var short_names: Array[String] = ["Cel Anime", "Semi-Real", "Noir Ink"]
	for idx in range(short_names.size()):
		var cbtn := Button.new()
		cbtn.text = short_names[idx]
		cbtn.custom_minimum_size = Vector2(88.0, 38.0)
		cbtn.focus_mode = Control.FOCUS_NONE
		cbtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cbtn.pressed.connect(_select_single_character.bind(idx))
		_single_char_bar.add_child(cbtn)
		_char_buttons.append(cbtn)


func _select_motion(motion_id: int) -> void:
	motion_controller.set_motion(motion_id, true)
	_sync_button_states()


func _toggle_view_mode() -> void:
	view_mode = ViewMode.SINGLE if view_mode == ViewMode.GRID else ViewMode.GRID
	_apply_layout()
	_sync_button_states()


func _select_single_character(idx: int) -> void:
	selected_char_idx = clampi(idx, 0, characters.size() - 1)
	_apply_layout()
	_sync_button_states()


func _apply_layout() -> void:
	if view_mode == ViewMode.GRID:
		for i in range(characters.size()):
			characters[i].visible = true
			characters[i].position = Vector2(GRID_POSITIONS[i], FLOOR_Y)
			characters[i].scale = Vector2(1.0, 1.0)
	else:
		for i in range(characters.size()):
			var is_sel: bool = (i == selected_char_idx)
			characters[i].visible = is_sel
			characters[i].position = Vector2(STAGE_W * 0.5, FLOOR_Y + 6.0)
			characters[i].scale = Vector2(1.18, 1.18)
	queue_redraw()


func _sync_button_states() -> void:
	var active_m: int = motion_controller.get_motion()
	for motion_id in _motion_buttons.keys():
		var btn: Button = _motion_buttons[motion_id]
		_style_button(btn, int(motion_id) == active_m, true)

	_view_toggle_btn.text = "Single View" if view_mode == ViewMode.GRID else "Side-by-Side"
	_style_button(_view_toggle_btn, false, false)

	_single_char_bar.visible = (view_mode == ViewMode.SINGLE)
	for i in range(_char_buttons.size()):
		_style_button(_char_buttons[i], i == selected_char_idx, false)
