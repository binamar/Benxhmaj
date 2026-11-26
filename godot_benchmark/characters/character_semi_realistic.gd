class_name CharacterSemiRealistic
extends Node2D

const STYLE_TITLE: String = "Graphic Semi-Realistic"
const STYLE_SUBTITLE: String = "7.5-Head Anatomy · Planar Shadows · Tapered Linework"

# Moody muted editorial semi-realistic palette
const LINE := Color(0.137, 0.153, 0.188, 1.0)         # #232730 thin warm charcoal
const LINE_SOFT := Color(0.240, 0.230, 0.250, 0.65)

const SKIN_LIT := Color(0.875, 0.769, 0.690, 1.0)     # #DFC4B0
const SKIN_PLANE := Color(0.757, 0.620, 0.529, 1.0)   # #C19E87 cheekbone/collar plane
const SKIN_DEEP := Color(0.600, 0.455, 0.380, 1.0)    # #997461 eye-socket/jaw-under plane

const HAIR_LIT := Color(0.267, 0.235, 0.220, 1.0)     # #443C38
const HAIR_SH := Color(0.165, 0.145, 0.140, 1.0)      # #2A2524

const COAT_LIT := Color(0.247, 0.286, 0.333, 1.0)     # #3F4955
const COAT_SH1 := Color(0.173, 0.204, 0.243, 1.0)     # #2C343E
const COAT_SH2 := Color(0.114, 0.137, 0.165, 1.0)     # #1D232A
const COAT_LAPEL := Color(0.306, 0.349, 0.400, 1.0)   # #4E5966

const SHIRT_LIT := Color(0.494, 0.549, 0.557, 1.0)    # #7E8C8E
const SHIRT_SH := Color(0.369, 0.416, 0.427, 1.0)     # #5E6A6D
const SCARF_ACCENT := Color(0.620, 0.353, 0.278, 1.0) # #9E5A47 muted terracotta
const SCARF_SH := Color(0.451, 0.243, 0.192, 1.0)     # #733E31

