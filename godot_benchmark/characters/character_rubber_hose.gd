class_name CharacterRubberHose
extends Node2D

const STYLE_TITLE: String = "1930s Rubber Hose"
const STYLE_SUBTITLE: String = "Curved Hose Limbs · Pie-Cut Eyes · Vintage Ink"

const INK := Color(0.067, 0.063, 0.078, 1.0)         # #111014 soot black
const CREAM := Color(0.961, 0.937, 0.878, 1.0)       # #F5EFE0 vintage cream
const CREAM_SH := Color(0.847, 0.808, 0.722, 1.0)    # #D8CEB8
const VEST_GRAY := Color(0.240, 0.227, 0.235, 1.0)   # #3D3A3C charcoal shorts/vest
const MUZZLE := Color(0.980, 0.957, 0.902, 1.0)

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 156.0 * s
	var h: float = 330.0 * s
	return Rect2(position.x + bx * s - w * 0.5, position.y + by * s - h, w, h)


static func _xform(pos: Vector2, rot: float = 0.0, scl: Vector2 = Vector2.ONE) -> Transform2D:
	return Transform2D(0.0, pos) * Transform2D(rot, Vector2.ZERO) * Transform2D.IDENTITY.scaled(scl)


static func _quad_pts(p0: Vector2, p1: Vector2, p2: Vector2, steps: int = 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var omt: float = 1.0 - t
		pts.append(omt * omt * p0 + 2.0 * omt * t * p1 + t * t * p2)
	return pts


static func _closed_outline(poly: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = poly.duplicate()
	if poly.size() > 0:
		out.append(poly[0])
	return out


static func _ellipse_pts(center: Vector2, rx: float, ry: float, segments: int = 22) -> PackedVector2Array:
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

	# Ink pool ground shadow
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	draw_set_transform_matrix(_xform(
		Vector2(body_root.x * 0.7, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.42, 1.0 - air_factor * 0.35)
	))
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 52.0, 11.0, 22), Color(0.05, 0.05, 0.06, 0.42))

	# Bouncy rubber-hose squash/stretch
	var sx: float = 1.0 + (body_root.scale_x - 1.0) * 1.2
	var sy: float = 1.0 + (body_root.scale_y - 1.0) * 1.2
	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean,
		Vector2(sx, sy)
	)
	draw_set_transform_matrix(root_xf)

	# === CURVED RUBBER-HOSE LEGS & HUGE VINTAGE TOON SHOES ===
	var knee_bend: float = clampf((1.0 - body_root.scale_y) * 32.0, -10.0, 22.0)
	for side in [-1, 1]:
		var is_back: bool = side == -1
		var hip := Vector2(float(side) * 14.0, -110.0)
		var ankle := Vector2(float(side) * 20.0, -24.0)
		var knee_ctrl := Vector2(float(side) * (24.0 + knee_bend * 0.9), -68.0)
		var hose_pts := _quad_pts(hip, knee_ctrl, ankle, 10)
		draw_polyline(hose_pts, INK, 11.0 if not is_back else 10.0, true)

		# Oversized bulbous toon shoe with curved toe highlight
		var shoe_c := Vector2(ankle.x + float(side) * 8.0, -11.0)
		var shoe_pts := _ellipse_pts(shoe_c, 22.0, 12.5, 20)
		draw_colored_polygon(shoe_pts, CREAM_SH if is_back else VEST_GRAY)
		draw_polyline(_closed_outline(shoe_pts), INK, 3.2, true)
		if not is_back:
			draw_polyline(_quad_pts(shoe_c + Vector2(3.0, -7.0), shoe_c + Vector2(13.0, -6.0), shoe_c + Vector2(14.0, -1.0), 5), CREAM, 2.5, true)

	# === TORSO ANCHOR (Bean-shaped cartoon torso + 2 pearl buttons + bow-tie) ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -108.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x, torso.breath_scale_y)
	)

	# Floppy rubber-hose cartoon tail (secondary_lag!)
	var tail_xf := torso_xf * _xform(Vector2(-24.0, -14.0), lag.rot * 0.9)
	draw_set_transform_matrix(tail_xf)
	var tail_pts := _quad_pts(
		Vector2.ZERO,
		Vector2(-32.0 + lag.x * 0.7, 14.0 + lag.y * 0.5),
		Vector2(-52.0 + lag.x * 1.2 + lag.flutter, -14.0 + lag.y * 0.85),
		10
	)
	draw_polyline(tail_pts, INK, 5.5, true)
	draw_circle(tail_pts[tail_pts.size() - 1], 4.5, INK)

	# Back hose arm
	_draw_hose_arm(
		torso_xf,
		Vector2(-24.0 + torso.twist * 4.0, -72.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		false
	)

	draw_set_transform_matrix(torso_xf)
	# Bean torso
	var torso_pts := _ellipse_pts(Vector2(0.0, -44.0), 30.0, 44.0, 24)
	draw_colored_polygon(torso_pts, INK)

	# Cartoon shorts / overalls lower half
	var pants_pts := _ellipse_pts(Vector2(0.0, -16.0), 31.0, 22.0, 20)
	draw_colored_polygon(pants_pts, VEST_GRAY)
	draw_polyline(_closed_outline(pants_pts), INK, 3.2, true)

	# Two classic white oval buttons
	draw_colored_polygon(_ellipse_pts(Vector2(-10.0 + torso.twist * 8.0, -24.0), 4.0, 5.5, 12), CREAM)
	draw_colored_polygon(_ellipse_pts(Vector2(10.0 + torso.twist * 8.0, -24.0), 4.0, 5.5, 12), CREAM)

	# White cartoon shirt chest bib
	draw_colored_polygon(_ellipse_pts(Vector2(torso.twist * 6.0, -64.0), 17.0, 22.0, 18), CREAM)

	# Bouncy vintage bow-tie (secondary_lag)
	var bow_xf := torso_xf * _xform(Vector2(torso.twist * 6.0, -82.0), lag.rot * 0.45)
	draw_set_transform_matrix(bow_xf)
	var bow_poly := PackedVector2Array([
		Vector2(-14.0, -8.0), Vector2(0.0, -2.0), Vector2(14.0, -8.0),
		Vector2(14.0, 8.0), Vector2(0.0, 2.0), Vector2(-14.0, 8.0),
	])
	draw_colored_polygon(bow_poly, VEST_GRAY)
	draw_polyline(_closed_outline(bow_poly), INK, 2.6, true)
	draw_circle(Vector2.ZERO, 4.0, CREAM)
	draw_arc(Vector2.ZERO, 4.0, 0.0, TAU, 10, INK, 2.2, true)

	# === HEAD PIVOT ANCHOR ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -86.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 14.0
	var face_shift_y: float = pitch * 7.5

	# Floppy 1930s cartoon ears reacting to secondary_lag!
	for ear_side in [-1, 1]:
		var ear_xf := head_xf * _xform(
			Vector2(float(ear_side) * 32.0, -76.0),
			float(ear_side) * 0.35 + lag.rot * 0.85
		)
		draw_set_transform_matrix(ear_xf)
		var ear_pts := _ellipse_pts(Vector2(lag.x * 0.12, -16.0 + lag.y * 0.12), 14.0, 24.0, 18)
		draw_colored_polygon(ear_pts, INK)

	# Classic round ink head with cream face mask
	draw_set_transform_matrix(head_xf)
	var head_circle := _ellipse_pts(Vector2(0.0, -44.0), 46.0, 42.0, 28)
	draw_colored_polygon(head_circle, INK)

	# Cream face mask (widow's peak + puffy cheeks shifting with 2.5D yaw)
	var mask_c := Vector2(face_shift_x * 0.75, -30.0 + face_shift_y * 0.5)
	draw_colored_polygon(_ellipse_pts(mask_c + Vector2(-14.0, -14.0), 18.0, 20.0, 16), MUZZLE)
	draw_colored_polygon(_ellipse_pts(mask_c + Vector2(14.0, -14.0), 18.0, 20.0, 16), MUZZLE)
	draw_colored_polygon(_ellipse_pts(mask_c + Vector2(0.0, 8.0), 38.0, 22.0, 24), MUZZLE)

	# === PIE-CUT VINTAGE CARTOON EYES ===
	var eye_y: float = -44.0 + face_shift_y
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.32, 0.62, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.32, 0.62, 1.0)
	_draw_pie_eye(head_xf, Vector2(-12.5 * left_fs + face_shift_x, eye_y), left_fs, eyes)
	_draw_pie_eye(head_xf, Vector2(12.5 * right_fs + face_shift_x, eye_y), right_fs, eyes)

	# Glossy oval toon nose
	draw_set_transform_matrix(head_xf)
	var nose_pos := Vector2(face_shift_x * 1.2, -26.0 + face_shift_y * 1.1)
	draw_colored_polygon(_ellipse_pts(nose_pos, 9.0, 6.0, 14), INK)
	draw_circle(nose_pos + Vector2(-2.8, -1.8), 2.0, CREAM)

	# === EXPRESSIVE CARTOON MOUTH ===
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 1.05, -14.0 + face_shift_y * 1.1)))
	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			var m_pts := _ellipse_pts(Vector2(0.0, 2.0), 9.0 + mouth.open * 4.0, 10.0 + mouth.open * 6.0, 16)
			draw_colored_polygon(m_pts, INK)
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 6.0 + mouth.open * 3.0), 5.0, 3.5, 10), CREAM_SH)
		MotionController.MouthShape.OPEN_HAPPY:
			var grin := PackedVector2Array([
				Vector2(-18.0, -2.0), Vector2(18.0, -2.0),
				Vector2(14.0, 14.0 * mouth.open + 4.0), Vector2(0.0, 17.0 * mouth.open + 5.0), Vector2(-14.0, 14.0 * mouth.open + 4.0),
			])
			draw_colored_polygon(grin, INK)
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 10.0 * mouth.open + 1.5), 8.0, 4.0, 12), CREAM_SH)
			draw_polyline(_quad_pts(Vector2(-15.0, 0.0), Vector2(0.0, 4.0), Vector2(15.0, 0.0), 6), CREAM, 3.0, true)
		MotionController.MouthShape.SMILE:
			draw_polyline(_quad_pts(Vector2(-14.0, -1.0), Vector2(0.0, 7.0), Vector2(14.0, -1.0), 8), INK, 3.0, true)
		_:
			draw_polyline(_quad_pts(Vector2(-11.0, 0.0), Vector2(0.0, 4.0), Vector2(11.0, 0.0), 6), INK, 2.8, true)

	# Front hose arm
	_draw_hose_arm(
		torso_xf,
		Vector2(24.0 + torso.twist * 4.0, -72.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_pie_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor
) -> void:
	draw_set_transform_matrix(head_xf * _xform(eye_pos))
	var w: float = 9.5 * foreshorten_x
	var h: float = 15.5 * (1.0 + eyes.wide * 0.25) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.94)

	# Expressive floating toon brow arcs
	var brow_y: float = -18.0 - eyes.brow_offset * 6.0 + eyes.squint * 2.0
	draw_polyline(_quad_pts(Vector2(-w * 0.7, brow_y + 1.5), Vector2(0.0, brow_y - 3.5), Vector2(w * 0.7, brow_y + 1.5), 6), INK, 2.5, true)

	if eyes.blink > 0.78:
		draw_polyline(_quad_pts(Vector2(-w * 0.85, 2.0), Vector2(0.0, 6.0), Vector2(w * 0.85, 2.0), 6), INK, 3.2, true)
		return

	if eyes.squint > 0.45 and eyes.wide < 0.2:
		draw_polyline(_quad_pts(Vector2(-w * 0.85, 3.0), Vector2(0.0, -9.0), Vector2(w * 0.85, 3.0), 7), INK, 3.5, true)
		return

	var scl := _ellipse_pts(Vector2.ZERO, w, h, 18)
	draw_colored_polygon(scl, CREAM)
	draw_polyline(_closed_outline(scl), INK, 2.4, true)

	# Authentic 1930s Pie-Cut pupil (with wedge cutout!)
	var gx: float = clampf(eyes.look_x * 3.5 * foreshorten_x, -w * 0.35, w * 0.35)
	var gy: float = clampf(eyes.look_y * 3.5, -h * 0.25, h * 0.25)
	var pw: float = minf(5.2 * foreshorten_x * (1.0 - eyes.wide * 0.32 if eyes.wide > 0.2 else 1.0), w * 0.65)
	var ph: float = minf(8.2 * (1.0 - eyes.wide * 0.32 if eyes.wide > 0.2 else 1.0), h * 0.62)
	var pc := Vector2(gx, gy)

	var pie_pts := PackedVector2Array([pc])
	var start_a: float = 0.28
	var end_a: float = TAU - 0.36
	for si in range(15):
		var a: float = lerpf(start_a, end_a, float(si) / 14.0)
		pie_pts.append(pc + Vector2(cos(a) * pw, sin(a) * ph))
	draw_colored_polygon(pie_pts, INK)


