class_name CharacterLinelessVector
extends Node2D

const STYLE_TITLE: String = "Lineless Flat Vector"
const STYLE_SUBTITLE: String = "Zero Outlines · Crisp Color Blocking · Geometric Planes"

# Modern editorial vector palette — ZERO ink strokes!
const SKIN_LIT := Color(0.961, 0.808, 0.706, 1.0)     # #F5CEB4
const SKIN_SH := Color(0.847, 0.631, 0.522, 1.0)      # #D8A185
const SKIN_DEEP := Color(0.718, 0.494, 0.400, 1.0)    # #B77E66

const HAIR_LIT := Color(0.118, 0.141, 0.290, 1.0)     # #1E244A deep indigo
const HAIR_HL := Color(0.220, 0.278, 0.498, 1.0)      # #38477F

const PONCHO_LIT := Color(0.925, 0.365, 0.271, 1.0)   # #EC5D45 coral-vermilion
const PONCHO_SH := Color(0.741, 0.235, 0.173, 1.0)    # #BD3C2C
const PONCHO_TRIM := Color(0.988, 0.788, 0.333, 1.0)  # #FCC955 warm gold band

const TURTLE_LIT := Color(0.976, 0.965, 0.933, 1.0)   # #F9F6EE cream turtleneck
const TURTLE_SH := Color(0.855, 0.835, 0.792, 1.0)

const PANTS_LIT := Color(0.165, 0.247, 0.435, 1.0)    # #2A3F6F cobalt slate
const PANTS_SH := Color(0.114, 0.169, 0.314, 1.0)     # #1D2B50
const BOOT_LIT := Color(0.133, 0.145, 0.212, 1.0)
const BOOT_SH := Color(0.086, 0.094, 0.145, 1.0)

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 148.0 * s
	var h: float = 356.0 * s
	return Rect2(position.x + bx * s - w * 0.5, position.y + by * s - h, w, h)


static func _xform(pos: Vector2, rot: float = 0.0, scl: Vector2 = Vector2.ONE) -> Transform2D:
	return Transform2D(0.0, pos) * Transform2D(rot, Vector2.ZERO) * Transform2D.IDENTITY.scaled(scl)


