class_name CharacterPainterlyGouache
extends Node2D

const STYLE_TITLE: String = "Painterly Gouache"
const STYLE_SUBTITLE: String = "Translucent Brush Washes · Warm Edges · Soft Layering"

# Warm storybook gouache / watercolor wash palette (no harsh black outlines!)
const EDGE_WARM := Color(0.322, 0.204, 0.165, 0.58)    # soft umber contour wash
const SKIN_BASE := Color(0.953, 0.824, 0.729, 1.0)     # #F3D2BA
const SKIN_WASH1 := Color(0.875, 0.659, 0.561, 0.55)   # translucent peach-ochre wash
const SKIN_WASH2 := Color(0.761, 0.490, 0.420, 0.45)   # deeper terracotta wash
const CHEEK_ROSE := Color(0.898, 0.478, 0.451, 0.40)

const HAIR_BASE := Color(0.557, 0.290, 0.212, 1.0)     # #8E4A36 warm chestnut
const HAIR_WASH := Color(0.392, 0.188, 0.149, 0.55)
const HAIR_GLOW := Color(0.769, 0.482, 0.357, 0.50)

const SMOCK_BASE := Color(0.875, 0.835, 0.769, 1.0)    # #DFD5C4 linen smock
const SMOCK_WASH := Color(0.745, 0.690, 0.616, 0.55)
const SHAWL_BASE := Color(0.427, 0.541, 0.459, 1.0)    # #6D8A75 sage woven shawl
const SHAWL_WASH := Color(0.286, 0.380, 0.318, 0.58)
const SHAWL_TRIM := Color(0.788, 0.569, 0.353, 0.85)