func _draw_hose_arm(
	torso_xf: Transform2D,
	shoulder_pos: Vector2,
	shoulder_angle: float,
	elbow_angle: float,
	hand_pose: int,
	wave_phase: float,
	is_front: bool
) -> void:
	# Compute rubber-hose Bezier curve from shoulder -> curved elbow -> wrist!
	var upper_len: float = 44.0
	var fore_len: float = 42.0

	var p0: Vector2 = shoulder_pos
	var dir1 := Vector2(-sin(shoulder_angle), cos(shoulder_angle))
	var elbow: Vector2 = p0 + dir1 * upper_len
	var dir2 := Vector2(-sin(shoulder_angle + elbow_angle), cos(shoulder_angle + elbow_angle))
	var wrist: Vector2 = elbow + dir2 * fore_len

	draw_set_transform_matrix(torso_xf)
	var arm_curve := _quad_pts(p0, elbow, wrist, 12)
	draw_polyline(arm_curve, INK, 10.5 if is_front else 9.5, true)

	# Classic 3-stripe white toon glove!
	var hand_angle: float = shoulder_angle + elbow_angle + (wave_phase * 0.25 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0)
	var hand_xf := torso_xf * _xform(wrist, hand_angle)
	draw_set_transform_matrix(hand_xf)
	var glove_col: Color = CREAM if is_front else CREAM_SH

	# Glove cuff ring
	var cuff := _ellipse_pts(Vector2(0.0, 1.0), 8.5, 4.5, 12)
	draw_colored_polygon(cuff, glove_col)
	draw_polyline(_closed_outline(cuff), INK, 2.4, true)

	# Puffy 4-finger cartoon glove
	var glove := _ellipse_pts(Vector2(0.0, 11.0), 11.5 if hand_pose != MotionController.HandPose.RELAXED else 9.5, 11.0, 16)
	draw_colored_polygon(glove, glove_col)
	draw_polyline(_closed_outline(glove), INK, 2.8, true)
	# 3 iconic glove knuckle lines
	draw_line(Vector2(-4.0, 6.0), Vector2(-3.0, 12.0), INK, 2.0, true)
	draw_line(Vector2(0.0, 5.5), Vector2(0.0, 12.0), INK, 2.0, true)
	draw_line(Vector2(4.0, 6.0), Vector2(3.0, 12.0), INK, 2.0, true)
