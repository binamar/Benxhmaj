class_name CharacterGothicSketch
extends Node2D

const STYLE_TITLE: String = "Gothic Sketchy Ink"
const STYLE_SUBTITLE: String = "9-Head Elongated · Cross-Hatching · Sunken Eyes"

const INK := Color(0.075, 0.071, 0.094, 1.0)         # #131218 scratchy charcoal ink
const HATCH := Color(0.09, 0.085, 0.11, 0.55)
const SKIN_PALE := Color(0.886, 0.898, 0.918, 1.0)   # #E2E5EA moonlit porcelain
const SKIN_SOCKET := Color(0.580, 0.596, 0.655, 1.0) # #9498A7 sunken shadow
const COAT_DARK := Color(0.145, 0.141, 0.180, 1.0)   # #25242E
const COAT_PLUM := Color(0.243, 0.196, 0.278, 1.0)   # #3E3247 muted gothic plum
const SHIRT_GRAY := Color(0.710, 0.725, 0.765, 1.0)

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 128.0 * s
	var h: float = 382.0 * s
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


func _draw_hatch_block(origin: Vector2, width: float, height: float, count: int, cross: bool = true) -> void:
	for i in range(count):
		var t: float = float(i) / float(max(1, count - 1))
		var y_off: float = t * height
		draw_line(origin + Vector2(0.0, y_off), origin + Vector2(width, y_off + 3.0), HATCH, 0.9, true)
		if cross and i % 2 == 0:
			draw_line(origin + Vector2(width * 0.15, y_off + 4.0), origin + Vector2(width * 0.85, y_off - 2.0), HATCH, 0.8, true)


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

	# Narrow jagged gothic shadow
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	draw_set_transform_matrix(_xform(
		Vector2(body_root.x * 0.7, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.42, 1.0 - air_factor * 0.35)
	))
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 42.0, 9.0, 18), Color(0.04, 0.04, 0.06, 0.42))

	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean,
		Vector2(body_root.scale_x, body_root.scale_y)
	)
	draw_set_transform_matrix(root_xf)

	# === HYPER-ELONGATED SPINDLY LEGS & BUCKLED BOOTS (9-Head proportions!) ===
	var knee_bend: float = clampf((1.0 - body_root.scale_y) * 28.0, -7.0, 16.0)
	for side in [-1, 1]:
		var is_back: bool = side == -1
		var fx: float = float(side) * 11.5
		var kb: float = knee_bend * 0.25 * float(side)

		var leg_poly := PackedVector2Array([
			Vector2(float(side) * 7.5 - 6.0, -192.0),
			Vector2(float(side) * 7.5 + 6.0, -192.0),
			Vector2(fx + 5.0 + kb, -102.0),
			Vector2(fx + 4.0, -48.0),
			Vector2(fx - 4.0, -48.0),
			Vector2(fx - 5.0 + kb, -102.0),
		])
		draw_colored_polygon(leg_poly, INK if is_back else COAT_DARK)
		if not is_back:
			_draw_hatch_block(Vector2(fx - 4.0, -155.0), 8.0, 60.0, 8, false)
		draw_polyline(_closed_outline(leg_poly), INK, 1.7, true)

		# Tall pointed buckled gothic boot
		var boot := PackedVector2Array([
			Vector2(fx - 5.2, -52.0),
			Vector2(fx + 5.2, -52.0),
			Vector2(fx + 5.0, -10.0),
			Vector2(fx + 18.0 * float(side) + 3.0, -2.0),
			Vector2(fx + 18.0 * float(side) + 3.0, 0.0),
			Vector2(fx - 6.5, 0.0),
		])
		draw_colored_polygon(boot, INK)
		# Silver buckle bars
		for by in [-42.0, -30.0, -18.0]:
			draw_rect(Rect2(fx - 4.5, by, 9.0, 3.0), SHIRT_GRAY, false, 1.1)

	# === TORSO ANCHOR (Wasp-waist Victorian Frock Coat) ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -190.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x * (1.0 - absf(torso.twist) * 0.06), torso.breath_scale_y)
	)

	# Tattered split coat-tails (secondary_lag!)
	var tails_xf := torso_xf * _xform(Vector2(0.0, -6.0), lag.rot * 0.85)
	draw_set_transform_matrix(tails_xf)
	var t_l := Vector2(-28.0 + lag.x * 1.2 + lag.flutter, 134.0 + lag.y * 0.9)
	var t_r := Vector2(22.0 + lag.x * 1.0 + lag.flutter, 128.0 + lag.y * 0.85)
	var tails := PackedVector2Array([
		Vector2(-14.0, -4.0), Vector2(14.0, -4.0),
		t_r, Vector2(4.0 + lag.x * 0.8, 92.0 + lag.y * 0.6), t_l,
	])
	draw_colored_polygon(tails, COAT_DARK)
	draw_polyline(_closed_outline(tails), INK, 1.8, true)

	# Back spindly arm
	_draw_gothic_arm(
		torso_xf,
		Vector2(-22.0 + torso.twist * 4.0, -110.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		false
	)

	# Wasp-waisted frock coat + high Victorian collar
	draw_set_transform_matrix(torso_xf)
	var torso_h: float = 118.0
	var coat_poly := PackedVector2Array([
		Vector2(-24.0, -torso_h + 8.0),
		Vector2(0.0, -torso_h),
		Vector2(24.0, -torso_h + 8.0),
		Vector2(11.0, -34.0),
		Vector2(17.0, 4.0),
		Vector2(-17.0, 4.0),
		Vector2(-11.0, -34.0),
	])
	draw_colored_polygon(coat_poly, COAT_PLUM)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24.0, -torso_h + 8.0), Vector2(-3.0, -torso_h + 2.0),
		Vector2(-4.0, 4.0), Vector2(-17.0, 4.0), Vector2(-11.0, -34.0),
	]), COAT_DARK)
	_draw_hatch_block(Vector2(-18.0, -104.0), 14.0, 62.0, 9, true)
	draw_polyline(_closed_outline(coat_poly), INK, 1.9, true)

	# Crisp pinstripe cravat / vest center
	var cravat := PackedVector2Array([
		Vector2(-8.0 + torso.twist * 6.0, -torso_h + 2.0),
		Vector2(8.0 + torso.twist * 6.0, -torso_h + 2.0),
		Vector2(3.0 + torso.twist * 7.0, -40.0),
		Vector2(-3.0 + torso.twist * 7.0, -40.0),
	])
	draw_colored_polygon(cravat, SHIRT_GRAY)
	draw_polyline(_closed_outline(cravat), INK, 1.4, true)

	# High flared gothic collar
	var collar := PackedVector2Array([
		Vector2(-14.0, -torso_h + 4.0), Vector2(-21.0, -torso_h - 18.0),
		Vector2(21.0, -torso_h - 18.0), Vector2(14.0, -torso_h + 4.0),
	])
	draw_colored_polygon(collar, COAT_DARK)
	draw_polyline(_closed_outline(collar), INK, 1.8, true)

	# Long slender hatched neck
	draw_rect(Rect2(-5.0, -torso_h - 22.0, 10.0, 24.0), SKIN_PALE, true)
	_draw_hatch_block(Vector2(-4.5, -torso_h - 20.0), 8.0, 14.0, 5, true)
	draw_rect(Rect2(-5.0, -torso_h - 22.0, 10.0, 24.0), INK, false, 1.5)

	# === HEAD PIVOT ANCHOR (9-Head Smaller Angular Pale Head) ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -torso_h - 22.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 8.5
	var face_shift_y: float = pitch * 4.5

	# Jagged raven-feather back hair strands (secondary_lag)
	draw_set_transform_matrix(head_xf * _xform(Vector2(lag.x * 0.14, lag.y * 0.14), lag.rot * 0.25))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24.0, -28.0), Vector2(-12.0, -56.0), Vector2(14.0, -55.0),
		Vector2(25.0, -28.0), Vector2(28.0, 2.0), Vector2(16.0, -8.0),
		Vector2(-16.0, -8.0), Vector2(-28.0, 4.0),
	]), INK)

	# Gaunt angular skull/cheekbones contour
	draw_set_transform_matrix(head_xf)
	var chin := Vector2(yaw * 4.0, 3.0 + pitch * 2.5)
	var head_poly := PackedVector2Array([
		Vector2(-16.5, -28.0), Vector2(-13.0, -45.0), Vector2(13.0, -45.0), Vector2(16.5, -28.0),
		Vector2(11.0 + yaw * 2.0, -10.0), chin, Vector2(-11.0 + yaw * 2.0, -10.0),
	])
	draw_colored_polygon(head_poly, SKIN_PALE)
	# Cross-hatched hollow cheek shadows!
	_draw_hatch_block(Vector2(-14.5 + face_shift_x * 0.4, -18.0), 8.0, 10.0, 4, true)
	_draw_hatch_block(Vector2(6.5 + face_shift_x * 0.4, -18.0), 8.0, 10.0, 4, false)
	draw_polyline(_closed_outline(head_poly), INK, 1.8, true)

	# === SUNKEN CIRCULAR GOTHIC EYES ===
	var eye_y: float = -22.5 + face_shift_y
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.35, 0.58, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.35, 0.58, 1.0)
	_draw_gothic_eye(head_xf, Vector2(-6.8 * left_fs + face_shift_x, eye_y), left_fs, eyes)
	_draw_gothic_eye(head_xf, Vector2(6.8 * right_fs + face_shift_x, eye_y), right_fs, eyes)

	# Sharp thin gothic nose
	draw_set_transform_matrix(head_xf)
	var nx: float = face_shift_x * 1.15
	var ny: float = -20.5 + face_shift_y
	draw_polyline(PackedVector2Array([Vector2(nx, ny), Vector2(nx + 2.5, ny + 7.5), Vector2(nx - 1.5, ny + 8.0)]), INK, 1.2, true)

	# === STITCHED / EXPRESSIVE GOTHIC MOUTH ===
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 1.05, -6.5 + face_shift_y * 1.1)))
	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 0.8), 3.2 + mouth.open * 1.8, 3.8 + mouth.open * 3.0, 12), INK)
		MotionController.MouthShape.OPEN_HAPPY:
			var grin := PackedVector2Array([Vector2(-6.5, 0.0), Vector2(6.5, 0.0), Vector2(4.0, 4.5 * mouth.open + 1.5), Vector2(-4.0, 4.5 * mouth.open + 1.5)])
			draw_colored_polygon(grin, SKIN_PALE)
			draw_polyline(_closed_outline(grin), INK, 1.4, true)
			for tx in [-3.0, 0.0, 3.0]:
				draw_line(Vector2(tx, 0.0), Vector2(tx, 3.5), INK, 1.0, true)
		MotionController.MouthShape.SMILE:
			draw_polyline(_quad_pts(Vector2(-5.5, 0.2), Vector2(0.0, 2.2), Vector2(5.5, -0.4), 5), INK, 1.4, true)
		_:
			draw_line(Vector2(-5.0, 0.5), Vector2(5.0, 0.5), INK, 1.3, true)

	# Jagged hanging raven bangs (secondary_lag)
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 0.35 + lag.x * 0.06, lag.y * 0.06)))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18.0, -28.0), Vector2(-14.0, -49.0), Vector2(14.0, -49.0), Vector2(18.0, -28.0),
		Vector2(14.0, -34.0), Vector2(6.0, -22.0 + lag.y * 0.05), Vector2(1.0, -35.0),
		Vector2(-7.0, -20.0 + lag.y * 0.05), Vector2(-14.0, -33.0),
	]), INK)

	# Front spindly arm
	_draw_gothic_arm(
		torso_xf,
		Vector2(22.0 + torso.twist * 4.0, -110.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_gothic_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor
) -> void:
	draw_set_transform_matrix(head_xf * _xform(eye_pos))
	var r: float = 5.0 * foreshorten_x
	var ry: float = 4.8 * (1.0 + eyes.wide * 0.32) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.94)

	# Dark sunken orbital eye socket shadow
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, r * 1.35, 6.8, 14), SKIN_SOCKET)
	# Fine arched brow
	var brow_y: float = -7.5 - eyes.brow_offset * 3.5 + eyes.squint * 1.2
	draw_polyline(_quad_pts(Vector2(-r, brow_y + 1.0), Vector2(0.0, brow_y - 1.5), Vector2(r, brow_y + 1.0), 4), INK, 1.3, true)

	if eyes.blink > 0.78:
		draw_line(Vector2(-r, 0.5), Vector2(r, 0.5), INK, 1.7, true)
		return

	var scl := _ellipse_pts(Vector2.ZERO, r, ry, 14)
	draw_colored_polygon(scl, Color.WHITE)
	draw_polyline(_closed_outline(scl), INK, 1.5, true)

	var gx: float = clampf(eyes.look_x * 2.0 * foreshorten_x, -r * 0.45, r * 0.45)
	var gy: float = clampf(eyes.look_y * 1.6, -ry * 0.35, ry * 0.35)
	var pr: float = 1.4 if eyes.wide > 0.3 else 1.8
	draw_circle(Vector2(gx, gy), pr, INK)


