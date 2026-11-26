extends Node2D

const MotionControllerScript = preload("res://motion_controller.gd")

const CHARACTER_SCRIPTS := [
	preload("res://characters/character_cel_anime.gd"),
	preload("res://characters/character_semi_realistic.gd"),
	preload("res://characters/character_noir_comic.gd"),
	preload("res://characters/character_chibi.gd"),
	preload("res://characters/character_lineless_vector.gd"),
	preload("res://characters/character_rubber_hose.gd"),
	preload("res://characters/character_ligne_claire.gd"),
	preload("res://characters/character_painterly_gouache.gd"),
	preload("res://characters/character_gothic_sketch.gd"),
	preload("res://characters/character_paper_cutout.gd"),
	preload("res://characters/character_ukiyoe.gd"),
	preload("res://characters/character_mecha_android.gd"),
]

const STAGE_W: float = 1280.0
const STAGE_H: float = 720.0
const FLOOR_Y: float = 548.0
const GRID_POSITIONS := [250.0, 640.0, 1030.0]

enum ViewMode {
	GRID,
	SINGLE,
}

enum BackdropMode {
	DARK,
	GRAY,
	LIGHT,
}

const BACKDROP_THEMES := [
	{
		"label": "Dark",
		"floor": Color(0.055, 0.067, 0.090),
		"wall": Color(0.075, 0.090, 0.122),
		"horizon": Color(0.145, 0.173, 0.227, 0.55),
		"grid": Color(0.140, 0.165, 0.220, 0.25),
		"pedestal": Color(0.105, 0.125, 0.169),
		"ring": Color(0.240, 0.280, 0.360, 0.65),
		"title": Color(0.945, 0.961, 0.976),
		"subtitle": Color(0.580, 0.639, 0.722),
	},
	{
		"label": "Gray",
		"floor": Color(0.329, 0.349, 0.380),
		"wall": Color(0.392, 0.416, 0.451),
		"horizon": Color(0.240, 0.260, 0.290, 0.65),
		"grid": Color(0.250, 0.270, 0.300, 0.30),
		"pedestal": Color(0.275, 0.294, 0.325),
		"ring": Color(0.180, 0.200, 0.230, 0.70),
		"title": Color(0.970, 0.976, 0.984),
		"subtitle": Color(0.820, 0.843, 0.875),
	},
	{
		"label": "Light",
		"floor": Color(0.847, 0.863, 0.890),
		"wall": Color(0.922, 0.933, 0.953),
		"horizon": Color(0.678, 0.710, 0.765, 0.75),
		"grid": Color(0.690, 0.725, 0.780, 0.35),
		"pedestal": Color(0.765, 0.788, 0.827),
		"ring": Color(0.490, 0.529, 0.600, 0.75),
		"title": Color(0.086, 0.106, 0.141),
		"subtitle": Color(0.302, 0.349, 0.424),
	},
]

var motion_controller: MotionController
var characters: Array[Node2D] = []
var char_titles: Array[String] = []
var char_subtitles: Array[String] = []

var view_mode: int = ViewMode.GRID
var backdrop_mode: int = BackdropMode.DARK
var grid_slots: Array[int] = [0, 1, 2]
var selected_char_idx: int = 0
var hovered_char_idx: int = -1

# Pedestal click ripple feedback: { "pos": Vector2, "age": float }
var _ripples: Array[Dictionary] = []

# Bottom HUD controls
var _hud_layer: CanvasLayer
var _motion_buttons: Dictionary = {}
var _backdrop_buttons: Array[Button] = []
var _view_toggle_btn: Button
var _grid_set_bar: HBoxContainer
var _set_buttons: Array[Button] = []
var _single_nav_bar: HBoxContainer
var _single_label_btn: Button
var _slot_swap_groups: Array[HBoxContainer] = []

var _btn_normal: StyleBoxFlat
var _btn_hover: StyleBoxFlat
var _btn_active: StyleBoxFlat
var _btn_secondary_active: StyleBoxFlat
var _btn_mini_normal: StyleBoxFlat
var _btn_mini_hover: StyleBoxFlat