const SKIRT_BASE := Color(0.369, 0.290, 0.376, 1.0)    # #5E4A60 dusty plum
const SKIRT_WASH := Color(0.251, 0.188, 0.263, 0.60)
const BOOT_BASE := Color(0.349, 0.243, 0.200, 1.0)

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 148.0 * s
	var h: float = 354.0 * s
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

	# Soft multi-layered watercolor shadow wash
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	draw_set_transform_matrix(_xform(
		Vector2(body_root.x * 0.7, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.42, 1.0 - air_factor * 0.35)
	))
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 56.0, 12.0, 22), Color(0.16, 0.12, 0.15, 0.20))
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 38.0, 8.0, 20), Color(0.12, 0.09, 0.12, 0.22))

	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean,
		Vector2(body_root.scale_x, body_root.scale_y)
	)
	draw_set_transform_matrix(root_xf)

	# === LOWER LEGS & SOFT LEATHER BOOTS ===
	for side in [-1, 1]:
		var is_back: bool = side == -1
		var fx: float = float(side) * 14.0
		var leg_poly := PackedVector2Array([
			Vector2(fx - 7.0, -90.0), Vector2(fx + 7.0, -90.0),
			Vector2(fx + 5.5, -22.0), Vector2(fx - 5.5, -22.0),
		])
		draw_colored_polygon(leg_poly, SKIN_BASE)
		draw_colored_polygon(leg_poly, SKIN_WASH1 if not is_back else SKIN_WASH2)

		var boot := PackedVector2Array([
			Vector2(fx - 6.5, -26.0), Vector2(fx + 6.5, -26.0),
			Vector2(fx + 14.0 * float(side) + 4.0, -4.0),
			Vector2(fx + 14.0 * float(side) + 4.0, 0.0),
			Vector2(fx - 8.0, 0.0),
		])
		draw_colored_polygon(boot, BOOT_BASE)
		draw_colored_polygon(_ellipse_pts(Vector2(fx + 4.0 * float(side), -8.0), 8.0, 4.0, 12), Color(0.48, 0.35, 0.28, 0.45))
		draw_polyline(_closed_outline(boot), EDGE_WARM, 1.1, true)

	# === LAYERED FLOWING SKIRT (reacts gently to lag) ===
	var skirt_poly := PackedVector2Array([
		Vector2(-21.0, -144.0 + torso.offset_y),
		Vector2(21.0, -144.0 + torso.offset_y),
		Vector2(38.0 + lag.x * 0.45, -42.0 + lag.y * 0.25),
		Vector2(8.0 + lag.x * 0.4, -36.0 + lag.y * 0.25),
		Vector2(-36.0 + lag.x * 0.45, -44.0 + lag.y * 0.25),
	])
	draw_colored_polygon(skirt_poly, SKIRT_BASE)
	# Overlapping gouache fold washes
	draw_colored_polygon(PackedVector2Array([
		Vector2(-21.0, -144.0 + torso.offset_y),
		Vector2(-2.0, -144.0 + torso.offset_y),
		Vector2(-8.0 + lag.x * 0.4, -38.0 + lag.y * 0.25),
		Vector2(-36.0 + lag.x * 0.45, -44.0 + lag.y * 0.25),
	]), SKIRT_WASH)
	draw_colored_polygon(PackedVector2Array([
		Vector2(6.0, -144.0 + torso.offset_y),
		Vector2(18.0, -144.0 + torso.offset_y),
		Vector2(28.0 + lag.x * 0.42, -40.0 + lag.y * 0.25),
		Vector2(10.0 + lag.x * 0.4, -37.0 + lag.y * 0.25),
	]), SKIRT_WASH)
	draw_polyline(_closed_outline(skirt_poly), EDGE_WARM, 1.2, true)

	# === TORSO ANCHOR ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -142.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x * (1.0 - absf(torso.twist) * 0.06), torso.breath_scale_y)
	)

	# Back shawl drape tail (secondary_lag)
	var back_shawl_xf := torso_xf * _xform(Vector2(-10.0, -86.0), lag.rot * 0.85)
	draw_set_transform_matrix(back_shawl_xf)
	var b_shawl := PackedVector2Array([Vector2(-16.0, 0.0), Vector2(12.0, 2.0)])
	var bs_tip := Vector2(-34.0 + lag.x * 1.1 + lag.flutter, 96.0 + lag.y * 0.8)
	_append_quad(b_shawl, Vector2(12.0, 2.0), Vector2(4.0 + lag.x * 0.5, 48.0), bs_tip + Vector2(22.0, -6.0), 7)
	b_shawl.append(bs_tip)
	_append_quad(b_shawl, bs_tip, Vector2(-30.0 + lag.x * 0.55, 48.0), Vector2(-16.0, 0.0), 7)
	draw_colored_polygon(b_shawl, SHAWL_BASE)
	draw_colored_polygon(b_shawl, SHAWL_WASH)

	# Back painter arm
	_draw_gouache_arm(
		torso_xf,
		Vector2(-25.0 + torso.twist * 5.0, -82.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		false
	)

	# Linen smock + Draped Woven Sage Shawl
	draw_set_transform_matrix(torso_xf)
	var torso_h: float = 94.0
	var smock_poly := PackedVector2Array([
		Vector2(-24.0, -torso_h + 6.0),
		Vector2(24.0, -torso_h + 6.0),
		Vector2(23.0, 6.0),
		Vector2(-23.0, 6.0),
	])
	draw_colored_polygon(smock_poly, SMOCK_BASE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24.0, -torso_h + 6.0), Vector2(-4.0, -torso_h + 6.0),
		Vector2(-6.0, 6.0), Vector2(-23.0, 6.0),
	]), SMOCK_WASH)
	draw_polyline(_closed_outline(smock_poly), EDGE_WARM, 1.15, true)

	# Draped Sage Shawl wrapping shoulders + soft ochre trim
	var shawl_front := PackedVector2Array([
		Vector2(-29.0, -torso_h + 4.0),
		Vector2(29.0, -torso_h + 4.0),
		Vector2(26.0, -torso_h + 36.0),
		Vector2(4.0 + torso.twist * 8.0, -torso_h + 48.0),
		Vector2(-26.0, -torso_h + 34.0),
	])
	draw_colored_polygon(shawl_front, SHAWL_BASE)
	draw_colored_polygon(_ellipse_pts(Vector2(-10.0, -torso_h + 24.0), 16.0, 14.0, 16), SHAWL_WASH)
	draw_polyline(PackedVector2Array([
		Vector2(-25.0, -torso_h + 30.0), Vector2(4.0 + torso.twist * 8.0, -torso_h + 43.0), Vector2(25.0, -torso_h + 32.0)
	]), SHAWL_TRIM, 2.4, true)
	draw_polyline(_closed_outline(shawl_front), EDGE_WARM, 1.2, true)

	# Neck + soft warm wash shadow
	draw_rect(Rect2(-7.0, -torso_h - 15.0, 14.0, 18.0), SKIN_BASE, true)
	draw_colored_polygon(_ellipse_pts(Vector2(-1.0, -torso_h - 10.0), 7.5, 6.5, 12), SKIN_WASH1)

	# === HEAD PIVOT ANCHOR ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -torso_h - 14.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 11.0
	var face_shift_y: float = pitch * 6.0

	# Tousled back hair waves (secondary_lag)
	draw_set_transform_matrix(head_xf * _xform(Vector2(lag.x * 0.14, lag.y * 0.14), lag.rot * 0.25))
	var back_hair := _ellipse_pts(Vector2(0.0, -24.0), 34.0, 32.0, 22)
	draw_colored_polygon(back_hair, HAIR_BASE)
	draw_colored_polygon(_ellipse_pts(Vector2(-8.0, -14.0), 26.0, 20.0, 16), HAIR_WASH)

	# Ears
	for ear_side in [-1, 1]:
		var ear_vis: float = clampf(1.0 - float(ear_side) * yaw * 0.85, 0.15, 1.15)
		draw_set_transform_matrix(head_xf * _xform(Vector2(float(ear_side) * 23.0 - yaw * 5.0, -22.0 + face_shift_y * 0.35), 0.0, Vector2(ear_vis, 1.0)))
		draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 4.5, 7.2, 12), SKIN_BASE)
		draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 4.5, 7.2, 12), SKIN_WASH1)

	# Softly sculpted face with layered gouache cheek/brow washes
	draw_set_transform_matrix(head_xf)
	var chin := Vector2(yaw * 5.0, 4.0 + pitch * 3.5)
	var head_poly := PackedVector2Array([Vector2(-23.0, -32.0)])
	_append_quad(head_poly, Vector2(-23.0, -32.0), Vector2(-23.0, -56.0), Vector2(0.0, -56.0), 7)
	_append_quad(head_poly, Vector2(0.0, -56.0), Vector2(23.0, -56.0), Vector2(23.0, -32.0), 7)
	_append_quad(head_poly, Vector2(23.0, -32.0), Vector2(22.0, -9.0), chin, 7)
	_append_quad(head_poly, chin, Vector2(-22.0, -9.0), Vector2(-23.0, -32.0), 7)
	draw_colored_polygon(head_poly, SKIN_BASE)

	# Overlapping translucent washes for painterly volume
	draw_colored_polygon(_ellipse_pts(Vector2(-12.0 + face_shift_x * 0.4, -22.0), 14.0, 18.0, 14), SKIN_WASH1)
	draw_colored_polygon(_ellipse_pts(Vector2(-13.0 + face_shift_x, -16.0 + face_shift_y), 7.5, 4.5, 12), CHEEK_ROSE)
	draw_colored_polygon(_ellipse_pts(Vector2(13.0 + face_shift_x, -16.0 + face_shift_y), 7.5, 4.5, 12), CHEEK_ROSE)
	draw_polyline(_closed_outline(head_poly), EDGE_WARM, 1.1, true)

	# === PAINTED GOUACHE EYES ===
	var eye_y: float = -25.0 + face_shift_y
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.35, 0.62, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.35, 0.62, 1.0)
	_draw_gouache_eye(head_xf, Vector2(-9.5 * left_fs + face_shift_x, eye_y), left_fs, eyes)
	_draw_gouache_eye(head_xf, Vector2(9.5 * right_fs + face_shift_x, eye_y), right_fs, eyes)

	# Soft nose wash + gentle tip stroke
	draw_set_transform_matrix(head_xf)
	var nx: float = face_shift_x * 1.15
	var ny: float = -21.0 + face_shift_y
	draw_colored_polygon(_ellipse_pts(Vector2(nx - 1.5, ny + 4.5), 3.0, 4.5, 10), SKIN_WASH2)
	draw_polyline(_quad_pts(Vector2(nx - 1.0, ny + 7.5), Vector2(nx + 1.0, ny + 9.2), Vector2(nx + 2.5, ny + 7.5), 4), EDGE_WARM, 1.1, true)

	# === SOFT PAINTED MOUTH ===
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 1.05, -6.8 + face_shift_y * 1.1)))
	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 1.0), 3.8 + mouth.open * 2.0, 4.2 + mouth.open * 3.5, 12), Color(0.55, 0.24, 0.22, 0.9))
		MotionController.MouthShape.OPEN_HAPPY:
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 2.2 * mouth.open), 6.2, 3.5 * mouth.open + 1.4, 14), Color(0.68, 0.30, 0.28, 0.9))
		MotionController.MouthShape.SMILE:
			draw_polyline(_quad_pts(Vector2(-5.5, -0.3), Vector2(0.0, 2.8), Vector2(5.5, -0.3), 6), Color(0.58, 0.28, 0.24, 0.85), 1.5, true)
		_:
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 0.4), 4.8, 1.4, 10), Color(0.76, 0.43, 0.39, 0.75))

	# Tousled painted bangs with warm sunlit brushstroke highlights
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 0.38 + lag.x * 0.06, lag.y * 0.06)))
	var bangs := PackedVector2Array([Vector2(-25.0, -32.0)])
	_append_quad(bangs, Vector2(-25.0, -32.0), Vector2(-26.0, -61.0), Vector2(0.0, -60.0), 7)
	_append_quad(bangs, Vector2(0.0, -60.0), Vector2(26.0, -61.0), Vector2(25.0, -32.0), 7)
	bangs.append_array(PackedVector2Array([
		Vector2(18.0, -40.0), Vector2(6.0, -34.0), Vector2(-4.0, -42.0), Vector2(-17.0, -32.0),
	]))
	draw_colored_polygon(bangs, HAIR_BASE)
	draw_colored_polygon(_ellipse_pts(Vector2(6.0, -49.0), 13.0, 6.0, 14), HAIR_GLOW)
	draw_colored_polygon(_ellipse_pts(Vector2(-12.0, -46.0), 10.0, 9.0, 12), HAIR_WASH)
	draw_polyline(_closed_outline(bangs), EDGE_WARM, 1.1, true)

	# Front painter arm
	_draw_gouache_arm(
		torso_xf,
		Vector2(25.0 + torso.twist * 5.0, -82.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_gouache_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor
) -> void:
	draw_set_transform_matrix(head_xf * _xform(eye_pos))
	var w: float = 6.2 * foreshorten_x
	var h: float = 4.2 * (1.0 + eyes.wide * 0.45) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.92)

	var brow_y: float = -7.2 - eyes.brow_offset * 3.5 + eyes.squint * 1.2
	draw_polyline(_quad_pts(Vector2(-w, brow_y + 0.8), Vector2(0.0, brow_y - 1.4), Vector2(w, brow_y + 0.8), 5), Color(0.38, 0.21, 0.17, 0.85), 2.1, true)

	if eyes.blink > 0.78:
		draw_polyline(_quad_pts(Vector2(-w, 0.5), Vector2(0.0, 2.2), Vector2(w, 0.5), 5), EDGE_WARM, 1.6, true)
		return

	if eyes.squint > 0.45 and eyes.wide < 0.2:
		draw_polyline(_quad_pts(Vector2(-w, 1.5), Vector2(0.0, -3.5), Vector2(w, 1.5), 5), EDGE_WARM, 1.9, true)
		return

	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, w, h, 14), Color(0.98, 0.96, 0.93))
	var gx: float = clampf(eyes.look_x * 2.0 * foreshorten_x, -w * 0.35, w * 0.35)
	var gy: float = clampf(eyes.look_y * 1.2, -h * 0.2, h * 0.25)
	var ir: float = minf(2.9 * (1.0 - eyes.wide * 0.32 if eyes.wide > 0.2 else 1.0), h * 0.85)
	draw_colored_polygon(_ellipse_pts(Vector2(gx, gy), ir * foreshorten_x, ir, 12), Color(0.28, 0.42, 0.35))
	draw_circle(Vector2(gx, gy), ir * 0.45, Color(0.18, 0.14, 0.14))
	draw_circle(Vector2(gx - ir * 0.3, gy - ir * 0.3), maxf(0.7, 0.9), Color(1.0, 0.98, 0.94))
	draw_polyline(_quad_pts(Vector2(-w * 1.05, 0.2), Vector2(0.0, -h * 1.15), Vector2(w * 1.05, 0.2), 6), Color(0.28, 0.17, 0.14, 0.82), 1.8, true)


