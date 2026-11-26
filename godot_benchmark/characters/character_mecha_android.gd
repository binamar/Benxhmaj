class_name CharacterMechaAndroid
extends Node2D

const STYLE_TITLE: String = "Hard-Surface Mecha"
const STYLE_SUBTITLE: String = "Chamfered Armor · Hydraulic Joints · LED Visor"

const PANEL_LINE := Color(0.075, 0.090, 0.122, 1.0)  # #13171F technical seam ink
const CHASSIS_DARK := Color(0.145, 0.173, 0.220, 1.0)# #252C38 joint/frame gunmetal
const TITANIUM_LIT := Color(0.847, 0.875, 0.914, 1.0)# #D8DFE9 brushed silver plate
const TITANIUM_SH := Color(0.580, 0.627, 0.698, 1.0) # #94A0B2
const COBALT_ARMOR := Color(0.184, 0.341, 0.580, 1.0)# #2F5794 tactical blue
const COBALT_SH := Color(0.118, 0.220, 0.392, 1.0)
const SPECULAR_BAR := Color(0.980, 0.992, 1.0, 0.85)

const VISOR_GLASS := Color(0.055, 0.075, 0.114, 1.0) # #0E131D dark visor
const LED_CYAN := Color(0.133, 0.827, 0.933, 1.0)    # #22D3EE active visor glow
const LED_SHOCK := Color(0.984, 0.388, 0.243, 1.0)   # #FB633E alert amber-red

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 152.0 * s
	var h: float = 368.0 * s
	return Rect2(position.x + bx * s - w * 0.5, position.y + by * s - h, w, h)


static func _xform(pos: Vector2, rot: float = 0.0, scl: Vector2 = Vector2.ONE) -> Transform2D:
	return Transform2D(0.0, pos) * Transform2D(rot, Vector2.ZERO) * Transform2D.IDENTITY.scaled(scl)