func _draw_gothic_arm(
	torso_xf: Transform2D,
	shoulder_pos: Vector2,
	shoulder_angle: float,
	elbow_angle: float,
	hand_pose: int,
	wave_phase: float,
	is_front: bool
) -> void:
	var upper_len: float = 64.0
	var fore_len: float = 62.0

	var upper_xf := torso_xf * _xform(shoulder_pos, shoulder_angle)
	draw_set_transform_matrix(upper_xf)
	var u_poly := PackedVector2Array([
		Vector2(-5.5, -4.0), Vector2(5.5, -4.0),
		Vector2(4.5, upper_len), Vector2(-4.5, upper_len),
	])
	draw_colored_polygon(u_poly, COAT_PLUM if is_front else COAT_DARK)
	draw_polyline(_closed_outline(u_poly), INK, 1.6, true)

	var fore_xf := upper_xf * _xform(Vector2(0.0, upper_len - 2.0), elbow_angle)
	draw_set_transform_matrix(fore_xf)
	var f_poly := PackedVector2Array([
		Vector2(-4.8, 0.0), Vector2(4.8, 0.0),
		Vector2(3.6, fore_len - 6.0), Vector2(-3.6, fore_len - 6.0),
	])
	draw_colored_polygon(f_poly, COAT_PLUM if is_front else COAT_DARK)
	draw_polyline(_closed_outline(f_poly), INK, 1.6, true)

	var hand_rot: float = wave_phase * 0.22 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0
	draw_set_transform_matrix(fore_xf * _xform(Vector2(0.0, fore_len - 4.0), hand_rot))
	var h_col: Color = SKIN_PALE if is_front else SKIN_SOCKET
	var palm := PackedVector2Array([Vector2(-3.5, 0.0), Vector2(3.5, 0.0), Vector2(4.5, 7.0), Vector2(-4.5, 7.0)])
	draw_colored_polygon(palm, h_col)
	draw_polyline(_closed_outline(palm), INK, 1.4, true)
	# Long bony gothic fingers
	for fi in [-3.2, -1.0, 1.2, 3.4]:
		var spread: float = fi * (1.8 if hand_pose == MotionController.HandPose.TENSE_SPLAY else 1.1)
		draw_line(Vector2(fi, 7.0), Vector2(spread, 17.5), INK, 1.5, true)
