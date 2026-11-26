class_name CharacterChibi
extends Node2D

const STYLE_TITLE: String = "Chibi Super-Deformed"
const STYLE_SUBTITLE: String = "2.5-Head Proportions · Rounded Ink · Jewel Eyes"

const INK := Color(0.231, 0.137, 0.118, 1.0)         # #3B231E warm cocoa ink
const SKIN_LIT := Color(1.0, 0.914, 0.855, 1.0)      # #FFE9DA
const SKIN_SH := Color(0.961, 0.776, 0.678, 1.0)     # #F5C6AD
const BLUSH := Color(0.988, 0.565, 0.608, 0.65)

const HAIR_LIT := Color(0.976, 0.580, 0.710, 1.0)    # #F994B5 sakura pink
const HAIR_SH := Color(0.847, 0.369, 0.545, 1.0)     # #D85E8B
const HAIR_HL := Color(1.0, 0.835, 0.894, 1.0)

const HOODIE_LIT := Color(0.329, 0.729, 0.882, 1.0)  # #54BAE1 sky hoodie
const HOODIE_SH := Color(0.184, 0.525, 0.698, 1.0)   # #2F86B2
const HOODIE_TRIM := Color(0.996, 0.969, 0.914, 1.0) # #FEF7E9 cream trim
const STAR_GOLD := Color(0.992, 0.788, 0.239, 1.0)   # #FDC93D

