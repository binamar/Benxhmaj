class_name CharacterPaperCutout
extends Node2D

const STYLE_TITLE: String = "Layered Paper Cutout"
const STYLE_SUBTITLE: String = "Origami Facets · Offset Drop-Shadows · Fold Creases"

const DROP_SHADOW := Color(0.04, 0.04, 0.07, 0.28)
const CREASE_DARK := Color(0.18, 0.14, 0.12, 0.26)
const CREASE_LIGHT := Color(1.0, 0.99, 0.95, 0.45)

const VELLUM := Color(0.957, 0.914, 0.843, 1.0)     # #F4E9D7 warm cream paper
const VELLUM_FOLD := Color(0.890, 0.824, 0.725, 1.0)
const TEAL_PAPER := Color(0.192, 0.494, 0.525, 1.0)  # #317E86 muted teal cardstock
const TEAL_FOLD := Color(0.137, 0.376, 0.408, 1.0)
const SIENNA_PAPER := Color(0.816, 0.388, 0.251, 1.0)# #D06340 burnt sienna
const SIENNA_FOLD := Color(0.659, 0.278, 0.169, 1.0)
const MUSTARD_PAPER := Color(0.902, 0.690, 0.259, 1.0)# #E6B042
const SLATE_PAPER := Color(0.247, 0.267, 0.322, 1.0) # #3F4452
const INK_CUT := Color(0.18, 0.15, 0.14, 0.40)

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 148.0 * s
	var h: float = 352.0 * s
	return Rect2(position.x + bx * s - w * 0.5, position.y + by * s - h, w, h)


static func _xform(pos: Vector2, rot: float = 0.0, scl: Vector2 = Vector2.ONE) -> Transform2D:
	return Transform2D(0.0, pos) * Transform2D(rot, Vector2.ZERO) * Transform2D.IDENTITY.scaled(scl)