func _ready() -> void:
	motion_controller = MotionControllerScript.new() as MotionController
	motion_controller.name = "MotionController"
	add_child(motion_controller)

	for i in range(CHARACTER_SCRIPTS.size()):
		var scr := CHARACTER_SCRIPTS[i] as GDScript
		var ch := scr.new() as Node2D
		ch.name = "Character_%02d" % (i + 1)
		add_child(ch)
		characters.append(ch)
		var cmap: Dictionary = scr.get_script_constant_map()
		char_titles.append(String(cmap.get("STYLE_TITLE", "Style %d" % (i + 1))))
		char_subtitles.append(String(cmap.get("STYLE_SUBTITLE", "")))

	_build_button_styles()
	_build_bottom_hud()
	_apply_layout()
	_sync_button_states()

	var initial_anchors: MotionController.RigAnchors = motion_controller.step(0.016)
	for ch in characters:
		if ch.visible:
			ch.call("set_anchors", initial_anchors)


func _process(delta: float) -> void:
	var anchors: MotionController.RigAnchors = motion_controller.step(delta)
	for ch in characters:
		if ch.visible:
			ch.call("set_anchors", anchors)

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
			KEY_B:
				_select_backdrop((backdrop_mode + 1) % BACKDROP_THEMES.size())
			KEY_LEFT:
				if view_mode == ViewMode.SINGLE:
					_step_single_character(-1)
			KEY_RIGHT:
				if view_mode == ViewMode.SINGLE:
					_step_single_character(1)


func _hit_test_characters(mpos: Vector2) -> int:
	for i in range(characters.size() - 1, -1, -1):
		var ch: Node2D = characters[i]
		if ch.visible:
			var rect: Rect2 = ch.call("get_hit_rect")
			if rect.has_point(mpos):
				return i
	return -1


