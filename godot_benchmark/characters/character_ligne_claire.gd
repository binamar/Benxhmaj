class_name CharacterLigneClaire
extends Node2D

const STYLE_TITLE: String = "European Ligne Claire"
const STYLE_SUBTITLE: String = "Uniform 1.75px Clear Line · Flat Bright Colors · Clean Readability"

# Franco-Belgian Ligne Claire: uniform clean ink weight + bright flat ungraduated fills
const INK := Color(0.110, 0.102, 0.125, 1.0)         # #1C1A20 crisp uniform pen
const LINE_W: float = 1.75

const SKIN := Color(0.980, 0.859, 0.761, 1.0)        # #Fadbc2
const SKIN_SH := Color(0.922, 0.753, 0.643, 1.0)     # minimal clean shadow accent

const HAIR := Color(0.835, 0.451, 0.188, 1.0)        # #D57330 classic adventurer auburn
const JACKET := Color(0.851, 0.737, 0.514, 1.0)      # #D9BC83 khaki safari coat
const JACKET_SH := Color(0.745, 0.624, 0.408, 1.0)
const SHIRT := Color(0.329, 0.620, 0.769, 1.0)       # #549EC4 cerulean shirt
const KERCHIEF := Color(0.859, 0.278, 0.243, 1.0)    # #DB473E bright red kerchief
const TROUSERS := Color(0.247, 0.341, 0.412, 1.0)    # #3F5769 slate trousers
const TROUSERS_SH := Color(0.192, 0.271, 0.333, 1.0)
const BOOTS := Color(0.388, 0.235, 0.165, 1.0)       # #633C2A leather field boots

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 138.0 * s
	var h: float = 356.0 * s
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

	# Crisp clean ground shadow
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	draw_set_transform_matrix(_xform(
		Vector2(body_root.x * 0.7, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.42, 1.0 - air_factor * 0.35)
	))
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 48.0, 10.0, 22), Color(0.06, 0.07, 0.1, 0.34))

	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean,
		Vector2(body_root.scale_x, body_root.scale_y)
	)
	draw_set_transform_matrix(root_xf)

	# === EXPEDITION TROUSERS & LACED BOOTS ===
	var knee_bend: float = clampf((1.0 - body_root.scale_y) * 26.0, -7.0, 15.0)
	for side in [-1, 1]:
		var is_back: bool = side == -1
		var fx: float = float(side) * 14.5
		var kb: float = knee_bend * 0.22 * float(side)

		var leg_poly := PackedVector2Array([
			Vector2(float(side) * 11.0 - 11.0, -142.0),
			Vector2(float(side) * 11.0 + 11.0, -142.0),
			Vector2(fx + 9.5 + kb, -76.0),
			Vector2(fx + 7.0, -34.0),
			Vector2(fx - 7.0, -34.0),
			Vector2(fx - 9.5 + kb, -76.0),
		])
		draw_colored_polygon(leg_poly, TROUSERS_SH if is_back else TROUSERS)
		# Crisp pocket/seam crease lines
		draw_line(Vector2(fx, -134.0), Vector2(fx + kb * 0.4, -40.0), INK, LINE_W * 0.75, true)
		draw_polyline(_closed_outline(leg_poly), INK, LINE_W, true)

		# Laced field boot
		var boot_poly := PackedVector2Array([
			Vector2(fx - 8.0, -38.0),
			Vector2(fx + 8.0, -38.0),
			Vector2(fx + 9.0, -14.0),
			Vector2(fx + 18.0 * float(side) + 4.0, -4.0),
			Vector2(fx + 18.0 * float(side) + 4.0, 0.0),
			Vector2(fx - 9.5, 0.0),
		])
		draw_colored_polygon(boot_poly, BOOTS)
		draw_polyline(_closed_outline(boot_poly), INK, LINE_W, true)
		# Boot cuff + lace bars
		draw_line(Vector2(fx - 7.5, -32.0), Vector2(fx + 7.5, -32.0), INK, LINE_W, true)
		draw_line(Vector2(fx - 4.0, -24.0), Vector2(fx + 4.0, -24.0), INK, LINE_W, true)
		draw_line(Vector2(fx - 4.0, -18.0), Vector2(fx + 4.0, -18.0), INK, LINE_W, true)

	# === TORSO ANCHOR (Safari Utility Jacket) ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -140.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x * (1.0 - absf(torso.twist) * 0.06), torso.breath_scale_y)
	)

	# Back arm
	_draw_claire_arm(
		torso_xf,
		Vector2(-27.0 + torso.twist * 5.0, -90.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		false
	)

	draw_set_transform_matrix(torso_xf)
	var torso_h: float = 98.0
	var jacket_poly := PackedVector2Array([
		Vector2(-28.0, -torso_h + 6.0),
		Vector2(0.0, -torso_h),
		Vector2(28.0, -torso_h + 6.0),
		Vector2(24.0, 12.0),
		Vector2(-24.0, 12.0),
	])
	draw_colored_polygon(jacket_poly, JACKET)
	draw_polyline(_closed_outline(jacket_poly), INK, LINE_W, true)

	# Cerulean collar V-opening
	var shirt_v := PackedVector2Array([
		Vector2(-11.0 + torso.twist * 6.0, -torso_h + 2.0),
		Vector2(11.0 + torso.twist * 6.0, -torso_h + 2.0),
		Vector2(torso.twist * 7.0, -68.0),
	])
	draw_colored_polygon(shirt_v, SHIRT)
	draw_polyline(_closed_outline(shirt_v), INK, LINE_W, true)

	# Center button placket + 4 utility pockets (classic Ligne Claire precision!)
	var cx: float = torso.twist * 7.0
	draw_line(Vector2(cx, -68.0), Vector2(cx, 12.0), INK, LINE_W, true)
	for by in [-58.0, -40.0, -16.0, 0.0]:
		draw_circle(Vector2(cx + 3.0, by), 2.0, INK)

	# Chest pockets & lower cargo pockets
	for ps in [-1, 1]:
		var px_p: float = float(ps) * 14.0 + cx * 0.5
		draw_rect(Rect2(px_p - 6.0, -68.0, 12.0, 15.0), JACKET_SH, true)
		draw_rect(Rect2(px_p - 6.0, -68.0, 12.0, 15.0), INK, false, LINE_W)
		draw_line(Vector2(px_p - 6.0, -62.0), Vector2(px_p + 6.0, -62.0), INK, LINE_W, true)

		draw_rect(Rect2(px_p - 7.0, -20.0, 14.0, 19.0), JACKET_SH, true)
		draw_rect(Rect2(px_p - 7.0, -20.0, 14.0, 19.0), INK, false, LINE_W)
		draw_line(Vector2(px_p - 7.0, -13.0), Vector2(px_p + 7.0, -13.0), INK, LINE_W, true)

	# Leather belt & brass buckle
	draw_rect(Rect2(-24.0, -32.0, 48.0, 7.0), BOOTS, true)
	draw_rect(Rect2(-24.0, -32.0, 48.0, 7.0), INK, false, LINE_W)
	draw_rect(Rect2(cx - 5.0, -33.0, 10.0, 9.0), Color(0.92, 0.78, 0.32), true)
	draw_rect(Rect2(cx - 5.0, -33.0, 10.0, 9.0), INK, false, LINE_W)

	# Neck
	draw_rect(Rect2(-7.0, -torso_h - 14.0, 14.0, 16.0), SKIN, true)
	draw_rect(Rect2(-7.0, -torso_h - 14.0, 14.0, 16.0), INK, false, LINE_W)

	# Fluttering red explorer kerchief (secondary_lag!)
	var kerchief_xf := torso_xf * _xform(Vector2(-8.0 + cx * 0.5, -torso_h + 2.0), lag.rot * 0.85)
	draw_set_transform_matrix(kerchief_xf)
	var k_tip := Vector2(-28.0 + lag.x * 1.05 + lag.flutter, 34.0 + lag.y * 0.75)
	var kerchief_poly := PackedVector2Array([
		Vector2(2.0, -2.0),
		Vector2(18.0, 4.0),
		Vector2(6.0, 12.0),
		k_tip,
		Vector2(-10.0 + lag.x * 0.45, 22.0 + lag.y * 0.35),
	])
	draw_colored_polygon(kerchief_poly, KERCHIEF)
	draw_polyline(_closed_outline(kerchief_poly), INK, LINE_W, true)

	# === HEAD PIVOT ANCHOR ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -torso_h - 14.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 11.0
	var face_shift_y: float = pitch * 6.0

	# Clean Franco-Belgian ears with inner C-line
	for ear_side in [-1, 1]:
		var ear_vis: float = clampf(1.0 - float(ear_side) * yaw * 0.85, 0.15, 1.15)
		draw_set_transform_matrix(head_xf * _xform(Vector2(float(ear_side) * 24.5 - yaw * 5.0, -24.0 + face_shift_y * 0.35), 0.0, Vector2(ear_vis, 1.0)))
		var ear_pts := _ellipse_pts(Vector2.ZERO, 4.8, 7.8, 12)
		draw_colored_polygon(ear_pts, SKIN)
		draw_polyline(_closed_outline(ear_pts), INK, LINE_W, true)
		draw_arc(Vector2(0.0, 0.5), 2.4, -1.0, 1.5, 6, INK, LINE_W * 0.8, true)

	# Rounded clear-line head
	draw_set_transform_matrix(head_xf)
	var chin := Vector2(yaw * 5.0, 4.0 + pitch * 3.5)
	var head_poly := PackedVector2Array([Vector2(-24.0, -34.0)])
	_append_quad(head_poly, Vector2(-24.0, -34.0), Vector2(-24.0, -58.0), Vector2(0.0, -58.0), 7)
	_append_quad(head_poly, Vector2(0.0, -58.0), Vector2(24.0, -58.0), Vector2(24.0, -34.0), 7)
	_append_quad(head_poly, Vector2(24.0, -34.0), Vector2(23.0, -9.0), chin, 7)
	_append_quad(head_poly, chin, Vector2(-23.0, -9.0), Vector2(-24.0, -34.0), 7)
	draw_colored_polygon(head_poly, SKIN)
	draw_polyline(_closed_outline(head_poly), INK, LINE_W, true)

	# === CLEAN DOT/OVAL LIGNE CLAIRE EYES ===
	var eye_y: float = -26.0 + face_shift_y
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.35, 0.62, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.35, 0.62, 1.0)
	_draw_claire_eye(head_xf, Vector2(-9.5 * left_fs + face_shift_x, eye_y), left_fs, eyes)
	_draw_claire_eye(head_xf, Vector2(9.5 * right_fs + face_shift_x, eye_y), right_fs, eyes)

	# Classic clean hook nose line
	draw_set_transform_matrix(head_xf)
	var nx: float = face_shift_x * 1.15
	var ny: float = -24.0 + face_shift_y
	draw_polyline(_quad_pts(Vector2(nx, ny), Vector2(nx + 6.0 * (1.0 if yaw >= 0.0 else -0.4), ny + 6.0), Vector2(nx + 0.5, ny + 9.5), 6), INK, LINE_W, true)

	# Clean Ligne Claire Mouth
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 1.05, -6.5 + face_shift_y * 1.1)))
	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			var m_pts := _ellipse_pts(Vector2(0.0, 1.0), 4.0 + mouth.open * 2.5, 4.5 + mouth.open * 4.0, 14)
			draw_colored_polygon(m_pts, Color(0.55, 0.16, 0.16))
			draw_polyline(_closed_outline(m_pts), INK, LINE_W, true)
		MotionController.MouthShape.OPEN_HAPPY:
			var d_pts := PackedVector2Array([Vector2(-6.5, -0.5), Vector2(6.5, -0.5), Vector2(4.5, 6.5 * mouth.open + 2.0), Vector2(-4.5, 6.5 * mouth.open + 2.0)])
			draw_colored_polygon(d_pts, Color(0.75, 0.22, 0.25))
			draw_polyline(_closed_outline(d_pts), INK, LINE_W, true)
		MotionController.MouthShape.SMILE:
			draw_polyline(_quad_pts(Vector2(-6.0, -0.5), Vector2(0.0, 3.5), Vector2(6.0, -0.5), 6), INK, LINE_W, true)
		_:
			draw_line(Vector2(-4.5, 0.5), Vector2(4.5, 0.5), INK, LINE_W, true)

	# Adventurer Quiff Hair + Cowlick (secondary_lag)
	draw_set_transform_matrix(head_xf * _xform(Vector2(face_shift_x * 0.35, 0.0)))
	var hair_poly := PackedVector2Array([Vector2(-24.0, -35.0)])
	_append_quad(hair_poly, Vector2(-24.0, -35.0), Vector2(-25.0, -64.0), Vector2(-2.0, -62.0), 7)
	# Iconic Ligne Claire swept quiff wave!
	_append_quad(hair_poly, Vector2(-2.0, -62.0), Vector2(14.0 + lag.x * 0.18, -76.0 + lag.y * 0.12), Vector2(24.0, -52.0), 8)
	_append_quad(hair_poly, Vector2(24.0, -52.0), Vector2(27.0, -40.0), Vector2(23.0, -34.0), 5)
	hair_poly.append_array(PackedVector2Array([
		Vector2(17.0, -44.0),
		Vector2(4.0, -42.0),
		Vector2(-15.0, -44.0),
	]))
	draw_colored_polygon(hair_poly, HAIR)
	draw_polyline(_closed_outline(hair_poly), INK, LINE_W, true)

	# Front arm
	_draw_claire_arm(
		torso_xf,
		Vector2(27.0 + torso.twist * 5.0, -90.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_claire_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor
) -> void:
	draw_set_transform_matrix(head_xf * _xform(eye_pos))
	var w: float = 5.2 * foreshorten_x
	var h: float = 4.6 * (1.0 + eyes.wide * 0.48) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.92)

	var brow_y: float = -7.5 - eyes.brow_offset * 4.0 + eyes.squint * 1.5
	draw_polyline(_quad_pts(Vector2(-w * 0.9, brow_y + 1.0), Vector2(0.0, brow_y - 1.5), Vector2(w * 0.9, brow_y + 1.0), 5), INK, LINE_W, true)

	if eyes.blink > 0.78:
		draw_polyline(_quad_pts(Vector2(-w * 0.9, 0.5), Vector2(0.0, 2.5), Vector2(w * 0.9, 0.5), 5), INK, LINE_W, true)
		return

	if eyes.squint > 0.45 and eyes.wide < 0.2:
		draw_polyline(_quad_pts(Vector2(-w * 0.9, 1.5), Vector2(0.0, -4.0), Vector2(w * 0.9, 1.5), 6), INK, LINE_W, true)
		return

	var scl := _ellipse_pts(Vector2.ZERO, w, h, 14)
	draw_colored_polygon(scl, Color.WHITE)
	draw_polyline(_closed_outline(scl), INK, LINE_W, true)

	var gx: float = clampf(eyes.look_x * 2.0 * foreshorten_x, -w * 0.4, w * 0.4)
	var gy: float = clampf(eyes.look_y * 1.4, -h * 0.25, h * 0.25)
	var pr: float = minf(2.2 * (1.0 - eyes.wide * 0.35 if eyes.wide > 0.2 else 1.0), h * 0.65)
	draw_circle(Vector2(gx, gy), pr, INK)