static func _ellipse_pts(center: Vector2, rx: float, ry: float, segments: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a: float = (float(i) / float(segments)) * TAU
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _draw_paper_poly(poly: PackedVector2Array, col: Color, shadow_offset: Vector2 = Vector2(3.5, 4.5)) -> void:
	var sh := PackedVector2Array()
	for pt in poly:
		sh.append(pt + shadow_offset)
	draw_colored_polygon(sh, DROP_SHADOW)
	draw_colored_polygon(poly, col)
	var out: PackedVector2Array = poly.duplicate()
	out.append(poly[0])
	draw_polyline(out, INK_CUT, 1.0, true)


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

	# Crisp paper cutout floor shadow
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	draw_set_transform_matrix(_xform(
		Vector2(body_root.x * 0.7 + 4.0, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.42, 1.0 - air_factor * 0.35)
	))
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 50.0, 10.0, 18), DROP_SHADOW)

	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean,
		Vector2(body_root.scale_x, body_root.scale_y)
	)
	draw_set_transform_matrix(root_xf)

	# === FACETED PAPER LEGS & FOLDED BOOTS ===
	for side in [-1, 1]:
		var is_back: bool = side == -1
		var fx: float = float(side) * 15.0
		var leg_poly := PackedVector2Array([
			Vector2(fx - 9.0, -138.0), Vector2(fx + 9.0, -138.0),
			Vector2(fx + 7.0, -22.0), Vector2(fx - 7.0, -22.0),
		])
		_draw_paper_poly(leg_poly, SLATE_PAPER if not is_back else Color(0.19, 0.21, 0.25), Vector2(2.5, 3.0))
		# Origami crease line down center of leg
		draw_line(Vector2(fx, -138.0), Vector2(fx, -22.0), CREASE_LIGHT, 1.2, true)

		var boot := PackedVector2Array([
			Vector2(fx - 8.5, -24.0), Vector2(fx + 8.5, -24.0),
			Vector2(fx + 18.0 * float(side) + 4.0, -5.0),
			Vector2(fx + 16.0 * float(side) + 4.0, 0.0),
			Vector2(fx - 10.0, 0.0),
		])
		_draw_paper_poly(boot, SIENNA_FOLD if is_back else SIENNA_PAPER, Vector2(2.5, 3.0))

	# === TORSO ANCHOR ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -136.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x * (1.0 - absf(torso.twist) * 0.06), torso.breath_scale_y)
	)

	# Origami tail ribbon (secondary_lag behind torso)
	var rib_xf := torso_xf * _xform(Vector2(-10.0, -88.0), lag.rot * 0.85)
	draw_set_transform_matrix(rib_xf)
	var r_tip := Vector2(-38.0 + lag.x * 1.15 + lag.flutter, 90.0 + lag.y * 0.85)
	_draw_paper_poly(PackedVector2Array([
		Vector2(-6.0, 0.0), Vector2(10.0, 2.0),
		r_tip + Vector2(14.0, -10.0),
		r_tip + Vector2(4.0, -2.0),
		r_tip,
	]), MUSTARD_PAPER, Vector2(4.0, 5.0))

	# Back paper arm
	_draw_paper_arm(
		torso_xf,
		Vector2(-28.0 + torso.twist * 5.0, -84.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		false
	)

	# Layered Paper Tunic & Pleated Origami Skirt Overlay
	draw_set_transform_matrix(torso_xf)
	var torso_h: float = 94.0

	# Pleated paper skirt flaps (layered triangles)
	_draw_paper_poly(PackedVector2Array([
		Vector2(-24.0, -24.0), Vector2(24.0, -24.0),
		Vector2(34.0 + lag.x * 0.25, 22.0 + lag.y * 0.2),
		Vector2(0.0, 16.0),
		Vector2(-34.0 + lag.x * 0.25, 22.0 + lag.y * 0.2),
	]), TEAL_FOLD, Vector2(3.5, 4.5))

	# Tunic body with origami center-fold split
	_draw_paper_poly(PackedVector2Array([
		Vector2(-27.0, -torso_h + 6.0),
		Vector2(0.0, -torso_h),
		Vector2(27.0, -torso_h + 6.0),
		Vector2(24.0, -14.0),
		Vector2(-24.0, -14.0),
	]), TEAL_PAPER, Vector2(4.0, 5.0))

	# Folded right half plane (origami ridge)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0 + torso.twist * 8.0, -torso_h),
		Vector2(27.0, -torso_h + 6.0),
		Vector2(24.0, -14.0),
		Vector2(0.0 + torso.twist * 8.0, -14.0),
	]), TEAL_FOLD)
	draw_line(Vector2(0.0 + torso.twist * 8.0, -torso_h), Vector2(0.0 + torso.twist * 8.0, -14.0), CREASE_LIGHT, 1.4, true)

	# Scalloped origami paper collar (3 overlapping triangles)
	for cx_i in [-16.0, 0.0, 16.0]:
		_draw_paper_poly(PackedVector2Array([
			Vector2(cx_i - 10.0, -torso_h + 2.0),
			Vector2(cx_i + 10.0, -torso_h + 2.0),
			Vector2(cx_i, -torso_h + 20.0),
		]), MUSTARD_PAPER if cx_i == 0.0 else VELLUM, Vector2(2.5, 3.5))

	# Layered paper neck
	_draw_paper_poly(PackedVector2Array([
		Vector2(-7.5, -torso_h - 14.0), Vector2(7.5, -torso_h - 14.0),
		Vector2(8.5, -torso_h + 3.0), Vector2(-8.5, -torso_h + 3.0),
	]), VELLUM_FOLD, Vector2(2.5, 3.0))

	# === HEAD PIVOT ANCHOR ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -torso_h - 14.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 11.0
	var face_shift_y: float = pitch * 6.0

	# Back faceted origami hair shell (secondary_lag)
	draw_set_transform_matrix(head_xf * _xform(Vector2(lag.x * 0.12, lag.y * 0.12), lag.rot * 0.2))
	_draw_paper_poly(PackedVector2Array([
		Vector2(-32.0, -34.0), Vector2(-20.0, -68.0), Vector2(20.0, -68.0),
		Vector2(32.0, -34.0), Vector2(26.0, -6.0), Vector2(-26.0, -6.0),
	]), SIENNA_FOLD, Vector2(4.0, 5.0))

	# Faceted Paper Head (decagonal craft cutout with drop shadow!)
	draw_set_transform_matrix(head_xf)
	var chin := Vector2(yaw * 5.0, 4.0 + pitch * 3.5)
	var head_poly := PackedVector2Array([
		Vector2(-25.0, -32.0), Vector2(-20.0, -54.0), Vector2(0.0, -60.0),
		Vector2(20.0, -54.0), Vector2(25.0, -32.0),
		Vector2(20.0 + yaw * 2.0, -10.0), chin, Vector2(-20.0 + yaw * 2.0, -10.0),
	])
	_draw_paper_poly(head_poly, VELLUM, Vector2(3.5, 4.5))
	# Vertical origami center-face crease plane
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0 + face_shift_x * 0.5, -60.0),
		Vector2(-20.0, -54.0), Vector2(-25.0, -32.0),
		Vector2(-20.0 + yaw * 2.0, -10.0), chin,
		Vector2(face_shift_x * 0.5, -10.0),
	]), VELLUM_FOLD)

	# Paper cutout rosy cheek triangles
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18.0 + face_shift_x, -16.0 + face_shift_y),
		Vector2(-10.0 + face_shift_x, -18.0 + face_shift_y),
		Vector2(-13.0 + face_shift_x, -12.0 + face_shift_y),
	]), Color(0.85, 0.42, 0.35, 0.55))
	draw_colored_polygon(PackedVector2Array([
		Vector2(18.0 + face_shift_x, -16.0 + face_shift_y),
		Vector2(10.0 + face_shift_x, -18.0 + face_shift_y),
		Vector2(13.0 + face_shift_x, -12.0 + face_shift_y),
	]), Color(0.85, 0.42, 0.35, 0.55))

	# === LAYERED PAPER DISC EYES ===
	var eye_y: float = -27.0 + face_shift_y
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.35, 0.62, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.35, 0.62, 1.0)
	_draw_paper_eye(head_xf, Vector2(-10.5 * left_fs + face_shift_x, eye_y), left_fs, eyes)
	_draw_paper_eye(head_xf, Vector2(10.5 * right_fs + face_shift_x, eye_y), right_fs, eyes)

	# Folded triangle paper nose (with mini shadow!)
	draw_set_transform_matrix(head_xf)
	var nx: float = face_shift_x * 1.15
	var ny: float = -23.0 + face_shift_y
	_draw_paper_poly(PackedVector2Array([
		Vector2(nx, ny), Vector2(nx + 4.5, ny + 8.5), Vector2(nx - 2.5, ny + 8.0),
	]), VELLUM, Vector2(2.0, 2.5))

	# Cutout paper mouth
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 1.05, -7.0 + face_shift_y * 1.1)))
	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 1.0), 4.0 + mouth.open * 2.2, 4.5 + mouth.open * 3.8, 12), SLATE_PAPER)
		MotionController.MouthShape.OPEN_HAPPY:
			draw_colored_polygon(PackedVector2Array([
				Vector2(-7.0, -0.5), Vector2(7.0, -0.5),
				Vector2(4.5, 6.5 * mouth.open + 2.0), Vector2(-4.5, 6.5 * mouth.open + 2.0),
			]), SIENNA_FOLD)
		MotionController.MouthShape.SMILE:
			draw_polyline(PackedVector2Array([Vector2(-6.0, -0.5), Vector2(0.0, 3.0), Vector2(6.0, -0.5)]), SLATE_PAPER, 2.0, true)
		_:
			draw_line(Vector2(-4.5, 0.5), Vector2(4.5, 0.5), SLATE_PAPER, 1.8, true)

	# Faceted Layered Bangs (on top with drop shadow!)
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 0.4 + lag.x * 0.05, lag.y * 0.05)))
	_draw_paper_poly(PackedVector2Array([
		Vector2(-27.0, -33.0), Vector2(-22.0, -61.0), Vector2(0.0, -64.0),
		Vector2(22.0, -61.0), Vector2(27.0, -33.0),
		Vector2(14.0, -45.0), Vector2(2.0, -35.0), Vector2(-10.0, -47.0), Vector2(-20.0, -35.0),
	]), SIENNA_PAPER, Vector2(3.0, 4.0))

	# Front paper arm
	_draw_paper_arm(
		torso_xf,
		Vector2(28.0 + torso.twist * 5.0, -84.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_paper_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor
) -> void:
	draw_set_transform_matrix(head_xf * _xform(eye_pos))
	var w: float = 6.2 * foreshorten_x
	var h: float = 6.2 * (1.0 + eyes.wide * 0.35) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.92)

	var brow_y: float = -8.5 - eyes.brow_offset * 3.8 + eyes.squint * 1.2
	_draw_paper_poly(PackedVector2Array([
		Vector2(-w, brow_y - 1.5), Vector2(w, brow_y - 1.5),
		Vector2(w * 0.9, brow_y + 1.5), Vector2(-w * 0.9, brow_y + 1.5),
	]), SIENNA_FOLD, Vector2(1.5, 2.0))

	if eyes.blink > 0.78:
		draw_line(Vector2(-w, 0.5), Vector2(w, 0.5), SLATE_PAPER, 2.2, true)
		return

	if eyes.squint > 0.45 and eyes.wide < 0.2:
		draw_polyline(PackedVector2Array([Vector2(-w, 1.5), Vector2(0.0, -4.5), Vector2(w, 1.5)]), SLATE_PAPER, 2.4, true)
		return

	# Stacked paper discs
	_draw_paper_poly(_ellipse_pts(Vector2.ZERO, w, h, 14), Color.WHITE, Vector2(1.5, 2.0))
	var gx: float = clampf(eyes.look_x * 2.2 * foreshorten_x, -w * 0.35, w * 0.35)
	var gy: float = clampf(eyes.look_y * 1.5, -h * 0.25, h * 0.25)
	var ir: float = minf(3.2 * (1.0 - eyes.wide * 0.3 if eyes.wide > 0.2 else 1.0), h * 0.78)
	draw_colored_polygon(_ellipse_pts(Vector2(gx, gy), ir * foreshorten_x, ir, 12), TEAL_PAPER)
	draw_circle(Vector2(gx, gy), ir * 0.45, SLATE_PAPER)


