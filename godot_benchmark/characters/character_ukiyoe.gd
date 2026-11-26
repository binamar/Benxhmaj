class_name CharacterUkiyoe
extends Node2D

const STYLE_TITLE: String = "Ukiyo-e Woodblock"
const STYLE_SUBTITLE: String = "Sumi Brush Lines · Kimono Patterns · Mineral Palette"

# Traditional Japanese woodblock mineral pigment palette
const SUMI := Color(0.114, 0.098, 0.094, 1.0)         # #1D1918 sumi ink
const WASHI := Color(0.953, 0.918, 0.847, 1.0)        # #F3EAD8 rice paper skin/tabi
const WASHI_SH := Color(0.875, 0.816, 0.710, 1.0)
const INDIGO := Color(0.118, 0.227, 0.373, 1.0)       # #1E3A5F aizome indigo kimono
const INDIGO_DEEP := Color(0.075, 0.145, 0.251, 1.0)
const VERMILION := Color(0.725, 0.220, 0.173, 1.0)    # #B9382C shu vermilion
const OCHRE := Color(0.784, 0.541, 0.212, 1.0)        # #C88A36 warm ochre obi
const MOSS := Color(0.306, 0.420, 0.322, 1.0)         # #4E6B52 mineral green

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 156.0 * s
	var h: float = 358.0 * s
	return Rect2(position.x + bx * s - w * 0.5, position.y + by * s - h, w, h)


static func _xform(pos: Vector2, rot: float = 0.0, scl: Vector2 = Vector2.ONE) -> Transform2D:
	return Transform2D(0.0, pos) * Transform2D(rot, Vector2.ZERO) * Transform2D.IDENTITY.scaled(scl)


static func _quad_pts(p0: Vector2, p1: Vector2, p2: Vector2, steps: int = 8) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var omt: float = 1.0 - t
		pts.append(omt * omt * p0 + 2.0 * omt * t * p1 + t * t * p2)
	return pts