func _draw() -> void:
	var theme: Dictionary = BACKDROP_THEMES[backdrop_mode]
	var floor_col: Color = theme["floor"]
	var wall_col: Color = theme["wall"]
	var horizon_col: Color = theme["horizon"]
	var grid_col: Color = theme["grid"]
	var ped_col: Color = theme["pedestal"]
	var ring_col: Color = theme["ring"]
	var title_col: Color = theme["title"]
	var subtitle_col: Color = theme["subtitle"]

	# Studio backdrop drawn directly on Node2D so it never swallows clicks
	draw_rect(Rect2(0.0, 0.0, STAGE_W, STAGE_H), floor_col, true)
	draw_rect(Rect2(0.0, 0.0, STAGE_W, FLOOR_Y - 36.0), wall_col, true)
	draw_line(Vector2(0.0, FLOOR_Y - 36.0), Vector2(STAGE_W, FLOOR_Y - 36.0), horizon_col, 1.5, true)

	for gx in range(160, 1280, 160):
		draw_line(
			Vector2(float(gx), FLOOR_Y - 36.0),
			Vector2(float(gx) + (float(gx) - 640.0) * 0.28, STAGE_H),
			grid_col,
			1.0,
			true
		)

	var font: Font = ThemeDB.fallback_font
	var active_indices: Array[int] = []
	if view_mode == ViewMode.GRID:
		active_indices.assign(grid_slots)
	else:
		active_indices.append(selected_char_idx)

	for i in active_indices:
		var ch: Node2D = characters[i]
		var px: float = ch.position.x
		var py: float = ch.position.y
		var is_hovered: bool = (i == hovered_char_idx)
		var ped_rx: float = 96.0 if view_mode == ViewMode.SINGLE else 82.0
		var ped_ry: float = 18.0 if view_mode == ViewMode.SINGLE else 15.0

		_draw_ellipse_fill(Vector2(px, py + 4.0), ped_rx, ped_ry, ped_col)
		_draw_ellipse_ring(
			Vector2(px, py + 4.0),
			ped_rx,
			ped_ry,
			Color(0.961, 0.620, 0.043, 0.9) if is_hovered else ring_col,
			2.0 if is_hovered else 1.2
		)

		var label_w: float = 340.0
		var title_text: String = "%d. %s" % [i + 1, char_titles[i]]
		draw_string(
			font,
			Vector2(px - label_w * 0.5, py + 38.0),
			title_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			label_w,
			14,
			title_col
		)
		draw_string(
			font,
			Vector2(px - label_w * 0.5, py + 55.0),
			char_subtitles[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			label_w,
			11,
			subtitle_col
		)

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
	_btn_normal.content_margin_left = 10
	_btn_normal.content_margin_right = 10
	_btn_normal.content_margin_top = 7
	_btn_normal.content_margin_bottom = 7

	_btn_hover = _btn_normal.duplicate() as StyleBoxFlat
	_btn_hover.bg_color = Color(0.165, 0.196, 0.259, 0.98)
	_btn_hover.border_color = Color(0.360, 0.420, 0.520, 1.0)

	_btn_active = _btn_normal.duplicate() as StyleBoxFlat
	_btn_active.bg_color = Color(0.961, 0.620, 0.043, 1.0)
	_btn_active.border_color = Color(0.988, 0.749, 0.141, 1.0)

	_btn_secondary_active = _btn_normal.duplicate() as StyleBoxFlat
	_btn_secondary_active.bg_color = Color(0.240, 0.290, 0.380, 1.0)
	_btn_secondary_active.border_color = Color(0.550, 0.640, 0.780, 1.0)

	_btn_mini_normal = _btn_normal.duplicate() as StyleBoxFlat
	_btn_mini_normal.content_margin_left = 6
	_btn_mini_normal.content_margin_right = 6
	_btn_mini_normal.content_margin_top = 2
	_btn_mini_normal.content_margin_bottom = 2
	_btn_mini_normal.set_corner_radius_all(4)

	_btn_mini_hover = _btn_hover.duplicate() as StyleBoxFlat
	_btn_mini_hover.content_margin_left = 6
	_btn_mini_hover.content_margin_right = 6
	_btn_mini_hover.content_margin_top = 2
	_btn_mini_hover.content_margin_bottom = 2
	_btn_mini_hover.set_corner_radius_all(4)


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


func _style_mini_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _btn_mini_normal)
	btn.add_theme_stylebox_override("hover", _btn_mini_hover)
	btn.add_theme_stylebox_override("pressed", _btn_secondary_active)
	btn.add_theme_stylebox_override("focus", _btn_mini_hover)
	btn.add_theme_color_override("font_color", Color(0.88, 0.91, 0.95))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 11)