func _draw_paper_arm(
	torso_xf: Transform2D,
	shoulder_pos: Vector2,
	shoulder_angle: float,
	elbow_angle: float,
	hand_pose: int,
	wave_phase: float,
	is_front: bool
) -> void:
	var upper_len: float = 46.0
	var fore_len: float = 44.0

	var upper_xf := torso_xf * _xform(shoulder_pos, shoulder_angle)
	draw_set_transform_matrix(upper_xf)
	_draw_paper_poly(PackedVector2Array([
		Vector2(-8.0, -5.0), Vector2(8.0, -5.0),
		Vector2(6.5, upper_len), Vector2(-6.5, upper_len),
	]), TEAL_PAPER if is_front else TEAL_FOLD, Vector2(3.0, 3.5))

	var fore_xf := upper_xf * _xform(Vector2(0.0, upper_len - 2.0), elbow_angle)
	draw_set_transform_matrix(fore_xf)
	_draw_paper_poly(PackedVector2Array([
		Vector2(-6.8, 0.0), Vector2(6.8, 0.0),
		Vector2(5.2, fore_len - 6.0), Vector2(-5.2, fore_len - 6.0),
	]), VELLUM if is_front else VELLUM_FOLD, Vector2(2.5, 3.0))

	var hand_rot: float = wave_phase * 0.22 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0
	draw_set_transform_matrix(fore_xf * _xform(Vector2(0.0, fore_len - 4.0), hand_rot))
	_draw_paper_poly(PackedVector2Array([
		Vector2(-5.0, 0.0), Vector2(5.0, 0.0),
		Vector2(6.5, 9.0), Vector2(0.0, 15.0), Vector2(-6.5, 9.0),
	]), VELLUM if is_front else VELLUM_FOLD, Vector2(2.0, 2.5))