static func _append_quad(arr: PackedVector2Array, p0: Vector2, p1: Vector2, p2: Vector2, steps: int = 8) -> void:
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var omt: float = 1.0 - t
		arr.append(omt * omt * p0 + 2.0 * omt * t * p1 + t * t * p2)


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

	# Subtle woodblock oval shadow
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	draw_set_transform_matrix(_xform(
		Vector2(body_root.x * 0.7, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.42, 1.0 - air_factor * 0.35)
	))
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 52.0, 10.0, 20), Color(0.08, 0.07, 0.06, 0.34))

	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean,
		Vector2(body_root.scale_x, body_root.scale_y)
	)
	draw_set_transform_matrix(root_xf)

	# === TABI SOCKS & GETA WOODEN SANDALS ===
	for side in [-1, 1]:
		var fx: float = float(side) * 15.0
		# White tabi foot
		var tabi := PackedVector2Array([
			Vector2(fx - 7.0, -34.0), Vector2(fx + 7.0, -34.0),
			Vector2(fx + 14.0 * float(side) + 3.0, -10.0),
			Vector2(fx - 8.0, -10.0),
		])
		draw_colored_polygon(tabi, WASHI)
		draw_polyline(_closed_outline(tabi), SUMI, 2.1, true)
		# Geta sandal platform & twin wooden teeth
		draw_rect(Rect2(fx - 12.0, -11.0, 26.0, 4.5), OCHRE, true)
		draw_rect(Rect2(fx - 12.0, -11.0, 26.0, 4.5), SUMI, false, 2.0)
		draw_rect(Rect2(fx - 8.0, -6.5, 5.0, 6.5), SUMI, true)
		draw_rect(Rect2(fx + 4.0, -6.5, 5.0, 6.5), SUMI, true)
		# Red hanao sandal strap
		draw_line(Vector2(fx, -11.0), Vector2(fx + 6.0 * float(side), -18.0), VERMILION, 3.0, true)

	# === FLOWING KIMONO ROBE SKIRT (reacts smoothly to secondary_lag) ===
	var hem_l := Vector2(-36.0 + lag.x * 0.32, -26.0 + lag.y * 0.2)
	var hem_r := Vector2(36.0 + lag.x * 0.32, -24.0 + lag.y * 0.2)
	var skirt := PackedVector2Array([
		Vector2(-24.0, -148.0 + torso.offset_y),
		Vector2(24.0, -148.0 + torso.offset_y),
		hem_r,
		Vector2(6.0 + lag.x * 0.3, -22.0 + lag.y * 0.2),
		hem_l,
	])
	draw_colored_polygon(skirt, INDIGO)
	# Inner vermilion kimono under-hem flash
	draw_colored_polygon(PackedVector2Array([
		hem_l + Vector2(6.0, -2.0),
		Vector2(6.0 + lag.x * 0.3, -22.0 + lag.y * 0.2),
		Vector2(18.0 + lag.x * 0.3, -24.0 + lag.y * 0.2),
		Vector2(12.0 + lag.x * 0.25, -44.0),
	]), VERMILION)
	# Traditional wave/diamond mineral trim along kimono hem
	for ti in range(-28, 32, 14):
		draw_arc(Vector2(float(ti) + lag.x * 0.3, -32.0 + lag.y * 0.2), 6.0, PI, TAU, 8, OCHRE, 1.8, true)
	draw_polyline(_closed_outline(skirt), SUMI, 2.8, true)

	# === TORSO ANCHOR (Layered Kimono, Haori, & Wide Obi Sash) ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -146.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x * (1.0 - absf(torso.twist) * 0.06), torso.breath_scale_y)
	)

	# Back Obi Bow Ribbons (secondary_lag behind torso)
	var obi_xf := torso_xf * _xform(Vector2(-16.0, -18.0), lag.rot * 0.8)
	draw_set_transform_matrix(obi_xf)
	var obi_tail := PackedVector2Array([
		Vector2(-4.0, 0.0), Vector2(10.0, 4.0),
		Vector2(-18.0 + lag.x * 1.1 + lag.flutter, 76.0 + lag.y * 0.8),
		Vector2(-32.0 + lag.x * 1.15 + lag.flutter, 66.0 + lag.y * 0.75),
	])
	draw_colored_polygon(obi_tail, OCHRE)
	draw_polyline(_closed_outline(obi_tail), SUMI, 2.4, true)

	# Back kimono sleeve + arm
	_draw_ukiyoe_arm(
		torso_xf,
		Vector2(-26.0 + torso.twist * 5.0, -88.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		lag,
		false
	)

	draw_set_transform_matrix(torso_xf)
	var torso_h: float = 98.0
	var robe_top := PackedVector2Array([
		Vector2(-27.0, -torso_h + 6.0),
		Vector2(27.0, -torso_h + 6.0),
		Vector2(24.0, 2.0),
		Vector2(-24.0, 2.0),
	])
	draw_colored_polygon(robe_top, INDIGO)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-27.0, -torso_h + 6.0), Vector2(-6.0, -torso_h + 6.0),
		Vector2(-8.0, 2.0), Vector2(-24.0, 2.0),
	]), INDIGO_DEEP)

	# Crossed Kimono V-Collar (left over right!) + White Under-collar + Vermilion lining
	var cx: float = torso.twist * 7.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13.0 + cx, -torso_h), Vector2(13.0 + cx, -torso_h),
		Vector2(cx, -54.0),
	]), WASHI)
	draw_polyline(PackedVector2Array([
		Vector2(-15.0 + cx, -torso_h + 2.0), Vector2(cx + 4.0, -48.0),
	]), VERMILION, 5.0, true)
	draw_polyline(PackedVector2Array([
		Vector2(15.0 + cx, -torso_h + 2.0), Vector2(cx - 2.0, -54.0),
	]), MOSS, 5.0, true)
	draw_polyline(_closed_outline(robe_top), SUMI, 2.8, true)

	# Wide Ochre Obi Sash + Obijime Cord
	draw_rect(Rect2(-24.5, -34.0, 49.0, 24.0), OCHRE, true)
	draw_rect(Rect2(-24.5, -34.0, 49.0, 24.0), SUMI, false, 2.4)
	draw_line(Vector2(-24.5, -22.0), Vector2(24.5, -22.0), VERMILION, 3.0, true)
	draw_circle(Vector2(cx, -22.0), 4.0, WASHI)
	draw_arc(Vector2(cx, -22.0), 4.0, 0.0, TAU, 10, SUMI, 1.8, true)

	# Neck
	draw_rect(Rect2(-7.0, -torso_h - 14.0, 14.0, 16.0), WASHI, true)
	draw_rect(Rect2(-7.0, -torso_h - 14.0, 14.0, 16.0), SUMI, false, 2.2)

	# === HEAD PIVOT ANCHOR ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -torso_h - 14.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 11.0
	var face_shift_y: float = pitch * 6.0

	# Traditional Topknot Chignon + Kanzashi Hairpin Tassel (secondary_lag)
	var bun_xf := head_xf * _xform(Vector2(-yaw * 4.0, -64.0), lag.rot * 0.25)
	draw_set_transform_matrix(bun_xf)
	var bun := _ellipse_pts(Vector2.ZERO, 14.0, 12.0, 16)
	draw_colored_polygon(bun, SUMI)
	# Vermilion kanzashi stick & swaying tassel
	draw_line(Vector2(-22.0, 2.0), Vector2(22.0, -6.0), OCHRE, 3.2, true)
	draw_circle(Vector2(22.0, -6.0), 4.5, VERMILION)
	var tas_end := Vector2(24.0 + lag.x * 0.45 + lag.flutter * 0.4, 24.0 + lag.y * 0.35)
	draw_polyline(_quad_pts(Vector2(22.0, -4.0), Vector2(24.0 + lag.x * 0.2, 10.0), tas_end, 6), VERMILION, 2.6, true)

	# Classical Ukiyo-e Oval Face Contour
	draw_set_transform_matrix(head_xf)
	var chin := Vector2(yaw * 5.0, 4.0 + pitch * 3.5)
	var head_poly := PackedVector2Array([Vector2(-22.0, -34.0)])
	_append_quad(head_poly, Vector2(-22.0, -34.0), Vector2(-22.0, -58.0), Vector2(0.0, -58.0), 7)
	_append_quad(head_poly, Vector2(0.0, -58.0), Vector2(22.0, -58.0), Vector2(22.0, -34.0), 7)
	_append_quad(head_poly, Vector2(22.0, -34.0), Vector2(20.0, -8.0), chin, 7)
	_append_quad(head_poly, chin, Vector2(-20.0, -8.0), Vector2(-22.0, -34.0), 7)
	draw_colored_polygon(head_poly, WASHI)
	draw_polyline(_closed_outline(head_poly), SUMI, 2.5, true)

	# === TRADITIONAL UKIYO-E NARROW UPTURNED EYES ===
	var eye_y: float = -26.0 + face_shift_y
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.35, 0.60, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.35, 0.60, 1.0)
	_draw_ukiyoe_eye(head_xf, Vector2(-9.5 * left_fs + face_shift_x, eye_y), -1, left_fs, eyes)
	_draw_ukiyoe_eye(head_xf, Vector2(9.5 * right_fs + face_shift_x, eye_y), 1, right_fs, eyes)

	# Classic woodblock calligraphic nose bridge line
	draw_set_transform_matrix(head_xf)
	var nx: float = face_shift_x * 1.15
	var ny: float = -25.0 + face_shift_y
	draw_polyline(_quad_pts(Vector2(nx, ny), Vector2(nx + 3.0, ny + 8.0), Vector2(nx + 0.5, ny + 10.5), 6), SUMI, 1.7, true)

	# Vermilion Beni-style Traditional Mouth
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 1.05, -6.8 + face_shift_y * 1.1)))
	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			var m_pts := _ellipse_pts(Vector2(0.0, 1.0), 3.6 + mouth.open * 2.0, 4.0 + mouth.open * 3.5, 12)
			draw_colored_polygon(m_pts, SUMI)
			draw_polyline(_closed_outline(m_pts), VERMILION, 1.8, true)
		MotionController.MouthShape.OPEN_HAPPY:
			var d_pts := PackedVector2Array([Vector2(-5.5, -0.5), Vector2(5.5, -0.5), Vector2(4.0, 5.5 * mouth.open + 1.5), Vector2(-4.0, 5.5 * mouth.open + 1.5)])
			draw_colored_polygon(d_pts, VERMILION)
			draw_polyline(_closed_outline(d_pts), SUMI, 1.6, true)
		MotionController.MouthShape.SMILE:
			draw_polyline(_quad_pts(Vector2(-5.5, 0.0), Vector2(0.0, 2.5), Vector2(5.5, -0.5), 5), VERMILION, 2.2, true)
		_:
			draw_colored_polygon(PackedVector2Array([
				Vector2(-4.5, 0.5), Vector2(-1.5, -1.0), Vector2(0.0, -0.2), Vector2(1.5, -1.0), Vector2(4.5, 0.5), Vector2(0.0, 2.2)
			]), VERMILION)

	# Swept Traditional Side-Wings Hairline
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 0.35, 0.0)))
	var hair_top := PackedVector2Array([
		Vector2(-24.0, -28.0), Vector2(-27.0, -46.0), Vector2(-16.0, -61.0),
		Vector2(16.0, -61.0), Vector2(27.0, -46.0), Vector2(24.0, -28.0),
		Vector2(18.0, -44.0), Vector2(0.0, -48.0), Vector2(-18.0, -44.0),
	])
	draw_colored_polygon(hair_top, SUMI)

	# Front kimono sleeve + arm
	_draw_ukiyoe_arm(
		torso_xf,
		Vector2(26.0 + torso.twist * 5.0, -88.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		lag,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_ukiyoe_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	side: int,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor
) -> void:
	draw_set_transform_matrix(head_xf * _xform(eye_pos))
	var w: float = 6.8 * foreshorten_x
	var h: float = 2.8 * (1.0 + eyes.wide * 0.85) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.92)

	var brow_y: float = -7.0 - eyes.brow_offset * 3.5 + eyes.squint * 1.0
	draw_polyline(_quad_pts(Vector2(-w, brow_y + 1.0), Vector2(0.0, brow_y - 1.5), Vector2(w, brow_y), 5), SUMI, 2.0, true)

	if eyes.blink > 0.78:
		draw_line(Vector2(-w, 0.5), Vector2(w, -0.5), SUMI, 2.2, true)
		return

	var scl := PackedVector2Array([
		Vector2(-w, h * 0.16), Vector2(0.0, -h), Vector2(w, -h * 0.24), Vector2(0.0, h * 0.85),
	])
	draw_colored_polygon(scl, Color.WHITE)
	var gx: float = clampf(eyes.look_x * 2.4 * foreshorten_x, -w * 0.4, w * 0.4)
	var gy: float = clampf(eyes.look_y * 1.0, -h * 0.2, h * 0.2)
	var pr: float = minf(2.2, maxf(1.4, h * 0.78))
	draw_circle(Vector2(gx, gy), pr, SUMI)
	# Subtle vermilion outer eye-corner beni accent
	draw_circle(Vector2(w * 0.85 * float(side), -0.4), 1.3, VERMILION)
	draw_polyline(_closed_outline(scl), SUMI, 2.0, true)