func _draw_gouache_arm(
	torso_xf: Transform2D,
	shoulder_pos: Vector2,
	shoulder_angle: float,
	elbow_angle: float,
	hand_pose: int,
	wave_phase: float,
	is_front: bool
) -> void:
	var upper_len: float = 47.0
	var fore_len: float = 45.0

	var upper_xf := torso_xf * _xform(shoulder_pos, shoulder_angle)
	draw_set_transform_matrix(upper_xf)
	var u_poly := PackedVector2Array([
		Vector2(-8.5, -5.0), Vector2(8.5, -5.0),
		Vector2(8.0, upper_len), Vector2(-8.0, upper_len),
	])
	draw_colored_polygon(u_poly, SMOCK_BASE)
	if not is_front:
		draw_colored_polygon(u_poly, SMOCK_WASH)
	draw_polyline(_closed_outline(u_poly), EDGE_WARM, 1.1, true)

	var fore_xf := upper_xf * _xform(Vector2(0.0, upper_len - 2.0), elbow_angle)
	draw_set_transform_matrix(fore_xf)
	var f_poly := PackedVector2Array([
		Vector2(-7.8, 0.0), Vector2(7.8, 0.0),
		Vector2(6.5, fore_len - 10.0), Vector2(-6.5, fore_len - 10.0),
	])
	draw_colored_polygon(f_poly, SMOCK_BASE)
	if not is_front:
		draw_colored_polygon(f_poly, SMOCK_WASH)
	draw_polyline(_closed_outline(f_poly), EDGE_WARM, 1.1, true)

	var hand_rot: float = wave_phase * 0.20 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0
	draw_set_transform_matrix(fore_xf * _xform(Vector2(0.0, fore_len - 8.0), hand_rot))
	draw_colored_polygon(_ellipse_pts(Vector2(0.0, 7.0), 5.5 if hand_pose == MotionController.HandPose.RELAXED else 7.0, 7.5, 12), SKIN_BASE if is_front else Color(0.84, 0.68, 0.58))