static func _ellipse_pts(center: Vector2, rx: float, ry: float, segments: int = 20) -> PackedVector2Array:
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

	# Crisp geometric flat shadow disc
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	draw_set_transform_matrix(_xform(
		Vector2(body_root.x * 0.7, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.42, 1.0 - air_factor * 0.35)
	))
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 50.0, 10.0, 24), Color(0.04, 0.05, 0.09, 0.36))

	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean,
		Vector2(body_root.scale_x, body_root.scale_y)
	)
	draw_set_transform_matrix(root_xf)

	# === CLEAN GEOMETRIC LEGS (ZERO OUTLINES) ===
	var knee_bend: float = clampf((1.0 - body_root.scale_y) * 26.0, -7.0, 15.0)
	for side in [-1, 1]:
		var is_back: bool = side == -1
		var fx: float = float(side) * 15.0
		var kb: float = knee_bend * 0.24 * float(side)
		var leg_poly := PackedVector2Array([
			Vector2(float(side) * 11.0 - 11.5, -148.0),
			Vector2(float(side) * 11.0 + 11.5, -148.0),
			Vector2(fx + 9.0 + kb, -76.0),
			Vector2(fx + 6.5, -20.0),
			Vector2(fx - 6.5, -20.0),
			Vector2(fx - 9.0 + kb, -76.0),
		])
		draw_colored_polygon(leg_poly, PANTS_SH if is_back else PANTS_LIT)
		if not is_back:
			draw_colored_polygon(PackedVector2Array([
				Vector2(float(side) * 11.0 - 11.5, -148.0),
				Vector2(float(side) * 11.0 - 1.0, -148.0),
				Vector2(fx - 1.0, -20.0),
				Vector2(fx - 6.5, -20.0),
			]), PANTS_SH)

		# Clean geometric boot block
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx - 8.0, -22.0),
			Vector2(fx + 8.0, -22.0),
			Vector2(fx + 18.0 * float(side) + 5.0, -4.0),
			Vector2(fx + 18.0 * float(side) + 5.0, 0.0),
			Vector2(fx - 10.0, 0.0),
		]), BOOT_SH if is_back else BOOT_LIT)

	# === TORSO ANCHOR ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -146.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x * (1.0 - absf(torso.twist) * 0.06), torso.breath_scale_y)
	)

	# Back floating poncho cape layer (secondary_lag)
	var back_cape_xf := torso_xf * _xform(Vector2(-6.0, -96.0), lag.rot * 0.78)
	draw_set_transform_matrix(back_cape_xf)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-26.0, 0.0),
		Vector2(26.0, 0.0),
		Vector2(40.0 + lag.x * 1.05 + lag.flutter, 118.0 + lag.y * 0.85),
		Vector2(-46.0 + lag.x * 1.15 + lag.flutter, 126.0 + lag.y * 0.9),
	]), PONCHO_SH)

	# Back arm
	_draw_vector_arm(
		torso_xf,
		Vector2(-29.0 + torso.twist * 5.0, -92.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		false
	)

	# Asymmetrical Geometric Poncho & Turtleneck Torso
	draw_set_transform_matrix(torso_xf)
	var torso_h: float = 100.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24.0, -torso_h),
		Vector2(24.0, -torso_h),
		Vector2(20.0, -10.0),
		Vector2(-20.0, -10.0),
	]), TURTLE_LIT)

	# Geometric Poncho Triangle Overlay reacting subtly to twist + secondary_lag
	var hem_l := Vector2(-42.0 + lag.x * 0.45, -24.0 + lag.y * 0.35)
	var hem_r := Vector2(44.0 + lag.x * 0.45, -38.0 + lag.y * 0.35)
	var hem_tip := Vector2(6.0 + torso.twist * 10.0 + lag.x * 0.55, 6.0 + lag.y * 0.45)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-30.0, -torso_h + 6.0),
		Vector2(30.0, -torso_h + 6.0),
		hem_r,
		hem_tip,
		hem_l,
	]), PONCHO_LIT)

	# Hard-edged geometric shadow facet on left poncho
	draw_colored_polygon(PackedVector2Array([
		Vector2(-30.0, -torso_h + 6.0),
		Vector2(-2.0 + torso.twist * 8.0, -torso_h + 6.0),
		hem_tip,
		hem_l,
	]), PONCHO_SH)

	# Gold graphic stripe band across poncho
	draw_colored_polygon(PackedVector2Array([
		hem_l.lerp(Vector2(-30.0, -torso_h + 6.0), 0.16),
		hem_tip.lerp(Vector2(0.0, -torso_h + 6.0), 0.16),
		hem_r.lerp(Vector2(30.0, -torso_h + 6.0), 0.16),
		hem_r.lerp(Vector2(30.0, -torso_h + 6.0), 0.07),
		hem_tip.lerp(Vector2(0.0, -torso_h + 6.0), 0.07),
		hem_l.lerp(Vector2(-30.0, -torso_h + 6.0), 0.07),
	]), PONCHO_TRIM)

	# Cream Turtleneck Collar + Neck
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.0, -torso_h - 8.0),
		Vector2(11.0, -torso_h - 8.0),
		Vector2(14.0, -torso_h + 8.0),
		Vector2(-14.0, -torso_h + 8.0),
	]), TURTLE_LIT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.0, -torso_h - 8.0),
		Vector2(0.0, -torso_h - 8.0),
		Vector2(-2.0, -torso_h + 8.0),
		Vector2(-14.0, -torso_h + 8.0),
	]), TURTLE_SH)

	# Neck & geometric cast shadow triangle
	draw_rect(Rect2(-7.5, -torso_h - 22.0, 15.0, 16.0), SKIN_LIT, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7.5, -torso_h - 22.0),
		Vector2(7.5, -torso_h - 22.0),
		Vector2(7.5, -torso_h - 10.0),
		Vector2(-7.5, -torso_h - 15.0),
	]), SKIN_SH)

	# === HEAD PIVOT ANCHOR ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -torso_h - 20.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 11.0
	var face_shift_y: float = pitch * 6.0

	# Sleek Geometric Bob Hair (back silhouette with secondary_lag)
	var back_h_xf := head_xf * _xform(Vector2(lag.x * 0.12, lag.y * 0.12), lag.rot * 0.22)
	draw_set_transform_matrix(back_h_xf)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-28.0, -34.0),
		Vector2(-24.0, -64.0),
		Vector2(24.0, -64.0),
		Vector2(29.0, -34.0),
		Vector2(33.0, 4.0),
		Vector2(-33.0, 4.0),
	]), HAIR_LIT)

	# Minimalist geometric ears
	for ear_side in [-1, 1]:
		var ear_vis: float = clampf(1.0 - float(ear_side) * yaw * 0.85, 0.15, 1.15)
		draw_set_transform_matrix(head_xf * _xform(Vector2(float(ear_side) * 23.0 - yaw * 5.0, -24.0 + face_shift_y * 0.35), 0.0, Vector2(ear_vis, 1.0)))
		draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 4.5, 7.5, 12), SKIN_SH if ear_side == -1 else SKIN_LIT)

	# Sculpted Lineless Head Shape
	draw_set_transform_matrix(head_xf)
	var chin := Vector2(yaw * 5.0, 4.0 + pitch * 3.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-23.0, -34.0),
		Vector2(-19.0, -56.0),
		Vector2(19.0, -56.0),
		Vector2(23.0, -34.0),
		Vector2(20.0 + yaw * 2.0, -10.0),
		chin,
		Vector2(-20.0 + yaw * 2.0, -10.0),
	]), SKIN_LIT)

	# Crisp geometric color-block cheek shadow (lineless depth!)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-23.0, -34.0),
		Vector2(-19.0, -56.0),
		Vector2(-6.0 + face_shift_x * 0.45, -56.0),
		Vector2(-10.0 + face_shift_x * 0.45, -18.0),
		chin,
		Vector2(-20.0 + yaw * 2.0, -10.0),
	]), SKIN_SH)

	# Geometric cheek blush ovals
	draw_colored_polygon(_ellipse_pts(Vector2(-14.0 + face_shift_x, -16.0 + face_shift_y), 5.5, 3.0, 12), Color(0.925, 0.455, 0.400, 0.55))
	draw_colored_polygon(_ellipse_pts(Vector2(14.0 + face_shift_x, -16.0 + face_shift_y), 5.5, 3.0, 12), Color(0.925, 0.455, 0.400, 0.55))

	# === GEOMETRIC EYES ===
	var eye_y: float = -26.0 + face_shift_y
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.35, 0.60, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.35, 0.60, 1.0)
	_draw_vector_eye(head_xf, Vector2(-10.2 * left_fs + face_shift_x, eye_y), left_fs, eyes)
	_draw_vector_eye(head_xf, Vector2(10.2 * right_fs + face_shift_x, eye_y), right_fs, eyes)

	# Geometric triangular nose shape (no line!)
	draw_set_transform_matrix(head_xf)
	var nx: float = face_shift_x * 1.15
	var ny: float = -23.0 + face_shift_y
	draw_colored_polygon(PackedVector2Array([
		Vector2(nx, ny),
		Vector2(nx + 4.0, ny + 8.5),
		Vector2(nx - 2.0, ny + 8.5),
	]), SKIN_DEEP)

	# === LINELESS VECTOR MOUTH ===
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 1.05, -6.5 + face_shift_y * 1.1)))
	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 1.0), 4.0 + mouth.open * 2.2, 4.5 + mouth.open * 4.0, 14), Color(0.55, 0.18, 0.22))
		MotionController.MouthShape.OPEN_HAPPY:
			draw_colored_polygon(PackedVector2Array([
				Vector2(-7.0, -1.0), Vector2(7.0, -1.0),
				Vector2(5.0, 6.5 * mouth.open + 2.0), Vector2(-5.0, 6.5 * mouth.open + 2.0),
			]), Color(0.68, 0.20, 0.26))
			draw_colored_polygon(PackedVector2Array([
				Vector2(-5.5, -1.0), Vector2(5.5, -1.0), Vector2(4.5, 1.8), Vector2(-4.5, 1.8),
			]), Color.WHITE)
		MotionController.MouthShape.SMILE:
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 0.8), 5.8, 2.2, 12), Color(0.66, 0.28, 0.29))
		_:
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 0.5), 4.5, 1.3, 10), SKIN_DEEP)

	# Graphic Asymmetrical Swept Bangs (2-tone vector shapes)
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 0.4 + lag.x * 0.06, lag.y * 0.06)))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-26.0, -34.0),
		Vector2(-21.0, -61.0),
		Vector2(18.0, -62.0),
		Vector2(26.0, -35.0),
		Vector2(12.0, -44.0),
		Vector2(-4.0, -34.0),
		Vector2(-20.0, -40.0),
	]), HAIR_LIT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4.0, -58.0),
		Vector2(17.0, -58.0),
		Vector2(22.0, -42.0),
		Vector2(5.0, -48.0),
	]), HAIR_HL)

	# Front vector arm
	_draw_vector_arm(
		torso_xf,
		Vector2(29.0 + torso.twist * 5.0, -92.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_vector_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor
) -> void:
	draw_set_transform_matrix(head_xf * _xform(eye_pos))
	var w: float = 6.8 * foreshorten_x
	var h: float = 5.4 * (1.0 + eyes.wide * 0.45) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.92)

	# Geometric brow bar (no outlines)
	var brow_y: float = -8.5 - eyes.brow_offset * 3.8 + eyes.squint * 1.2
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w * 0.9, brow_y - 1.2), Vector2(w * 0.9, brow_y - 1.2),
		Vector2(w * 0.85, brow_y + 1.4), Vector2(-w * 0.85, brow_y + 1.4),
	]), HAIR_LIT)

	if eyes.blink > 0.78:
		draw_colored_polygon(_ellipse_pts(Vector2(0.0, 0.8), w * 0.9, 1.3, 10), HAIR_LIT)
		return

	if eyes.squint > 0.45 and eyes.wide < 0.2:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-w * 0.9, 1.5), Vector2(0.0, -4.5), Vector2(w * 0.9, 1.5),
			Vector2(w * 0.65, 2.5), Vector2(0.0, -1.8), Vector2(-w * 0.65, 2.5),
		]), HAIR_LIT)
		return

	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, w, h, 16), Color.WHITE)
	var gx: float = clampf(eyes.look_x * 2.5 * foreshorten_x, -w * 0.35, w * 0.35)
	var gy: float = clampf(eyes.look_y * 1.5, -h * 0.25, h * 0.25)
	var ir: float = minf(3.3 * (1.0 - eyes.wide * 0.32 if eyes.wide > 0.2 else 1.0), h * 0.82)
	draw_colored_polygon(_ellipse_pts(Vector2(gx, gy), ir * foreshorten_x, ir, 14), HAIR_LIT)
	draw_circle(Vector2(gx - ir * 0.3, gy - ir * 0.3), maxf(0.8, 1.1), Color.WHITE)