const SHORTS_COL := Color(0.255, 0.278, 0.420, 1.0)  # #41476B
const BOOT_LIT := Color(0.945, 0.431, 0.412, 1.0)    # #F16E69
const BOOT_SH := Color(0.753, 0.255, 0.255, 1.0)

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 166.0 * s
	var h: float = 285.0 * s
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

	# Amplified cute ground shadow
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	var sh_xf := _xform(
		Vector2(body_root.x * 0.7, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.45, 1.0 - air_factor * 0.35)
	)
	draw_set_transform_matrix(sh_xf)
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 54.0, 12.0, 24), Color(0.12, 0.08, 0.14, 0.32))

	# Chibi exaggerates squash & stretch slightly more (1.15x delta)
	var sx: float = 1.0 + (body_root.scale_x - 1.0) * 1.18
	var sy: float = 1.0 + (body_root.scale_y - 1.0) * 1.18
	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean * 1.1,
		Vector2(sx, sy)
	)
	draw_set_transform_matrix(root_xf)

	# === SHORT STUBBY LEGS & OVERSIZED CUFFED BOOTS ===
	for side in [-1, 1]:
		var is_back: bool = side == -1
		var fx: float = float(side) * 16.0
		var leg_poly := PackedVector2Array([
			Vector2(fx - 9.0, -70.0), Vector2(fx + 9.0, -70.0),
			Vector2(fx + 8.0, -24.0), Vector2(fx - 8.0, -24.0),
		])
		draw_colored_polygon(leg_poly, SKIN_SH if is_back else SKIN_LIT)
		draw_polyline(_closed_outline(leg_poly), INK, 3.0, true)

		# Puffy folded sock cuff
		var cuff := _ellipse_pts(Vector2(fx, -25.0), 11.5, 5.5, 14)
		draw_colored_polygon(cuff, HOODIE_TRIM)
		draw_polyline(_closed_outline(cuff), INK, 2.8, true)

		# Oversized rounded chibi boot
		var boot := PackedVector2Array([
			Vector2(fx - 12.0, -22.0),
			Vector2(fx + 12.0, -22.0),
			Vector2(fx + 17.0 * float(side) + 5.0, -7.0),
			Vector2(fx + 16.0 * float(side) + 5.0, 0.0),
			Vector2(fx - 13.0, 0.0),
		])
		draw_colored_polygon(boot, BOOT_SH if is_back else BOOT_LIT)
		draw_rect(Rect2(fx - 12.0, -5.0, 26.0, 5.0), HOODIE_TRIM, true)
		draw_polyline(_closed_outline(boot), INK, 3.0, true)

	# === TORSO ANCHOR (Compact plump hoodie) ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -68.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x * (1.0 - absf(torso.twist) * 0.05), torso.breath_scale_y)
	)

	# Back puffy hood + twin cat-ear tips (secondary_lag)
	var hood_xf := torso_xf * _xform(Vector2(0.0, -64.0), lag.rot * 0.35)
	draw_set_transform_matrix(hood_xf)
	var back_hood := _ellipse_pts(Vector2(lag.x * 0.14, 10.0 + lag.y * 0.12), 34.0, 18.0, 20)
	draw_colored_polygon(back_hood, HOODIE_SH)
	draw_polyline(_closed_outline(back_hood), INK, 3.0, true)

	# Back stubby arm
	_draw_chibi_arm(
		torso_xf,
		Vector2(-26.0 + torso.twist * 4.0, -56.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		false
	)

	# Hoodie body & flared shorts
	draw_set_transform_matrix(torso_xf)
	var shorts_poly := PackedVector2Array([
		Vector2(-26.0, -18.0), Vector2(26.0, -18.0),
		Vector2(30.0, 8.0), Vector2(4.0, 8.0),
		Vector2(0.0, -2.0), Vector2(-4.0, 8.0), Vector2(-30.0, 8.0),
	])
	draw_colored_polygon(shorts_poly, SHORTS_COL)
	draw_polyline(_closed_outline(shorts_poly), INK, 3.0, true)

	var body_poly := PackedVector2Array([
		Vector2(-24.0, -68.0),
		Vector2(24.0, -68.0),
		Vector2(31.0, -14.0),
		Vector2(-31.0, -14.0),
	])
	draw_colored_polygon(body_poly, HOODIE_LIT)
	# Soft shadow crescent
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24.0, -68.0), Vector2(-6.0, -68.0),
		Vector2(-10.0, -14.0), Vector2(-31.0, -14.0),
	]), HOODIE_SH)
	# Cream ribbed hoodie hem & kangaroo pocket
	draw_rect(Rect2(-31.0, -18.0, 62.0, 8.0), HOODIE_TRIM, true)
	draw_rect(Rect2(-15.0 + torso.twist * 6.0, -34.0, 30.0, 14.0), HOODIE_SH, true)
	draw_rect(Rect2(-15.0 + torso.twist * 6.0, -34.0, 30.0, 14.0), INK, false, 2.2)
	draw_polyline(_closed_outline(body_poly), INK, 3.2, true)

	# Star badge on chest
	var star_c := Vector2(13.0 + torso.twist * 6.0, -48.0)
	var star_pts := PackedVector2Array()
	for si in range(10):
		var ang: float = -PI * 0.5 + float(si) * PI / 5.0
		var rad: float = 8.0 if si % 2 == 0 else 3.6
		star_pts.append(star_c + Vector2(cos(ang) * rad, sin(ang) * rad))
	draw_colored_polygon(star_pts, STAR_GOLD)
	draw_polyline(_closed_outline(star_pts), INK, 2.0, true)

	# Bouncing hoodie drawstrings (secondary_lag)
	for ds in [-1, 1]:
		var sx_d: float = float(ds) * 7.0 + torso.twist * 6.0
		var tip := Vector2(sx_d + lag.x * 0.55 + lag.flutter * 0.5, -36.0 + lag.y * 0.45)
		draw_polyline(_quad_pts(Vector2(sx_d, -64.0), Vector2(sx_d + lag.x * 0.25, -50.0), tip, 6), HOODIE_TRIM, 4.0, true)
		draw_polyline(_quad_pts(Vector2(sx_d, -64.0), Vector2(sx_d + lag.x * 0.25, -50.0), tip, 6), INK, 1.8, true)
		draw_circle(tip, 4.2, STAR_GOLD)
		draw_arc(tip, 4.2, 0.0, TAU, 12, INK, 2.0, true)

	# === HEAD PIVOT ANCHOR (Huge Chibi Rounded Head) ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -68.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 16.0
	var face_shift_y: float = pitch * 9.0

	# Oversized Chibi Twin-Tails (secondary_lag!)
	for t_side in [-1, 1]:
		var tail_xf := head_xf * _xform(
			Vector2(float(t_side) * 56.0, -68.0),
			lag.rot * 0.9 + float(t_side) * 0.18
		)
		draw_set_transform_matrix(tail_xf)
		var tip := Vector2(float(t_side) * 26.0 + lag.x * 1.1 + lag.flutter, 82.0 + lag.y * 0.85)
		var tail_poly := PackedVector2Array([Vector2.ZERO])
		_append_quad(tail_poly, Vector2.ZERO, Vector2(float(t_side) * 34.0 + lag.x * 0.4, 32.0), tip, 8)
		_append_quad(tail_poly, tip, Vector2(float(t_side) * 6.0 + lag.x * 0.3, 46.0), Vector2(float(t_side) * -4.0, 8.0), 8)
		draw_colored_polygon(tail_poly, HAIR_SH if t_side == -1 else HAIR_LIT)
		draw_polyline(_closed_outline(tail_poly), INK, 3.0, true)
		# Star hair tie
		draw_circle(Vector2.ZERO, 7.5, STAR_GOLD)
		draw_arc(Vector2.ZERO, 7.5, 0.0, TAU, 14, INK, 2.4, true)

	# Cute rounded chibi ears
	for ear_side in [-1, 1]:
		var ear_vis: float = clampf(1.0 - float(ear_side) * yaw * 0.85, 0.15, 1.15)
		var ear_xf := head_xf * _xform(Vector2(float(ear_side) * 58.0 - yaw * 8.0, -40.0 + face_shift_y * 0.35), 0.0, Vector2(ear_vis, 1.0))
		draw_set_transform_matrix(ear_xf)
		var ear_pts := _ellipse_pts(Vector2.ZERO, 9.0, 11.0, 14)
		draw_colored_polygon(ear_pts, SKIN_SH if ear_side == -1 else SKIN_LIT)
		draw_polyline(_closed_outline(ear_pts), INK, 3.0, true)

	# Plump squishable chibi head
	draw_set_transform_matrix(head_xf)
	var head_pts := _ellipse_pts(Vector2(0.0, -54.0), 59.0, 52.0, 32)
	draw_colored_polygon(head_pts, SKIN_LIT)
	# Soft bottom-left cheek shadow
	draw_colored_polygon(_ellipse_pts(Vector2(-12.0 + face_shift_x * 0.3, -24.0), 40.0, 18.0, 20), SKIN_SH)
	# Re-fill center lit face leaving soft rim shadow
	draw_colored_polygon(_ellipse_pts(Vector2(4.0 + face_shift_x * 0.2, -56.0), 52.0, 46.0, 28), SKIN_LIT)
	draw_polyline(_closed_outline(head_pts), INK, 3.4, true)

	# Rosy chibi cheeks
	draw_colored_polygon(_ellipse_pts(Vector2(-32.0 + face_shift_x, -26.0 + face_shift_y), 11.0, 6.0, 14), BLUSH)
	draw_colored_polygon(_ellipse_pts(Vector2(32.0 + face_shift_x, -26.0 + face_shift_y), 11.0, 6.0, 14), BLUSH)
	draw_circle(Vector2(-35.0 + face_shift_x, -27.0 + face_shift_y), 2.2, Color.WHITE)
	draw_circle(Vector2(29.0 + face_shift_x, -27.0 + face_shift_y), 2.2, Color.WHITE)

	# === HUGE JEWEL CHIBI EYES ===
	var eye_y: float = -45.0 + face_shift_y
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.32, 0.64, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.32, 0.64, 1.0)
	_draw_chibi_eye(head_xf, Vector2(-23.0 * left_fs + face_shift_x, eye_y), -1, left_fs, eyes)
	_draw_chibi_eye(head_xf, Vector2(23.0 * right_fs + face_shift_x, eye_y), 1, right_fs, eyes)

	# Tiny button nose dot
	draw_set_transform_matrix(head_xf)
	draw_circle(Vector2(face_shift_x * 1.15, -31.0 + face_shift_y * 1.1), 1.8, SKIN_SH)

	# === CUTE CHIBI MOUTH ===
	var mouth_xf := head_xf * _xform(Vector2(face_shift_x * 1.05, -20.0 + face_shift_y * 1.1))
	draw_set_transform_matrix(mouth_xf)
	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			var m_pts := _ellipse_pts(Vector2(0.0, 1.0), 5.5 + mouth.open * 3.0, 6.0 + mouth.open * 5.0, 16)
			draw_colored_polygon(m_pts, Color(0.58, 0.16, 0.22))
			draw_polyline(_closed_outline(m_pts), INK, 2.5, true)
		MotionController.MouthShape.OPEN_HAPPY:
			var d_pts := PackedVector2Array([Vector2(-9.0, -1.0), Vector2(9.0, -1.0)])
			_append_quad(d_pts, Vector2(9.0, -1.0), Vector2(7.0, 11.0 * mouth.open + 3.0), Vector2(0.0, 11.0 * mouth.open + 3.0), 5)
			_append_quad(d_pts, Vector2(0.0, 11.0 * mouth.open + 3.0), Vector2(-7.0, 11.0 * mouth.open + 3.0), Vector2(-9.0, -1.0), 5)
			draw_colored_polygon(d_pts, Color(0.75, 0.20, 0.30))
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 6.5 * mouth.open + 1.0), 5.2, 2.8, 12), Color(1.0, 0.62, 0.68))
			draw_polyline(_closed_outline(d_pts), INK, 2.4, true)
		MotionController.MouthShape.SMILE:
			# Cute cat-like ":3" chibi smile
			draw_polyline(_quad_pts(Vector2(-7.0, -1.0), Vector2(-3.5, 4.0), Vector2(0.0, -0.5), 5), INK, 2.5, true)
			draw_polyline(_quad_pts(Vector2(0.0, -0.5), Vector2(3.5, 4.0), Vector2(7.0, -1.0), 5), INK, 2.5, true)
		_:
			draw_polyline(_quad_pts(Vector2(-5.0, 0.0), Vector2(0.0, 2.5), Vector2(5.0, 0.0), 5), INK, 2.5, true)

	# Rounded Chibi Bangs + Glossy Halo Highlight
	var bangs_xf := head_xf * _xform(Vector2(face_shift_x * 0.35 + lag.x * 0.06, lag.y * 0.06))
	draw_set_transform_matrix(bangs_xf)
	var bangs := PackedVector2Array([Vector2(-60.0, -48.0)])
	_append_quad(bangs, Vector2(-60.0, -48.0), Vector2(-62.0, -112.0), Vector2(0.0, -112.0), 10)
	_append_quad(bangs, Vector2(0.0, -112.0), Vector2(62.0, -112.0), Vector2(60.0, -48.0), 10)
	bangs.append_array(PackedVector2Array([
		Vector2(48.0, -28.0), Vector2(40.0, -58.0), Vector2(24.0, -54.0),
		Vector2(12.0, -64.0), Vector2(-2.0, -50.0), Vector2(-18.0, -64.0),
		Vector2(-38.0, -52.0), Vector2(-48.0, -28.0),
	]))
	draw_colored_polygon(bangs, HAIR_LIT)
	# Glossy chibi highlight ovals across bangs
	draw_colored_polygon(_ellipse_pts(Vector2(-18.0, -82.0), 14.0, 5.0, 14), HAIR_HL)
	draw_colored_polygon(_ellipse_pts(Vector2(18.0, -82.0), 14.0, 5.0, 14), HAIR_HL)
	draw_polyline(_closed_outline(bangs), INK, 3.2, true)

	# Front stubby arm
	_draw_chibi_arm(
		torso_xf,
		Vector2(26.0 + torso.twist * 4.0, -56.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_chibi_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	side: int,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor
) -> void:
	var eye_xf := head_xf * _xform(eye_pos)
	draw_set_transform_matrix(eye_xf)

	var w: float = 17.5 * foreshorten_x
	var h: float = 20.5 * (1.0 + eyes.wide * 0.22) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.94)

	# Short rounded chibi eyebrows
	var brow_y: float = -22.0 - eyes.brow_offset * 6.0 + eyes.squint * 2.0
	draw_polyline(_quad_pts(Vector2(-w * 0.45, brow_y), Vector2(0.0, brow_y - 2.5), Vector2(w * 0.45, brow_y), 5), INK, 2.6, true)

	if eyes.blink > 0.78:
		draw_polyline(_quad_pts(Vector2(-w * 0.75, 2.0), Vector2(0.0, 7.0), Vector2(w * 0.75, 2.0), 7), INK, 3.4, true)
		return

	if eyes.squint > 0.45 and eyes.wide < 0.2:
		draw_polyline(_quad_pts(Vector2(-w * 0.75, 3.0), Vector2(0.0, -10.0), Vector2(w * 0.75, 3.0), 8), INK, 3.8, true)
		return

	# Huge rounded sclera
	var scl := _ellipse_pts(Vector2.ZERO, w * 0.92, h * 0.72, 22)
	draw_colored_polygon(scl, Color.WHITE)
	draw_polyline(_closed_outline(scl), INK, 3.0, true)

	# Jewel iris + triple sparkle catchlights
	var iris_scale: float = 1.0 - eyes.wide * 0.35 if eyes.wide > 0.2 else 1.0
	var gx: float = clampf(eyes.look_x * 4.5 * foreshorten_x, -w * 0.25, w * 0.25)
	var gy: float = clampf(eyes.look_y * 3.0, -h * 0.15, h * 0.15)
	var iw: float = minf(11.5 * foreshorten_x * iris_scale, w * 0.72)
	var ih: float = minf(13.0 * iris_scale, h * 0.64)
	var ic := Vector2(gx, gy + 0.5)

	draw_colored_polygon(_ellipse_pts(ic, iw, ih, 20), Color(0.243, 0.565, 0.898))
	draw_colored_polygon(_ellipse_pts(ic + Vector2(0.0, -ih * 0.22), iw * 0.92, ih * 0.58, 16), Color(0.141, 0.251, 0.545))
	draw_colored_polygon(_ellipse_pts(ic + Vector2(0.0, ih * 0.38), iw * 0.72, ih * 0.34, 14), Color(0.553, 0.863, 0.988))
	draw_colored_polygon(_ellipse_pts(ic, iw * 0.46, ih * 0.46, 14), INK)

	# Triple jewel catchlights
	draw_circle(ic + Vector2(-iw * 0.38, -ih * 0.34), maxf(2.2, 4.2 * iris_scale), Color.WHITE)
	draw_circle(ic + Vector2(iw * 0.36, ih * 0.32), maxf(1.2, 2.1 * iris_scale), Color.WHITE)
	draw_circle(ic + Vector2(iw * 0.35, -ih * 0.32), maxf(0.9, 1.4 * iris_scale), Color.WHITE)

	# Thick plush upper eyelash cap
	draw_polyline(_quad_pts(Vector2(-w * 0.96, -h * 0.08), Vector2(0.0, -h * 0.92), Vector2(w * 0.96, -h * 0.08), 10), INK, 4.2, true)
	draw_line(Vector2(w * 0.85 * float(side), -h * 0.15), Vector2(w * 1.05 * float(side), -h * 0.35), INK, 2.6, true)