func _draw_ukiyoe_arm(
	torso_xf: Transform2D,
	shoulder_pos: Vector2,
	shoulder_angle: float,
	elbow_angle: float,
	hand_pose: int,
	wave_phase: float,
	lag: MotionController.SecondaryLagAnchor,
	is_front: bool
) -> void:
	var upper_len: float = 46.0
	var fore_len: float = 44.0

	var upper_xf := torso_xf * _xform(shoulder_pos, shoulder_angle)
	draw_set_transform_matrix(upper_xf)
	var u_poly := PackedVector2Array([
		Vector2(-9.0, -5.0), Vector2(9.0, -5.0),
		Vector2(10.0, upper_len), Vector2(-10.0, upper_len),
	])
	draw_colored_polygon(u_poly, INDIGO if is_front else INDIGO_DEEP)
	draw_polyline(_closed_outline(u_poly), SUMI, 2.6, true)

	var fore_xf := upper_xf * _xform(Vector2(0.0, upper_len - 2.0), elbow_angle)
	draw_set_transform_matrix(fore_xf)
	# Long square hanging kimono sleeve (furisode drape reacting to lag!)
	var sleeve_drop := PackedVector2Array([
		Vector2(-10.0, 0.0), Vector2(10.0, 0.0),
		Vector2(8.0, fore_len - 6.0),
		Vector2(-18.0 + lag.x * 0.25, fore_len + 18.0 + lag.y * 0.2),
		Vector2(-24.0 + lag.x * 0.25, 10.0),
	])
	draw_colored_polygon(sleeve_drop, INDIGO if is_front else INDIGO_DEEP)
	draw_line(Vector2(-18.0 + lag.x * 0.25, fore_len + 14.0 + lag.y * 0.2), Vector2(8.0, fore_len - 8.0), VERMILION, 3.0, true)
	draw_polyline(_closed_outline(sleeve_drop), SUMI, 2.6, true)

	var hand_rot: float = wave_phase * 0.20 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0
	draw_set_transform_matrix(fore_xf * _xform(Vector2(0.0, fore_len - 4.0), hand_rot))
	var h_poly := PackedVector2Array([
		Vector2(-4.5, 0.0), Vector2(4.5, 0.0),
		Vector2(5.5, 8.0), Vector2(0.0, 14.0), Vector2(-5.5, 8.0),
	])
	draw_colored_polygon(h_poly, WASHI if is_front else WASHI_SH)
	draw_polyline(_closed_outline(h_poly), SUMI, 2.1, true)