const TROUSER_LIT := Color(0.165, 0.180, 0.204, 1.0)  # #2A2E34
const TROUSER_SH := Color(0.110, 0.122, 0.141, 1.0)   # #1C1F24
const BOOT_LIT := Color(0.180, 0.153, 0.145, 1.0)     # #2E2725
const BOOT_SH := Color(0.114, 0.098, 0.094, 1.0)      # #1D1918

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 132.0 * s
	var h: float = 372.0 * s
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

	# Ground shadow
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	var sh_xf := _xform(
		Vector2(body_root.x * 0.7, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.42, 1.0 - air_factor * 0.35)
	)
	draw_set_transform_matrix(sh_xf)
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 48.0, 10.0, 24), Color(0.03, 0.035, 0.06, 0.38))

	# Body root (7.5-head realistic proportions: hips at -172, shoulders at -290, head top at -360)
	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean,
		Vector2(body_root.scale_x, body_root.scale_y)
	)
	draw_set_transform_matrix(root_xf)

	# === LONG ANATOMICAL LEGS & TAILORED BOOTS ===
	var knee_bend: float = clampf((1.0 - body_root.scale_y) * 26.0, -7.0, 15.0)
	for side in [-1, 1]:
		var is_back: bool = side == -1
		var hip_x: float = float(side) * 11.5
		var hip_y: float = -170.0
		var foot_x: float = float(side) * 14.5
		var kb: float = knee_bend * 0.2 * float(side)

		var leg_poly := PackedVector2Array([
			Vector2(hip_x - 10.5, hip_y),
			Vector2(hip_x + 10.5, hip_y),
			Vector2(foot_x + 8.5 + kb, -92.0),
			Vector2(foot_x + 6.0, -24.0),
			Vector2(foot_x - 6.0, -24.0),
			Vector2(foot_x - 8.0 + kb, -92.0),
		])
		draw_colored_polygon(leg_poly, TROUSER_SH if is_back else TROUSER_LIT)

		if not is_back:
			# Inner shadow plane on leg
			draw_colored_polygon(PackedVector2Array([
				Vector2(hip_x - 10.5, hip_y),
				Vector2(hip_x - 1.5, hip_y),
				Vector2(foot_x - 1.0, -24.0),
				Vector2(foot_x - 6.0, -24.0),
			]), TROUSER_SH)

		# Subtle tailored trouser crease + thin tapered outline
		draw_line(Vector2(hip_x + 1.0, hip_y + 12.0), Vector2(foot_x + 1.0, -28.0), LINE_SOFT, 1.0, true)
		draw_polyline(_closed_outline(leg_poly), LINE, 1.5, true)

		# Sleek leather dress boot
		var boot_poly := PackedVector2Array([
			Vector2(foot_x - 6.8, -26.0),
			Vector2(foot_x + 6.8, -26.0),
			Vector2(foot_x + 9.0, -8.0),
			Vector2(foot_x + 16.0 * float(side) + 3.0, -2.0),
			Vector2(foot_x + 16.0 * float(side) + 3.0, 0.0),
			Vector2(foot_x - 8.5, 0.0),
		])
		draw_colored_polygon(boot_poly, BOOT_SH if is_back else BOOT_LIT)
		draw_polyline(_closed_outline(boot_poly), LINE, 1.5, true)

	# === TORSO ANCHOR ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -170.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x * (1.0 - absf(torso.twist) * 0.06), torso.breath_scale_y)
	)

	# Back split trench coat tails (secondary_lag behind legs & torso)
	var back_coat_xf := torso_xf * _xform(Vector2(-4.0, -8.0), lag.rot * 0.65)
	draw_set_transform_matrix(back_coat_xf)
	var ct_tip_l := Vector2(-34.0 + lag.x * 0.95 + lag.flutter * 0.6, 114.0 + lag.y * 0.7)
	var ct_tip_r := Vector2(28.0 + lag.x * 0.85 + lag.flutter * 0.6, 110.0 + lag.y * 0.7)
	var coat_tail := PackedVector2Array([Vector2(-24.0, -8.0), Vector2(22.0, -8.0)])
	_append_quad(coat_tail, Vector2(22.0, -8.0), Vector2(30.0 + lag.x * 0.4, 52.0), ct_tip_r, 7)
	coat_tail.append(Vector2(2.0 + lag.x * 0.8, 96.0 + lag.y * 0.6))
	coat_tail.append(ct_tip_l)
	_append_quad(coat_tail, ct_tip_l, Vector2(-30.0 + lag.x * 0.4, 52.0), Vector2(-24.0, -8.0), 7)
	draw_colored_polygon(coat_tail, COAT_SH2)
	draw_polyline(_closed_outline(coat_tail), LINE, 1.4, true)

	# Back realistic arm
	_draw_realistic_arm(
		torso_xf,
		Vector2(-30.0 + torso.twist * 5.0, -106.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		false
	)

	# Structured anatomical torso & tailored trench coat
	draw_set_transform_matrix(torso_xf)
	var sh_w: float = 33.0
	var waist_w: float = 21.0
	var torso_h: float = 114.0

	# Inner shirt V-plastron & muted terracotta ascot/tie
	var shirt_poly := PackedVector2Array([
		Vector2(-12.0 + torso.twist * 6.0, -torso_h),
		Vector2(12.0 + torso.twist * 6.0, -torso_h),
		Vector2(8.0 + torso.twist * 8.0, -48.0),
		Vector2(-8.0 + torso.twist * 8.0, -48.0),
	])
	draw_colored_polygon(shirt_poly, SHIRT_LIT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12.0 + torso.twist * 6.0, -torso_h),
		Vector2(-2.0 + torso.twist * 6.0, -torso_h),
		Vector2(-3.0 + torso.twist * 8.0, -48.0),
		Vector2(-8.0 + torso.twist * 8.0, -48.0),
	]), SHIRT_SH)

	# Terracotta silk tie / neck-scarf fold
	var tie_poly := PackedVector2Array([
		Vector2(-4.0 + torso.twist * 7.0, -torso_h + 4.0),
		Vector2(4.0 + torso.twist * 7.0, -torso_h + 4.0),
		Vector2(3.5 + torso.twist * 8.0, -54.0),
		Vector2(0.0 + torso.twist * 8.0, -48.0),
		Vector2(-3.5 + torso.twist * 8.0, -54.0),
	])
	draw_colored_polygon(tie_poly, SCARF_ACCENT)
	draw_polyline(_closed_outline(tie_poly), LINE, 1.1, true)

	# Left & Right tailored trench coat panels (planar shading)
	var left_coat := PackedVector2Array([
		Vector2(-sh_w, -torso_h + 6.0),
		Vector2(-12.0 + torso.twist * 6.0, -torso_h),
		Vector2(-3.0 + torso.twist * 8.0, -44.0),
		Vector2(-2.0 + torso.twist * 7.0, 26.0),
		Vector2(-waist_w - 6.0, 28.0),
		Vector2(-waist_w, -28.0),
	])
	draw_colored_polygon(left_coat, COAT_SH1)
	# Deep ribcage side shadow plane
	draw_colored_polygon(PackedVector2Array([
		Vector2(-sh_w, -torso_h + 6.0),
		Vector2(-21.0, -torso_h + 12.0),
		Vector2(-16.0, -28.0),
		Vector2(-waist_w, -28.0),
	]), COAT_SH2)
	draw_polyline(_closed_outline(left_coat), LINE, 1.6, true)

	var right_coat := PackedVector2Array([
		Vector2(12.0 + torso.twist * 6.0, -torso_h),
		Vector2(sh_w, -torso_h + 6.0),
		Vector2(waist_w, -28.0),
		Vector2(waist_w + 6.0, 28.0),
		Vector2(1.0 + torso.twist * 7.0, 26.0),
		Vector2(3.0 + torso.twist * 8.0, -44.0),
	])
	draw_colored_polygon(right_coat, COAT_LIT)
	# Lower coat hem shadow plane
	draw_colored_polygon(PackedVector2Array([
		Vector2(waist_w, -28.0),
		Vector2(waist_w + 6.0, 28.0),
		Vector2(1.0 + torso.twist * 7.0, 26.0),
		Vector2(2.0 + torso.twist * 7.0, -28.0),
	]), COAT_SH1)
	draw_polyline(_closed_outline(right_coat), LINE, 1.6, true)

	# Notched trench lapels
	for l_side in [-1, 1]:
		var sx: float = float(l_side)
		var lapel := PackedVector2Array([
			Vector2(sx * 12.0 + torso.twist * 6.0, -torso_h),
			Vector2(sx * 23.0 + torso.twist * 5.0, -torso_h + 14.0),
			Vector2(sx * 14.0 + torso.twist * 6.0, -torso_h + 24.0),
			Vector2(sx * 18.0 + torso.twist * 6.0, -torso_h + 30.0),
			Vector2(sx * 4.0 + torso.twist * 8.0, -52.0),
		])
		draw_colored_polygon(lapel, COAT_SH1 if l_side == -1 else COAT_LAPEL)
		draw_polyline(_closed_outline(lapel), LINE, 1.3, true)

	# Trench belt & muted brass buckle
	draw_rect(Rect2(-waist_w - 1.0, -30.0, waist_w * 2.0 + 2.0, 7.0), COAT_SH2, true)
	draw_rect(Rect2(-waist_w - 1.0, -30.0, waist_w * 2.0 + 2.0, 7.0), LINE, false, 1.3)
	draw_rect(Rect2(-5.0 + torso.twist * 8.0, -31.0, 10.0, 9.0), Color(0.55, 0.46, 0.34), false, 1.6)

	# === ANATOMICAL NECK & COLLARBONE SHADOW PLANES ===
	var neck_poly := PackedVector2Array([
		Vector2(-7.0, -torso_h - 19.0),
		Vector2(7.0, -torso_h - 19.0),
		Vector2(10.5, -torso_h + 4.0),
		Vector2(-10.5, -torso_h + 4.0),
	])
	draw_colored_polygon(neck_poly, SKIN_LIT)

	# Structured neck cast-shadow & sternocleidomastoid shadow plane
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7.0, -torso_h - 19.0),
		Vector2(7.0, -torso_h - 19.0),
		Vector2(7.5, -torso_h - 5.0),
		Vector2(-1.5, -torso_h + 3.0),
		Vector2(-10.5, -torso_h + 3.0),
	]), SKIN_PLANE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7.0, -torso_h - 19.0),
		Vector2(5.5, -torso_h - 19.0),
		Vector2(2.0, -torso_h - 10.0),
		Vector2(-8.0, -torso_h - 9.0),
	]), SKIN_DEEP)

	# Explicit collarbone shadow planes & delicate tapered clavicle lines
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13.0, -torso_h + 1.0),
		Vector2(-2.0, -torso_h + 5.0),
		Vector2(-12.0, -torso_h + 6.0),
	]), SKIN_PLANE)
	draw_line(Vector2(-13.0, -torso_h + 2.0), Vector2(-2.5, -torso_h + 5.0), LINE_SOFT, 1.1, true)
	draw_line(Vector2(13.0, -torso_h + 2.0), Vector2(2.5, -torso_h + 5.0), LINE_SOFT, 1.1, true)
	draw_line(Vector2(-7.0, -torso_h - 18.0), Vector2(-10.0, -torso_h + 2.0), LINE, 1.4, true)
	draw_line(Vector2(7.0, -torso_h - 18.0), Vector2(10.0, -torso_h + 2.0), LINE, 1.4, true)

	# === HEAD PIVOT ANCHOR (7.5-head realistic sculpted proportions) ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -torso_h - 18.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 9.5
	var face_shift_y: float = pitch * 5.0

	# Back layered hair
	var back_hair_xf := head_xf * _xform(Vector2(lag.x * 0.1, lag.y * 0.1), lag.rot * 0.15)
	draw_set_transform_matrix(back_hair_xf)
	var back_h := PackedVector2Array([
		Vector2(-21.0, -24.0),
		Vector2(-23.0, -6.0),
		Vector2(-15.0, 2.0),
		Vector2(15.0, 2.0),
		Vector2(23.0, -6.0),
		Vector2(21.0, -24.0),
	])
	_append_quad(back_h, Vector2(21.0, -24.0), Vector2(0.0, -56.0), Vector2(-21.0, -24.0), 10)
	draw_colored_polygon(back_h, HAIR_SH)

	# Realistic sculpted ears (2.5D yaw visibility)
	for ear_side in [-1, 1]:
		var ear_vis: float = clampf(1.0 - float(ear_side) * yaw * 0.85, 0.12, 1.15)
		var ear_xf := head_xf * _xform(
			Vector2(float(ear_side) * 18.5 - yaw * 4.5, -21.0 + face_shift_y * 0.35),
			float(ear_side) * 0.08,
			Vector2(ear_vis, 1.0)
		)
		draw_set_transform_matrix(ear_xf)
		var ear_pts := _ellipse_pts(Vector2.ZERO, 3.6, 6.8, 12)
		draw_colored_polygon(ear_pts, SKIN_PLANE if ear_side == -1 else SKIN_LIT)
		draw_polyline(_closed_outline(ear_pts), LINE, 1.2, true)

	# Sculpted realistic head & angular jaw contour
	draw_set_transform_matrix(head_xf)
	var chin := Vector2(yaw * 4.5, 4.0 + pitch * 3.0)
	var jaw_l := Vector2(-15.5 + yaw * 2.5, -9.0 + pitch * 1.5)
	var jaw_r := Vector2(15.5 + yaw * 2.5, -9.0 + pitch * 1.5)
	var head_poly := PackedVector2Array([
		Vector2(-18.5, -28.0),
	])
	_append_quad(head_poly, Vector2(-18.5, -28.0), Vector2(-18.0, -50.0), Vector2(0.0, -50.0), 7)
	_append_quad(head_poly, Vector2(0.0, -50.0), Vector2(18.0, -50.0), Vector2(18.5, -28.0), 7)
	head_poly.append(jaw_r)
	head_poly.append(chin + Vector2(3.5, -0.5))
	head_poly.append(chin + Vector2(-3.5, -0.5))
	head_poly.append(jaw_l)
	draw_colored_polygon(head_poly, SKIN_LIT)

	# === STRUCTURED ANATOMICAL FACIAL SHADOW PLANES ===
	# 1. Left temple & cheekbone planar shadow
	var cheek_plane_l := PackedVector2Array([
		Vector2(-18.5, -28.0),
		Vector2(-9.5 + face_shift_x * 0.5, -29.0 + face_shift_y * 0.4),
		Vector2(-6.5 + face_shift_x * 0.65, -14.0 + face_shift_y * 0.6),
		chin + Vector2(-3.5, -0.5),
		jaw_l,
	])
	draw_colored_polygon(cheek_plane_l, SKIN_PLANE)

	# 2. Right subtle zygomatic (cheekbone) hollow plane
	var cheek_plane_r := PackedVector2Array([
		Vector2(17.8, -22.0),
		Vector2(10.0 + face_shift_x * 0.7, -18.5 + face_shift_y * 0.6),
		Vector2(12.0 + face_shift_x * 0.5, -11.0 + face_shift_y * 0.6),
		jaw_r,
	])
	draw_colored_polygon(cheek_plane_r, SKIN_PLANE)

	# 3. Jawline underside deep occlusion plane
	var jaw_under := PackedVector2Array([
		jaw_l,
		chin + Vector2(-3.5, -0.5),
		chin + Vector2(3.5, -0.5),
		jaw_r,
		jaw_r + Vector2(-3.0, -3.2),
		chin + Vector2(0.0, -2.5),
		jaw_l + Vector2(3.0, -3.2),
	])
	draw_colored_polygon(jaw_under, SKIN_DEEP)

	# 4. Brow-ridge / orbital eye-socket shadow planes
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.35, 0.58, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.35, 0.58, 1.0)
	var eye_y: float = -24.0 + face_shift_y
	var le_pos := Vector2(-8.2 * left_fs + face_shift_x, eye_y)
	var re_pos := Vector2(8.2 * right_fs + face_shift_x, eye_y)

	draw_colored_polygon(PackedVector2Array([
		le_pos + Vector2(-5.5 * left_fs, -5.0),
		le_pos + Vector2(4.2 * left_fs, -4.5),
		le_pos + Vector2(3.5 * left_fs, 0.5),
		le_pos + Vector2(-5.0 * left_fs, 1.0),
	]), SKIN_PLANE)
	draw_colored_polygon(PackedVector2Array([
		re_pos + Vector2(-4.2 * right_fs, -4.5),
		re_pos + Vector2(5.5 * right_fs, -5.0),
		re_pos + Vector2(5.0 * right_fs, 1.0),
		re_pos + Vector2(-3.5 * right_fs, 0.5),
	]), SKIN_PLANE)

	# Thin tapered head contour line
	draw_polyline(_closed_outline(head_poly), LINE, 1.55, true)

	# === EYES ANCHOR (Almond semi-realistic eyes) ===
	_draw_realistic_eye(head_xf, le_pos, -1, left_fs, eyes)
	_draw_realistic_eye(head_xf, re_pos, 1, right_fs, eyes)

	# Structured nose bridge + side shadow plane + nostril crease
	draw_set_transform_matrix(head_xf)
	var nx: float = face_shift_x * 1.15
	var ny: float = -22.5 + face_shift_y * 0.9
	var nose_sh := PackedVector2Array([
		Vector2(nx - 0.5, ny),
		Vector2(nx + 0.8, ny + 8.5),
		Vector2(nx - 3.2, ny + 9.8),
		Vector2(nx - 2.2, ny + 5.0),
	])
	draw_colored_polygon(nose_sh, SKIN_PLANE)
	draw_polyline(PackedVector2Array([
		Vector2(nx + 0.4, ny + 1.0),
		Vector2(nx + 1.4, ny + 8.8),
		Vector2(nx - 1.4, ny + 10.2),
	]), LINE, 1.15, true)

	# === MOUTH ANCHOR (Realistic parted lips & lower-lip cast shadow) ===
	var mouth_xf := head_xf * _xform(Vector2(face_shift_x * 1.05, -7.2 + face_shift_y * 1.1))
	draw_set_transform_matrix(mouth_xf)
	# Subtle lower-lip cast shadow
	draw_colored_polygon(_ellipse_pts(Vector2(0.0, 3.8 + mouth.open * 2.5), 3.6, 1.2, 10), SKIN_PLANE)

	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			var m_pts := _ellipse_pts(Vector2(0.0, 0.8), 3.0 + mouth.open * 1.6, 3.2 + mouth.open * 3.0, 14)
			draw_colored_polygon(m_pts, Color(0.28, 0.14, 0.14))
			draw_polyline(_closed_outline(m_pts), LINE, 1.3, true)
		MotionController.MouthShape.OPEN_HAPPY:
			var m_pts := PackedVector2Array([
				Vector2(-5.5, -0.4), Vector2(5.5, -0.4),
				Vector2(4.2, 3.8 * mouth.open + 1.2), Vector2(0.0, 4.8 * mouth.open + 1.5), Vector2(-4.2, 3.8 * mouth.open + 1.2),
			])
			draw_colored_polygon(m_pts, Color(0.45, 0.22, 0.21))
			draw_polyline(_closed_outline(m_pts), LINE, 1.2, true)
		MotionController.MouthShape.SMILE:
			draw_polyline(_quad_pts(Vector2(-5.0, -0.3), Vector2(0.0, 2.2), Vector2(5.2, -0.3), 6), LINE, 1.3, true)
		_:
			# Defined upper bow + parted lip line
			draw_polyline(PackedVector2Array([
				Vector2(-4.6, 0.3), Vector2(-1.6, -0.4), Vector2(0.0, 0.2), Vector2(1.6, -0.4), Vector2(4.6, 0.3)
			]), LINE, 1.25, true)

	# Swept layered semi-realistic hair (2.5D shift + subtle lag)
	var hair_xf := head_xf * _xform(Vector2(face_shift_x * 0.38 + lag.x * 0.05, lag.y * 0.05))
	draw_set_transform_matrix(hair_xf)
	var top_hair := PackedVector2Array([Vector2(-19.5, -24.0)])
	_append_quad(top_hair, Vector2(-19.5, -24.0), Vector2(-21.0, -53.0), Vector2(1.0, -53.5), 8)
	_append_quad(top_hair, Vector2(1.0, -53.5), Vector2(21.5, -52.0), Vector2(19.5, -24.0), 8)
	top_hair.append_array(PackedVector2Array([
		Vector2(17.0, -34.0),
		Vector2(9.0, -38.0),
		Vector2(-1.0, -31.0),
		Vector2(-11.0, -39.0),
		Vector2(-17.0, -31.0),
	]))
	draw_colored_polygon(top_hair, HAIR_LIT)

	# Planar shadow on left side of hair
	var hair_sh := PackedVector2Array([Vector2(-19.5, -24.0)])
	_append_quad(hair_sh, Vector2(-19.5, -24.0), Vector2(-21.0, -53.0), Vector2(-3.0, -53.2), 7)
	hair_sh.append(Vector2(-6.0, -36.0))
	hair_sh.append(Vector2(-17.0, -31.0))
	draw_colored_polygon(hair_sh, HAIR_SH)

	# Tapered hair strand accents
	draw_line(Vector2(-4.0, -48.0), Vector2(-1.0, -32.0), LINE, 1.0, true)
	draw_line(Vector2(6.0, -49.0), Vector2(9.5, -37.0), LINE, 1.0, true)
	draw_polyline(_closed_outline(top_hair), LINE, 1.45, true)

	# Front tailored arm
	_draw_realistic_arm(
		torso_xf,
		Vector2(30.0 + torso.twist * 5.0, -106.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_realistic_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	side: int,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor
) -> void:
	var eye_xf := head_xf * _xform(eye_pos)
	draw_set_transform_matrix(eye_xf)

	var w: float = 5.4 * foreshorten_x
	var base_h: float = 3.1
	var h: float = base_h * (1.0 + eyes.wide * 0.48) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.92)

	# Natural tapered brow arch
	var brow_y: float = -6.8 - eyes.brow_offset * 3.2 + eyes.squint * 1.0
	var brow_pts := PackedVector2Array([
		Vector2(-w * 1.15, brow_y + (0.6 if side == -1 else 0.2)),
		Vector2(0.0, brow_y - 1.3 - eyes.wide * 0.8),
		Vector2(w * 1.1, brow_y + (0.6 if side == 1 else 0.2)),
	])
	draw_polyline(brow_pts, HAIR_SH, 1.7, true)

	if eyes.blink > 0.78:
		draw_polyline(_quad_pts(Vector2(-w, 0.4), Vector2(0.0, 1.8), Vector2(w, 0.3), 5), LINE, 1.5, true)
		return

	# Upper eyelid crease line (anatomical fold)
	var crease_y: float = -h - 1.6
	draw_polyline(_quad_pts(Vector2(-w * 0.95, crease_y + 1.0), Vector2(0.0, crease_y - 0.6), Vector2(w * 0.95, crease_y + 1.0), 5), LINE_SOFT, 0.85, true)

	# Almond sclera
	var sclera := PackedVector2Array([Vector2(-w, 0.0)])
	_append_quad(sclera, Vector2(-w, 0.0), Vector2(0.0, -h * 1.3), Vector2(w, 0.0), 5)
	_append_quad(sclera, Vector2(w, 0.0), Vector2(0.0, h * 1.15), Vector2(-w, 0.0), 5)
	draw_colored_polygon(sclera, Color(0.941, 0.925, 0.902))

	# Subtle upper scleral shadow
	var scl_sh := PackedVector2Array([Vector2(-w * 0.95, -0.2)])
	_append_quad(scl_sh, Vector2(-w * 0.95, -0.2), Vector2(0.0, -h * 1.3), Vector2(w * 0.95, -0.2), 5)
	scl_sh.append(Vector2(0.0, -h * 0.45))
	draw_colored_polygon(scl_sh, Color(0.76, 0.75, 0.74))

	# Realistic iris & pupil
	var iris_scale: float = 1.0 - eyes.wide * 0.32 if eyes.wide > 0.2 else 1.0
	var gx: float = clampf(eyes.look_x * 1.8 * foreshorten_x, -w * 0.35, w * 0.35)
	var gy: float = clampf(eyes.look_y * 1.0, -h * 0.2, h * 0.25)
	var ir: float = minf(2.4 * iris_scale, h * 0.85)
	var ic := Vector2(gx, gy)

	draw_colored_polygon(_ellipse_pts(ic, ir * foreshorten_x, ir, 12), Color(0.357, 0.439, 0.396))
	draw_colored_polygon(_ellipse_pts(ic, ir * 0.48 * foreshorten_x, ir * 0.48, 10), LINE)
	draw_circle(ic + Vector2(-ir * 0.32, -ir * 0.32), maxf(0.6, 0.75 * iris_scale), Color.WHITE)

	# Defined upper lash line + subtle lower rim
	draw_polyline(_quad_pts(Vector2(-w * 1.05, 0.2), Vector2(0.0, -h * 1.32), Vector2(w * 1.05, 0.2), 6), LINE, 1.55, true)
	draw_polyline(_quad_pts(Vector2(-w * 0.75, 0.4), Vector2(0.0, h * 1.15), Vector2(w * 0.75, 0.4), 5), LINE_SOFT, 0.85, true)