static func _closed_outline(poly: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = poly.duplicate()
	if poly.size() > 0:
		out.append(poly[0])
	return out


static func _ellipse_pts(center: Vector2, rx: float, ry: float, segments: int = 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a: float = (float(i) / float(segments)) * TAU
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _draw() -> void:
	if anchors == null:
		return

	var body_root := anchors.body_root
	var torso := anchors.torso
	var head_pivot := anchors.head_pivot
	var eyes := anchors.eyes
	var mouth := anchors.mouth
	var front_arm := anchors.front_arm
	var back_arm := anchors.back_arm
	var lag := anchors.secondary_lag

	var led_col: Color = LED_SHOCK if eyes.wide > 0.35 else LED_CYAN

	# Crisp hex-like robotic ground shadow
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	draw_set_transform_matrix(_xform(
		Vector2(body_root.x * 0.7, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.42, 1.0 - air_factor * 0.35)
	))
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 52.0, 10.0, 12), Color(0.03, 0.04, 0.08, 0.42))

	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean,
		Vector2(body_root.scale_x, body_root.scale_y)
	)
	draw_set_transform_matrix(root_xf)

	# === ARTICULATED ARMORED GREAVES, KNEE ROTORS, & THRUSTER BOOTS ===
	var knee_bend: float = clampf((1.0 - body_root.scale_y) * 26.0, -7.0, 15.0)
	for side in [-1, 1]:
		var is_back: bool = side == -1
		var fx: float = float(side) * 16.0
		var kb: float = knee_bend * 0.24 * float(side)

		# Upper thigh hydraulic frame + armor plate
		var thigh := PackedVector2Array([
			Vector2(float(side) * 11.0 - 10.0, -162.0),
			Vector2(float(side) * 11.0 + 10.0, -162.0),
			Vector2(fx + 8.5 + kb, -88.0),
			Vector2(fx - 8.5 + kb, -88.0),
		])
		draw_colored_polygon(thigh, TITANIUM_SH if is_back else TITANIUM_LIT)
		draw_polyline(_closed_outline(thigh), PANEL_LINE, 2.2, true)

		# Lower greave armor
		var shin := PackedVector2Array([
			Vector2(fx - 9.0 + kb, -88.0),
			Vector2(fx + 9.0 + kb, -88.0),
			Vector2(fx + 7.5, -24.0),
			Vector2(fx - 7.5, -24.0),
		])
		draw_colored_polygon(shin, COBALT_SH if is_back else COBALT_ARMOR)
		if not is_back:
			draw_line(Vector2(fx + 4.0 + kb * 0.6, -80.0), Vector2(fx + 4.5, -30.0), SPECULAR_BAR, 2.6, true)
		draw_polyline(_closed_outline(shin), PANEL_LINE, 2.2, true)

		# Knee rotary joint disc
		draw_circle(Vector2(fx + kb, -88.0), 8.0, CHASSIS_DARK)
		draw_arc(Vector2(fx + kb, -88.0), 8.0, 0.0, TAU, 14, PANEL_LINE, 2.0, true)
		draw_circle(Vector2(fx + kb, -88.0), 3.0, led_col)

		# Chamfered Mecha Thruster Boot
		var boot := PackedVector2Array([
			Vector2(fx - 10.0, -26.0), Vector2(fx + 10.0, -26.0),
			Vector2(fx + 19.0 * float(side) + 5.0, -7.0),
			Vector2(fx + 18.0 * float(side) + 5.0, 0.0),
			Vector2(fx - 12.0, 0.0),
		])
		draw_colored_polygon(boot, CHASSIS_DARK)
		draw_line(Vector2(fx - 8.0, -10.0), Vector2(fx + 10.0 * float(side), -10.0), led_col, 2.0, true)
		draw_polyline(_closed_outline(boot), PANEL_LINE, 2.2, true)

	# === TORSO ANCHOR (Hydraulic Waist + Chamfered Chest Carapace) ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -160.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x * (1.0 - absf(torso.twist) * 0.06), torso.breath_scale_y)
	)

	# Twin articulated energy-ribbon / fiber cables behind backpack (secondary_lag)
	var cable_xf := torso_xf * _xform(Vector2(-14.0, -86.0), lag.rot * 0.9)
	draw_set_transform_matrix(cable_xf)
	for ci in [0.0, 8.0]:
		var c_tip := Vector2(-36.0 + ci + lag.x * 1.2 + lag.flutter, 96.0 + lag.y * 0.9)
		var c_pts := PackedVector2Array([
			Vector2(ci, 0.0),
			Vector2(-14.0 + ci + lag.x * 0.5, 48.0 + lag.y * 0.4),
			c_tip,
		])
		draw_polyline(c_pts, CHASSIS_DARK, 4.5, true)
		draw_circle(c_tip, 3.2, led_col)

	# Back Mecha Arm
	_draw_mecha_arm(
		torso_xf,
		Vector2(-32.0 + torso.twist * 5.0, -90.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		led_col,
		false
	)

	draw_set_transform_matrix(torso_xf)
	var torso_h: float = 104.0

	# Segmented hydraulic spine abdomen
	draw_rect(Rect2(-15.0, -44.0, 30.0, 44.0), CHASSIS_DARK, true)
	for sy in [-36.0, -24.0, -12.0]:
		draw_rect(Rect2(-17.0, sy, 34.0, 7.0), TITANIUM_SH, true)
		draw_rect(Rect2(-17.0, sy, 34.0, 7.0), PANEL_LINE, false, 1.8)

	# Chamfered Chest Carapace Plate
	var chest := PackedVector2Array([
		Vector2(-34.0, -torso_h + 12.0),
		Vector2(-20.0, -torso_h),
		Vector2(20.0, -torso_h),
		Vector2(34.0, -torso_h + 12.0),
		Vector2(26.0, -42.0),
		Vector2(-26.0, -42.0),
	])
	draw_colored_polygon(chest, TITANIUM_LIT)
	# Left angled armor shadow plane
	draw_colored_polygon(PackedVector2Array([
		Vector2(-34.0, -torso_h + 12.0), Vector2(-20.0, -torso_h),
		Vector2(-4.0 + torso.twist * 8.0, -torso_h),
		Vector2(-6.0 + torso.twist * 8.0, -42.0), Vector2(-26.0, -42.0),
	]), TITANIUM_SH)
	# Cobalt shoulder armor trim & glowing core diamond
	var cx: float = torso.twist * 8.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, -torso_h + 16.0), Vector2(cx + 10.0, -torso_h + 28.0),
		Vector2(cx, -torso_h + 40.0), Vector2(cx - 10.0, -torso_h + 28.0),
	]), CHASSIS_DARK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, -torso_h + 21.0), Vector2(cx + 6.0, -torso_h + 28.0),
		Vector2(cx, -torso_h + 35.0), Vector2(cx - 6.0, -torso_h + 28.0),
	]), led_col)
	# Diagonal metallic specular bar
	draw_line(Vector2(14.0, -torso_h + 12.0), Vector2(26.0, -torso_h + 26.0), SPECULAR_BAR, 3.0, true)
	draw_polyline(_closed_outline(chest), PANEL_LINE, 2.4, true)

	# Armored collar ring + hydraulic neck cylinder
	draw_rect(Rect2(-9.0, -torso_h - 15.0, 18.0, 17.0), CHASSIS_DARK, true)
	draw_line(Vector2(-4.0, -torso_h - 13.0), Vector2(-4.0, -torso_h), TITANIUM_SH, 2.2, true)
	draw_line(Vector2(4.0, -torso_h - 13.0), Vector2(4.0, -torso_h), TITANIUM_LIT, 2.2, true)

	# === HEAD PIVOT ANCHOR (Chamfered Helmet + Dark LED Visor) ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -torso_h - 15.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 11.0
	var face_shift_y: float = pitch * 6.0

	# Articulated Ear Pods + Twin Antenna Fins (secondary_lag flutter!)
	for ear_side in [-1, 1]:
		var ear_vis: float = clampf(1.0 - float(ear_side) * yaw * 0.85, 0.15, 1.15)
		var ear_xf := head_xf * _xform(Vector2(float(ear_side) * 25.0 - yaw * 5.0, -28.0 + face_shift_y * 0.35), 0.0, Vector2(ear_vis, 1.0))
		draw_set_transform_matrix(ear_xf)
		draw_rect(Rect2(-5.0, -9.0, 10.0, 18.0), COBALT_ARMOR, true)
		draw_rect(Rect2(-5.0, -9.0, 10.0, 18.0), PANEL_LINE, false, 2.0)
		draw_line(Vector2(0.0, -9.0), Vector2(float(ear_side) * 4.0 + lag.x * 0.12, -32.0 + lag.y * 0.08), TITANIUM_LIT, 3.0, true)
		draw_circle(Vector2(float(ear_side) * 4.0 + lag.x * 0.12, -32.0 + lag.y * 0.08), 2.5, led_col)

	# Helmet Shell
	draw_set_transform_matrix(head_xf)
	var chin := Vector2(yaw * 5.0, 4.0 + pitch * 3.0)
	var helm := PackedVector2Array([
		Vector2(-24.0, -34.0), Vector2(-17.0, -58.0), Vector2(17.0, -58.0), Vector2(24.0, -34.0),
		Vector2(20.0 + yaw * 2.0, -10.0), chin + Vector2(6.0, 0.0), chin + Vector2(-6.0, 0.0), Vector2(-20.0 + yaw * 2.0, -10.0),
	])
	draw_colored_polygon(helm, TITANIUM_LIT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24.0, -34.0), Vector2(-17.0, -58.0), Vector2(-2.0 + face_shift_x * 0.4, -58.0),
		Vector2(-4.0 + face_shift_x * 0.4, 4.0), chin + Vector2(-6.0, 0.0), Vector2(-20.0 + yaw * 2.0, -10.0),
	]), TITANIUM_SH)
	# Cobalt crest fin
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4.0 + face_shift_x * 0.4, -62.0), Vector2(4.0 + face_shift_x * 0.4, -62.0),
		Vector2(3.0 + face_shift_x * 0.4, -44.0), Vector2(-3.0 + face_shift_x * 0.4, -44.0),
	]), COBALT_ARMOR)

	# Dark Glass Visor Plate (2.5D shifted!)
	var visor := PackedVector2Array([
		Vector2(-20.0 + face_shift_x * 0.65, -39.0 + face_shift_y * 0.6),
		Vector2(20.0 + face_shift_x * 0.65, -39.0 + face_shift_y * 0.6),
		Vector2(18.0 + face_shift_x * 0.75, -14.0 + face_shift_y * 0.8),
		Vector2(-18.0 + face_shift_x * 0.75, -14.0 + face_shift_y * 0.8),
	])
	draw_colored_polygon(visor, VISOR_GLASS)
	draw_line(
		Vector2(4.0 + face_shift_x * 0.65, -36.0 + face_shift_y * 0.6),
		Vector2(15.0 + face_shift_x * 0.72, -18.0 + face_shift_y * 0.8),
		Color(1.0, 1.0, 1.0, 0.16),
		3.5,
		true
	)
	draw_polyline(_closed_outline(visor), PANEL_LINE, 2.0, true)

	# === LED MATRIX VISOR EYES ===
	var eye_y: float = -27.0 + face_shift_y
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.35, 0.60, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.35, 0.60, 1.0)
	_draw_led_eye(head_xf, Vector2(-9.0 * left_fs + face_shift_x, eye_y), left_fs, eyes, led_col)
	_draw_led_eye(head_xf, Vector2(9.0 * right_fs + face_shift_x, eye_y), right_fs, eyes, led_col)

	# LED Equalizer / Mouth Bar on Lower Jaw Plate
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 1.0, -7.5 + face_shift_y * 1.0)))
	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			draw_arc(Vector2.ZERO, 4.5 + mouth.open * 2.5, 0.0, TAU, 14, led_col, 2.4, true)
		MotionController.MouthShape.OPEN_HAPPY:
			draw_polyline(PackedVector2Array([Vector2(-6.5, -1.0), Vector2(0.0, 3.5), Vector2(6.5, -1.0)]), led_col, 2.4, true)
		MotionController.MouthShape.SMILE:
			draw_polyline(PackedVector2Array([Vector2(-5.5, -0.5), Vector2(0.0, 2.0), Vector2(5.5, -0.5)]), led_col, 2.0, true)
		_:
			draw_line(Vector2(-4.5, 0.0), Vector2(4.5, 0.0), led_col, 1.8, true)

	draw_set_transform_matrix(head_xf)
	draw_polyline(_closed_outline(helm), PANEL_LINE, 2.4, true)

	# Front Mecha Arm
	_draw_mecha_arm(
		torso_xf,
		Vector2(32.0 + torso.twist * 5.0, -90.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		led_col,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_led_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor,
	led_col: Color
) -> void:
	draw_set_transform_matrix(head_xf * _xform(eye_pos))
	var gx: float = clampf(eyes.look_x * 2.5 * foreshorten_x, -3.5, 3.5)
	var gy: float = clampf(eyes.look_y * 1.5, -2.5, 2.5)
	var w: float = 5.4 * foreshorten_x
	var h: float = 4.2 * (1.0 + eyes.wide * 0.45) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.92)

	if eyes.blink > 0.78:
		draw_line(Vector2(gx - w * 0.85, gy), Vector2(gx + w * 0.85, gy), led_col, 2.2, true)
		return

	if eyes.squint > 0.45 and eyes.wide < 0.2:
		draw_polyline(PackedVector2Array([Vector2(gx - w * 0.8, gy + 1.5), Vector2(gx, gy - 3.5), Vector2(gx + w * 0.8, gy + 1.5)]), led_col, 2.6, true)
		return

	if eyes.wide > 0.35:
		draw_arc(Vector2(gx, gy), minf(w, h) * 0.95, 0.0, TAU, 16, led_col, 2.2, true)
		draw_circle(Vector2(gx, gy), 1.6, led_col)
		return

	draw_colored_polygon(_ellipse_pts(Vector2(gx, gy), w * 0.85, h, 12), led_col)
	draw_circle(Vector2(gx, gy), minf(w, h) * 0.42, Color.WHITE)