func _draw_chibi_arm(
	torso_xf: Transform2D,
	shoulder_pos: Vector2,
	shoulder_angle: float,
	elbow_angle: float,
	hand_pose: int,
	wave_phase: float,
	is_front: bool
) -> void:
	var upper_len: float = 24.0
	var fore_len: float = 22.0

	var upper_xf := torso_xf * _xform(shoulder_pos, shoulder_angle)
	draw_set_transform_matrix(upper_xf)
	var u_poly := PackedVector2Array([
		Vector2(-9.5, -5.0), Vector2(9.5, -5.0),
		Vector2(9.0, upper_len), Vector2(-9.0, upper_len),
	])
	draw_colored_polygon(u_poly, HOODIE_LIT if is_front else HOODIE_SH)
	draw_polyline(_closed_outline(u_poly), INK, 2.8, true)

	var fore_xf := upper_xf * _xform(Vector2(0.0, upper_len - 2.0), elbow_angle)
	draw_set_transform_matrix(fore_xf)
	var f_poly := PackedVector2Array([
		Vector2(-9.0, 0.0), Vector2(9.0, 0.0),
		Vector2(8.0, fore_len - 4.0), Vector2(-8.0, fore_len - 4.0),
	])
	draw_colored_polygon(f_poly, HOODIE_LIT if is_front else HOODIE_SH)
	draw_rect(Rect2(-8.5, fore_len - 8.0, 17.0, 6.0), HOODIE_TRIM, true)
	draw_polyline(_closed_outline(f_poly), INK, 2.8, true)

	var hand_rot: float = wave_phase * 0.25 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0
	var hand_xf := fore_xf * _xform(Vector2(0.0, fore_len), hand_rot)
	draw_set_transform_matrix(hand_xf)
	var h_pts := _ellipse_pts(Vector2(0.0, 5.0), 7.5 if hand_pose != MotionController.HandPose.TENSE_SPLAY else 9.5, 7.5, 14)
	draw_colored_polygon(h_pts, SKIN_LIT if is_front else SKIN_SH)
	draw_polyline(_closed_outline(h_pts), INK, 2.6, true)