func _draw_realistic_arm(
	torso_xf: Transform2D,
	shoulder_pos: Vector2,
	shoulder_angle: float,
	elbow_angle: float,
	hand_pose: int,
	wave_phase: float,
	is_front: bool
) -> void:
	var upper_len: float = 60.0
	var fore_len: float = 56.0

	var upper_xf := torso_xf * _xform(shoulder_pos, shoulder_angle)
	draw_set_transform_matrix(upper_xf)

	var u_poly := PackedVector2Array([
		Vector2(-8.5, -5.0), Vector2(8.5, -5.0),
		Vector2(7.0, upper_len), Vector2(-7.0, upper_len),
	])
	draw_colored_polygon(u_poly, COAT_LIT if is_front else COAT_SH1)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.5, -5.0), Vector2(-1.5, -5.0),
		Vector2(-2.0, upper_len), Vector2(-7.0, upper_len),
	]), COAT_SH1 if is_front else COAT_SH2)
	draw_polyline(_closed_outline(u_poly), LINE, 1.5 if is_front else 1.25, true)

	var fore_xf := upper_xf * _xform(Vector2(0.0, upper_len - 2.0), elbow_angle)
	draw_set_transform_matrix(fore_xf)

	var f_poly := PackedVector2Array([
		Vector2(-7.2, 0.0), Vector2(7.2, 0.0),
		Vector2(5.2, fore_len - 7.0), Vector2(-5.2, fore_len - 7.0),
	])
	draw_colored_polygon(f_poly, COAT_LIT if is_front else COAT_SH1)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7.2, 0.0), Vector2(-1.5, 0.0),
		Vector2(-1.8, fore_len - 7.0), Vector2(-5.2, fore_len - 7.0),
	]), COAT_SH1 if is_front else COAT_SH2)
	# Subtle shirt cuff peek
	draw_rect(Rect2(-4.8, fore_len - 7.0, 9.6, 5.0), SHIRT_LIT if is_front else SHIRT_SH, true)
	draw_line(Vector2(-5.2, fore_len - 13.0), Vector2(4.0, fore_len - 15.0), LINE_SOFT, 1.0, true)
	draw_polyline(_closed_outline(f_poly), LINE, 1.5 if is_front else 1.25, true)

	var hand_rot: float = wave_phase * 0.20 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0
	var hand_xf := fore_xf * _xform(Vector2(0.0, fore_len - 2.0), hand_rot)
	draw_set_transform_matrix(hand_xf)

	var h_col: Color = SKIN_LIT if is_front else SKIN_PLANE
	if hand_pose == MotionController.HandPose.WAVE_OPEN:
		var h_poly := PackedVector2Array([
			Vector2(-4.8, 0.0), Vector2(-7.0, 9.0), Vector2(-3.2, 16.5),
			Vector2(0.5, 17.5), Vector2(4.5, 15.5), Vector2(6.5, 8.0), Vector2(4.8, 0.0),
		])
		draw_colored_polygon(h_poly, h_col)
		draw_polyline(_closed_outline(h_poly), LINE, 1.25, true)
		draw_line(Vector2(-2.0, 9.0), Vector2(-2.2, 15.0), LINE_SOFT, 0.9, true)
		draw_line(Vector2(1.2, 9.0), Vector2(1.0, 16.0), LINE_SOFT, 0.9, true)
	elif hand_pose == MotionController.HandPose.TENSE_SPLAY:
		var h_poly := PackedVector2Array([
			Vector2(-5.0, 0.0), Vector2(-10.0, 8.0), Vector2(-5.5, 15.5),
			Vector2(-1.5, 9.5), Vector2(1.0, 16.5), Vector2(3.8, 9.5),
			Vector2(8.5, 14.0), Vector2(5.5, 4.5), Vector2(4.5, 0.0),
		])
		draw_colored_polygon(h_poly, h_col)
		draw_polyline(_closed_outline(h_poly), LINE, 1.25, true)
	else:
		var h_poly := PackedVector2Array([
			Vector2(-4.5, 0.0), Vector2(-5.2, 9.0), Vector2(-2.0, 14.0),
			Vector2(2.8, 13.0), Vector2(4.8, 7.0), Vector2(4.2, 0.0),
		])
		draw_colored_polygon(h_poly, h_col)
		draw_polyline(_closed_outline(h_poly), LINE, 1.25, true)