func _draw_mecha_arm(
	torso_xf: Transform2D,
	shoulder_pos: Vector2,
	shoulder_angle: float,
	elbow_angle: float,
	hand_pose: int,
	wave_phase: float,
	led_col: Color,
	is_front: bool
) -> void:
	var upper_len: float = 50.0
	var fore_len: float = 48.0

	var upper_xf := torso_xf * _xform(shoulder_pos, shoulder_angle)
	draw_set_transform_matrix(upper_xf)

	# Rounded Pauldron Shoulder Armor
	var pauldron := PackedVector2Array([
		Vector2(-12.0, -10.0), Vector2(12.0, -10.0),
		Vector2(13.0, 12.0), Vector2(-11.0, 12.0),
	])
	draw_colored_polygon(pauldron, COBALT_ARMOR if is_front else COBALT_SH)
	draw_polyline(_closed_outline(pauldron), PANEL_LINE, 2.2, true)

	# Hydraulic Upper Arm Frame
	draw_rect(Rect2(-5.5, 10.0, 11.0, upper_len - 10.0), CHASSIS_DARK, true)
	draw_rect(Rect2(-5.5, 10.0, 11.0, upper_len - 10.0), PANEL_LINE, false, 1.8)

	var fore_xf := upper_xf * _xform(Vector2(0.0, upper_len - 2.0), elbow_angle)
	draw_set_transform_matrix(fore_xf)
	# Elbow servo circle
	draw_circle(Vector2.ZERO, 6.5, CHASSIS_DARK)
	draw_arc(Vector2.ZERO, 6.5, 0.0, TAU, 12, PANEL_LINE, 1.8, true)

	# Beveled Forearm Gauntlet
	var gauntlet := PackedVector2Array([
		Vector2(-8.0, 4.0), Vector2(8.0, 4.0),
		Vector2(6.5, fore_len - 6.0), Vector2(-6.5, fore_len - 6.0),
	])
	draw_colored_polygon(gauntlet, TITANIUM_LIT if is_front else TITANIUM_SH)
	draw_line(Vector2(0.0, 10.0), Vector2(0.0, fore_len - 12.0), led_col, 2.0, true)
	draw_polyline(_closed_outline(gauntlet), PANEL_LINE, 2.0, true)

	var hand_rot: float = wave_phase * 0.20 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0
	draw_set_transform_matrix(fore_xf * _xform(Vector2(0.0, fore_len - 4.0), hand_rot))
	var hand := PackedVector2Array([
		Vector2(-5.5, 0.0), Vector2(5.5, 0.0),
		Vector2(6.5, 9.0), Vector2(0.0, 15.0), Vector2(-6.5, 9.0),
	])
	draw_colored_polygon(hand, CHASSIS_DARK)
	draw_polyline(_closed_outline(hand), PANEL_LINE, 1.8, true)