func _build_bottom_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "BottomHUD"
	add_child(_hud_layer)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(root_ctrl)

	# Per-pedestal < / > style swappers below labels (never overlap characters!)
	for slot_idx in range(3):
		var slot_bar := HBoxContainer.new()
		slot_bar.position = Vector2(GRID_POSITIONS[slot_idx] - 32.0, FLOOR_Y + 64.0)
		slot_bar.add_theme_constant_override("separation", 12)
		slot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root_ctrl.add_child(slot_bar)

		var prev_slot := Button.new()
		prev_slot.text = "<"
		prev_slot.custom_minimum_size = Vector2(26.0, 22.0)
		prev_slot.focus_mode = Control.FOCUS_NONE
		prev_slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		prev_slot.pressed.connect(_step_grid_slot.bind(slot_idx, -1))
		_style_mini_button(prev_slot)
		slot_bar.add_child(prev_slot)

		var next_slot := Button.new()
		next_slot.text = ">"
		next_slot.custom_minimum_size = Vector2(26.0, 22.0)
		next_slot.focus_mode = Control.FOCUS_NONE
		next_slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		next_slot.pressed.connect(_step_grid_slot.bind(slot_idx, 1))
		_style_mini_button(next_slot)
		slot_bar.add_child(next_slot)

		_slot_swap_groups.append(slot_bar)

	# Main Bottom Bar
	var bar_anchor := HBoxContainer.new()
	bar_anchor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar_anchor.offset_top = -54.0
	bar_anchor.offset_bottom = -10.0
	bar_anchor.alignment = BoxContainer.ALIGNMENT_CENTER
	bar_anchor.add_theme_constant_override("separation", 10)
	bar_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(bar_anchor)

	# 5 Motion Buttons
	var motion_group := HBoxContainer.new()
	motion_group.add_theme_constant_override("separation", 5)
	motion_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_anchor.add_child(motion_group)

	for motion_id in MotionController.MOTION_ORDER:
		var btn := Button.new()
		btn.text = String(MotionController.MOTION_LABELS[motion_id])
		btn.custom_minimum_size = Vector2(82.0, 36.0)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(_select_motion.bind(motion_id))
		motion_group.add_child(btn)
		_motion_buttons[motion_id] = btn

	var sep_bg := VSeparator.new()
	sep_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_anchor.add_child(sep_bg)

	# 3-Backdrop Switcher (Dark / Gray / Light)
	var bg_group := HBoxContainer.new()
	bg_group.add_theme_constant_override("separation", 5)
	bg_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_anchor.add_child(bg_group)

	for bg_idx in range(BACKDROP_THEMES.size()):
		var bbtn := Button.new()
		bbtn.text = String(BACKDROP_THEMES[bg_idx]["label"])
		bbtn.custom_minimum_size = Vector2(56.0, 36.0)
		bbtn.focus_mode = Control.FOCUS_NONE
		bbtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		bbtn.pressed.connect(_select_backdrop.bind(bg_idx))
		bg_group.add_child(bbtn)
		_backdrop_buttons.append(bbtn)

	var sep_view := VSeparator.new()
	sep_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_anchor.add_child(sep_view)

	# View Mode Switch + Style Set / Single Navigation
	var view_group := HBoxContainer.new()
	view_group.add_theme_constant_override("separation", 6)
	view_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_anchor.add_child(view_group)

	_view_toggle_btn = Button.new()
	_view_toggle_btn.custom_minimum_size = Vector2(112.0, 36.0)
	_view_toggle_btn.focus_mode = Control.FOCUS_NONE
	_view_toggle_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_view_toggle_btn.pressed.connect(_toggle_view_mode)
	view_group.add_child(_view_toggle_btn)

	# Side-by-Side 4 Trio Sets (1-3, 4-6, 7-9, 10-12)
	_grid_set_bar = HBoxContainer.new()
	_grid_set_bar.add_theme_constant_override("separation", 5)
	_grid_set_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view_group.add_child(_grid_set_bar)

	var set_labels := ["1-3", "4-6", "7-9", "10-12"]
	for s_idx in range(set_labels.size()):
		var sbtn := Button.new()
		sbtn.text = set_labels[s_idx]
		sbtn.custom_minimum_size = Vector2(56.0, 36.0)
		sbtn.focus_mode = Control.FOCUS_NONE
		sbtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		sbtn.pressed.connect(_select_grid_set.bind(s_idx))
		_grid_set_bar.add_child(sbtn)
		_set_buttons.append(sbtn)

	# Single-View < Prev / Counter / Next >
	_single_nav_bar = HBoxContainer.new()
	_single_nav_bar.add_theme_constant_override("separation", 5)
	_single_nav_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view_group.add_child(_single_nav_bar)

	var prev_btn := Button.new()
	prev_btn.text = "< Prev"
	prev_btn.custom_minimum_size = Vector2(68.0, 36.0)
	prev_btn.focus_mode = Control.FOCUS_NONE
	prev_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	prev_btn.pressed.connect(_step_single_character.bind(-1))
	_style_button(prev_btn, false, false)
	_single_nav_bar.add_child(prev_btn)

	_single_label_btn = Button.new()
	_single_label_btn.custom_minimum_size = Vector2(92.0, 36.0)
	_single_label_btn.focus_mode = Control.FOCUS_NONE
	_single_label_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_single_label_btn.pressed.connect(_step_single_character.bind(1))
	_style_button(_single_label_btn, true, false)
	_single_nav_bar.add_child(_single_label_btn)

	var next_btn := Button.new()
	next_btn.text = "Next >"
	next_btn.custom_minimum_size = Vector2(68.0, 36.0)
	next_btn.focus_mode = Control.FOCUS_NONE
	next_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_btn.pressed.connect(_step_single_character.bind(1))
	_style_button(next_btn, false, false)
	_single_nav_bar.add_child(next_btn)