func _draw_vector_arm(
	torso_xf: Transform2D,
	shoulder_pos: Vector2,
	shoulder_angle: float,
	elbow_angle: float,
	hand_pose: int,
	wave_phase: float,
	is_front: bool
) -> void:
	var upper_len: float = 48.0
	var fore_len: float = 46.0

	var upper_xf := torso_xf * _xform(shoulder_pos, shoulder_angle)
	draw_set_transform_matrix(upper_xf)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0, -5.0), Vector2(8.0, -5.0),
		Vector2(6.5, upper_len), Vector2(-6.5, upper_len),
	]), TURTLE_LIT if is_front else TURTLE_SH)

	var fore_xf := upper_xf * _xform(Vector2(0.0, upper_len - 2.0), elbow_angle)
	draw_set_transform_matrix(fore_xf)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6.5, 0.0), Vector2(6.5, 0.0),
		Vector2(4.8, fore_len - 5.0), Vector2(-4.8, fore_len - 5.0),
	]), TURTLE_LIT if is_front else TURTLE_SH)

	var hand_rot: float = wave_phase * 0.22 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0
	draw_set_transform_matrix(fore_xf * _xform(Vector2(0.0, fore_len - 2.0), hand_rot))
	var h_col: Color = SKIN_LIT if is_front else SKIN_SH
	if hand_pose == MotionController.HandPose.WAVE_OPEN:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-5.0, -2.0), Vector2(-8.0, 9.0), Vector2(-3.0, 16.0),
			Vector2(1.0, 17.0), Vector2(6.0, 14.0), Vector2(7.0, 7.0), Vector2(5.0, -2.0),
		]), h_col)
	elif hand_pose == MotionController.HandPose.TENSE_SPLAY:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-5.0, -2.0), Vector2(-11.0, 8.0), Vector2(-6.0, 15.0),
			Vector2(-1.0, 9.0), Vector2(1.0, 17.0), Vector2(4.0, 9.0),
			Vector2(9.0, 14.0), Vector2(6.0, 4.0), Vector2(5.0, -2.0),
		]), h_col)
	else:
		draw_colored_polygon(_ellipse_pts(Vector2(0.0, 5.5), 5.2, 7.2, 12), h_col)