func _draw_claire_arm(
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
		Vector2(-8.0, -5.0), Vector2(8.0, -5.0),
		Vector2(7.0, upper_len), Vector2(-7.0, upper_len),
	])
	draw_colored_polygon(u_poly, JACKET if is_front else JACKET_SH)
	draw_polyline(_closed_outline(u_poly), INK, LINE_W, true)

	var fore_xf := upper_xf * _xform(Vector2(0.0, upper_len - 2.0), elbow_angle)
	draw_set_transform_matrix(fore_xf)
	# Rolled safari cuff + bare forearm
	var cuff := Rect2(-7.5, 0.0, 15.0, 11.0)
	draw_rect(cuff, JACKET_SH, true)
	draw_rect(cuff, INK, false, LINE_W)

	var f_poly := PackedVector2Array([
		Vector2(-6.2, 11.0), Vector2(6.2, 11.0),
		Vector2(4.8, fore_len - 4.0), Vector2(-4.8, fore_len - 4.0),
	])
	draw_colored_polygon(f_poly, SKIN if is_front else SKIN_SH)
	draw_polyline(_closed_outline(f_poly), INK, LINE_W, true)

	var hand_rot: float = wave_phase * 0.20 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0
	draw_set_transform_matrix(fore_xf * _xform(Vector2(0.0, fore_len - 2.0), hand_rot))
	var h_col: Color = SKIN if is_front else SKIN_SH
	var h_poly := PackedVector2Array([
		Vector2(-4.5, -2.0), Vector2(-6.5, 8.0), Vector2(-2.0, 14.0),
		Vector2(3.5, 13.0), Vector2(6.0, 6.0), Vector2(4.5, -2.0),
	])
	draw_colored_polygon(h_poly, h_col)
	draw_polyline(_closed_outline(h_poly), INK, LINE_W, true)