func _select_motion(motion_id: int) -> void:
	motion_controller.set_motion(motion_id, true)
	_sync_button_states()


func _select_backdrop(bg_idx: int) -> void:
	backdrop_mode = clampi(bg_idx, 0, BACKDROP_THEMES.size() - 1)
	_sync_button_states()
	queue_redraw()


func _toggle_view_mode() -> void:
	view_mode = ViewMode.SINGLE if view_mode == ViewMode.GRID else ViewMode.GRID
	if view_mode == ViewMode.SINGLE and not grid_slots.has(selected_char_idx):
		selected_char_idx = grid_slots[0]
	_apply_layout()
	_sync_button_states()


func _select_grid_set(set_idx: int) -> void:
	var base: int = set_idx * 3
	grid_slots = [base, base + 1, base + 2]
	_apply_layout()
	_sync_button_states()


func _step_grid_slot(slot_idx: int, dir: int) -> void:
	var n: int = characters.size()
	var next_c: int = (grid_slots[slot_idx] + dir + n) % n
	# Skip characters already visible in the other two slots so all 3 pedestals stay unique
	for _attempt in range(n):
		var conflict: bool = false
		for other_slot in range(3):
			if other_slot != slot_idx and grid_slots[other_slot] == next_c:
				conflict = true
				break
		if not conflict:
			break
		next_c = (next_c + dir + n) % n
	grid_slots[slot_idx] = next_c
	_apply_layout()
	_sync_button_states()


func _step_single_character(dir: int) -> void:
	var n: int = characters.size()
	selected_char_idx = (selected_char_idx + dir + n) % n
	_apply_layout()
	_sync_button_states()


func _apply_layout() -> void:
	hovered_char_idx = -1
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	for ch in characters:
		ch.visible = false

	if view_mode == ViewMode.GRID:
		for slot_idx in range(3):
			var c_idx: int = grid_slots[slot_idx]
			characters[c_idx].visible = true
			characters[c_idx].position = Vector2(GRID_POSITIONS[slot_idx], FLOOR_Y)
			characters[c_idx].scale = Vector2(1.0, 1.0)
	else:
		characters[selected_char_idx].visible = true
		characters[selected_char_idx].position = Vector2(STAGE_W * 0.5, FLOOR_Y + 8.0)
		characters[selected_char_idx].scale = Vector2(1.18, 1.18)

	var current_anchors: MotionController.RigAnchors = motion_controller.get_anchors()
	for ch in characters:
		if ch.visible:
			ch.call("set_anchors", current_anchors)

	queue_redraw()


func _sync_button_states() -> void:
	var active_m: int = motion_controller.get_motion()
	for motion_id in _motion_buttons.keys():
		var btn: Button = _motion_buttons[motion_id]
		_style_button(btn, int(motion_id) == active_m, true)

	for bg_idx in range(_backdrop_buttons.size()):
		_style_button(_backdrop_buttons[bg_idx], bg_idx == backdrop_mode, false)

	_view_toggle_btn.text = "Single View" if view_mode == ViewMode.GRID else "Side-by-Side"
	_style_button(_view_toggle_btn, false, false)

	_grid_set_bar.visible = (view_mode == ViewMode.GRID)
	_single_nav_bar.visible = (view_mode == ViewMode.SINGLE)
	for slot_bar in _slot_swap_groups:
		slot_bar.visible = (view_mode == ViewMode.GRID)

	for s_idx in range(_set_buttons.size()):
		var base: int = s_idx * 3
		var is_exact_set: bool = (grid_slots[0] == base and grid_slots[1] == base + 1 and grid_slots[2] == base + 2)
		_style_button(_set_buttons[s_idx], is_exact_set, false)

	_single_label_btn.text = "Style %d / %d" % [selected_char_idx + 1, characters.size()]
