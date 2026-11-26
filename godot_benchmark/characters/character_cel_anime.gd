class_name CharacterCelAnime
extends Node2D

const STYLE_TITLE: String = "Cel-Shaded Anime"
const STYLE_SUBTITLE: String = "2-Step Hard Shadows · Variable Ink · Rim Highlights"

# Crisp 2D Hard Cel-Shaded Anime palette
const INK := Color(0.086, 0.067, 0.157, 1.0)         # #161128
const SKIN_LIT := Color(1.0, 0.894, 0.816, 1.0)      # #FFE4D0
const SKIN_SH1 := Color(0.949, 0.722, 0.608, 1.0)    # #F2B89B
const SKIN_SH2 := Color(0.831, 0.541, 0.451, 1.0)    # #D48A73
const SKIN_RIM := Color(1.0, 0.973, 0.941, 1.0)      # #FFF8F0

const HAIR_LIT := Color(0.180, 0.227, 0.408, 1.0)    # #2E3A68
const HAIR_SH1 := Color(0.122, 0.149, 0.290, 1.0)    # #1F264A
const HAIR_SH2 := Color(0.075, 0.086, 0.180, 1.0)    # #13162E
const HAIR_SHINE := Color(0.376, 0.647, 0.980, 1.0)  # #60A5FA
const HAIR_RIM := Color(0.490, 0.827, 0.988, 1.0)    # #7DD3FC

const JACKET_LIT := Color(0.957, 0.247, 0.369, 1.0)  # #F43F5E
const JACKET_SH1 := Color(0.745, 0.071, 0.235, 1.0)  # #BE123C
const JACKET_SH2 := Color(0.533, 0.075, 0.216, 1.0)  # #881337
const JACKET_RIM := Color(1.0, 0.894, 0.902, 1.0)    # #FFE4E6

const INNER_LIT := Color(0.973, 0.980, 0.988, 1.0)   # #F8FAFC
const INNER_SH1 := Color(0.796, 0.835, 0.882, 1.0)   # #CBD5E1

const SCARF_LIT := Color(0.984, 0.749, 0.141, 1.0)   # #FBBF24
const SCARF_SH1 := Color(0.851, 0.467, 0.024, 1.0)   # #D97706
const SCARF_SH2 := Color(0.573, 0.251, 0.055, 1.0)   # #92400E
const SCARF_RIM := Color(0.996, 0.953, 0.780, 1.0)   # #FEF3C7

const PANTS_LIT := Color(0.118, 0.161, 0.231, 1.0)   # #1E293B
const PANTS_SH1 := Color(0.059, 0.090, 0.165, 1.0)   # #0F172A

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 136.0 * s
	var h: float = 360.0 * s
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

	# Ground shadow (shrinks during jump)
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	var sh_xf := _xform(
		Vector2(body_root.x * 0.7, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.42, 1.0 - air_factor * 0.35)
	)
	draw_set_transform_matrix(sh_xf)
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 52.0, 11.0, 24), Color(0.039, 0.047, 0.086, 0.42))

	# Body root transform
	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean,
		Vector2(body_root.scale_x, body_root.scale_y)
	)
	draw_set_transform_matrix(root_xf)

	# === LEGS & ANIME SNEAKERS ===
	var leg_spread: float = 16.0
	var knee_bend: float = clampf((1.0 - body_root.scale_y) * 28.0, -8.0, 16.0)

	for side in [-1, 1]:
		var is_back: bool = side == -1
		var hip_x: float = float(side) * 12.0
		var hip_y: float = -126.0
		var foot_x: float = float(side) * leg_spread
		var kb: float = knee_bend * 0.25 * float(side)

		var leg_poly := PackedVector2Array([
			Vector2(hip_x - 11.0, hip_y),
			Vector2(hip_x + 11.0, hip_y),
			Vector2(foot_x + 8.0 + kb, -64.0),
			Vector2(foot_x + 6.5, -18.0),
			Vector2(foot_x - 6.5, -18.0),
			Vector2(foot_x - 8.0 + kb, -64.0),
		])
		draw_colored_polygon(leg_poly, PANTS_SH1 if is_back else PANTS_LIT)

		if not is_back:
			var leg_sh := PackedVector2Array([
				Vector2(hip_x - 11.0, hip_y),
				Vector2(hip_x - 2.0, hip_y),
				Vector2(foot_x - 1.0, -18.0),
				Vector2(foot_x - 6.5, -18.0),
			])
			draw_colored_polygon(leg_sh, PANTS_SH1)

		draw_line(
			Vector2(hip_x + 8.0 * float(side), hip_y + 4.0),
			Vector2(foot_x + 5.5 * float(side), -20.0),
			JACKET_SH1 if is_back else JACKET_LIT,
			3.0,
			true
		)
		draw_polyline(_closed_outline(leg_poly), INK, 2.6, true)

		# Sculpted anime high-top sneaker
		var shoe_poly := PackedVector2Array([
			Vector2(foot_x - 9.0, -20.0),
			Vector2(foot_x + 9.0, -20.0),
			Vector2(foot_x + 15.0 * float(side) + 6.0, -5.0),
			Vector2(foot_x + 15.0 * float(side) + 6.0, 0.0),
			Vector2(foot_x - 11.0, 0.0),
		])
		draw_colored_polygon(shoe_poly, Color(0.796, 0.835, 0.882) if is_back else Color.WHITE)
		draw_rect(Rect2(foot_x - 9.0, -11.0, 18.0, 5.0), JACKET_SH1 if is_back else JACKET_LIT, true)
		draw_polyline(_closed_outline(shoe_poly), INK, 2.5, true)

	# === TORSO ANCHOR ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -124.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x * (1.0 - absf(torso.twist) * 0.06), torso.breath_scale_y)
	)

	# Back scarf tail (secondary_lag behind torso)
	var back_scarf_xf := torso_xf * _xform(Vector2(-8.0 + torso.twist * 6.0, -86.0), lag.rot * 0.85 - 0.12)
	draw_set_transform_matrix(back_scarf_xf)
	var b_tip := Vector2(-38.0 + lag.x * 1.15 + lag.flutter, 78.0 + lag.y * 0.9)
	var b_tip2 := Vector2(-20.0 + lag.x * 1.05 + lag.flutter, 86.0 + lag.y * 0.9)
	var back_scarf_poly := PackedVector2Array([Vector2.ZERO])
	_append_quad(back_scarf_poly, Vector2.ZERO, Vector2(-24.0 + lag.x * 0.75, 38.0 + lag.y * 0.45), b_tip, 8)
	back_scarf_poly.append(b_tip2)
	_append_quad(back_scarf_poly, b_tip2, Vector2(-8.0 + lag.x * 0.6, 40.0 + lag.y * 0.4), Vector2(12.0, 4.0), 8)
	draw_colored_polygon(back_scarf_poly, SCARF_SH1)
	draw_polyline(_closed_outline(back_scarf_poly), INK, 2.4, true)

	# Back arm
	_draw_cel_arm(
		torso_xf,
		Vector2(-24.0 + torso.twist * 5.0, -82.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		false
	)

	# Cropped jacket & inner tee
	draw_set_transform_matrix(torso_xf)
	var shoulder_w: float = 28.0
	var waist_w: float = 19.0
	var torso_h: float = 92.0

	var tee_poly := PackedVector2Array([
		Vector2(-waist_w + 2.0, -24.0),
		Vector2(waist_w - 2.0, -24.0),
		Vector2(waist_w + 3.0, 4.0),
		Vector2(-waist_w - 3.0, 4.0),
	])
	draw_colored_polygon(tee_poly, INNER_LIT)
	draw_rect(Rect2(-waist_w - 2.0, -24.0, 14.0, 28.0), INNER_SH1, true)
	draw_polyline(_closed_outline(tee_poly), INK, 2.5, true)

	var jacket_poly := PackedVector2Array([Vector2(-shoulder_w, -torso_h + 6.0)])
	_append_quad(jacket_poly, Vector2(-shoulder_w, -torso_h + 6.0), Vector2(0.0, -torso_h - 4.0), Vector2(shoulder_w, -torso_h + 6.0), 8)
	jacket_poly.append(Vector2(waist_w + 4.0, -18.0))
	jacket_poly.append(Vector2(-waist_w - 4.0, -18.0))
	draw_colored_polygon(jacket_poly, JACKET_LIT)

	# Hard Step-1 shadow band
	var j_sh1 := PackedVector2Array([
		Vector2(-shoulder_w, -torso_h + 6.0),
		Vector2(-4.0 + torso.twist * 8.0, -torso_h + 8.0),
		Vector2(-6.0 + torso.twist * 8.0, -18.0),
		Vector2(-waist_w - 4.0, -18.0),
	])
	draw_colored_polygon(j_sh1, JACKET_SH1)

	# Hard Step-2 deep occlusion shadow band
	var j_sh2 := PackedVector2Array([
		Vector2(-shoulder_w, -torso_h + 6.0),
		Vector2(-16.0 + torso.twist * 5.0, -torso_h + 10.0),
		Vector2(-15.0 + torso.twist * 5.0, -18.0),
		Vector2(-waist_w - 4.0, -18.0),
	])
	draw_colored_polygon(j_sh2, JACKET_SH2)

	# Inner white zipper placket
	var placket_poly := PackedVector2Array([
		Vector2(-6.0 + torso.twist * 10.0, -torso_h + 6.0),
		Vector2(6.0 + torso.twist * 10.0, -torso_h + 6.0),
		Vector2(2.0 + torso.twist * 10.0, -18.0),
		Vector2(-2.0 + torso.twist * 10.0, -18.0),
	])
	draw_colored_polygon(placket_poly, INNER_LIT)

	# Bright right-edge rim highlight
	draw_line(Vector2(shoulder_w - 2.0, -torso_h + 8.0), Vector2(waist_w + 2.0, -20.0), JACKET_RIM, 2.6, true)
	draw_polyline(_closed_outline(jacket_poly), INK, 2.8, true)

	# Neck + cast chin shadow
	var neck_rect := Rect2(-7.5, -torso_h - 14.0, 15.0, 18.0)
	draw_rect(neck_rect, SKIN_LIT, true)
	var neck_sh := PackedVector2Array([
		Vector2(-7.5, -torso_h - 14.0),
		Vector2(7.5, -torso_h - 14.0),
		Vector2(7.5, -torso_h - 2.0),
		Vector2(-7.5, -torso_h - 6.0),
	])
	draw_colored_polygon(neck_sh, SKIN_SH1)
	draw_rect(neck_rect, INK, false, 2.3)

	# Neck scarf collar wrap
	var collar_pts := _ellipse_pts(Vector2(torso.twist * 4.0, -torso_h + 2.0), 21.0, 9.0, 22)
	draw_colored_polygon(collar_pts, SCARF_LIT)
	var collar_sh := _ellipse_pts(Vector2(torso.twist * 4.0, -torso_h + 5.0), 17.5, 5.2, 18)
	draw_colored_polygon(collar_sh, SCARF_SH1)
	draw_polyline(_closed_outline(collar_pts), INK, 2.5, true)

	# Front scarf ribbon tail (secondary_lag)
	var front_scarf_xf := torso_xf * _xform(Vector2(10.0 + torso.twist * 6.0, -torso_h + 6.0), lag.rot * 0.7 + 0.08)
	draw_set_transform_matrix(front_scarf_xf)
	var f_tip1 := Vector2(18.0 + lag.x * 0.95 + lag.flutter * 0.8, 56.0 + lag.y * 0.65)
	var f_tip2 := Vector2(2.0 + lag.x * 0.88 + lag.flutter * 0.8, 62.0 + lag.y * 0.65)
	var front_scarf_poly := PackedVector2Array([Vector2(-5.0, 0.0)])
	_append_quad(front_scarf_poly, Vector2(-5.0, 0.0), Vector2(12.0 + lag.x * 0.55, 24.0 + lag.y * 0.35), f_tip1, 8)
	front_scarf_poly.append(f_tip2)
	_append_quad(front_scarf_poly, f_tip2, Vector2(lag.x * 0.4, 26.0 + lag.y * 0.3), Vector2(-9.0, 2.0), 8)
	draw_colored_polygon(front_scarf_poly, SCARF_LIT)

	# Step-2 hard shadow along left strip of front scarf
	var f_sh := PackedVector2Array([Vector2(-9.0, 2.0)])
	_append_quad(f_sh, Vector2(-9.0, 2.0), Vector2(lag.x * 0.4, 26.0 + lag.y * 0.3), f_tip2, 6)
	f_sh.append(f_tip2.lerp(f_tip1, 0.38))
	f_sh.append(Vector2(-3.0, 2.0))
	draw_colored_polygon(f_sh, SCARF_SH2)

	# Scarf rim highlight
	var rim_pts := _quad_pts(
		Vector2(2.0, 2.0),
		Vector2(13.0 + lag.x * 0.55, 24.0 + lag.y * 0.35),
		Vector2(17.0 + lag.x * 0.95 + lag.flutter * 0.8, 54.0 + lag.y * 0.65),
		7
	)
	draw_polyline(rim_pts, SCARF_RIM, 1.8, true)
	draw_polyline(_closed_outline(front_scarf_poly), INK, 2.4, true)

	# === HEAD PIVOT ANCHOR ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -torso_h - 14.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 12.0
	var face_shift_y: float = pitch * 7.0

	# Back spiky anime hair with secondary_lag
	var back_hair_xf := head_xf * _xform(Vector2(lag.x * 0.16, lag.y * 0.14), lag.rot * 0.25)
	draw_set_transform_matrix(back_hair_xf)
	var back_hair_poly := PackedVector2Array([
		Vector2(-36.0, -38.0),
		Vector2(-47.0, -14.0),
		Vector2(-37.0, -10.0),
		Vector2(-45.0, 8.0),
		Vector2(-24.0, 4.0),
		Vector2(24.0, 4.0),
		Vector2(44.0, 10.0),
		Vector2(38.0, -8.0),
		Vector2(48.0, -16.0),
		Vector2(35.0, -40.0),
	])
	_append_quad(back_hair_poly, Vector2(35.0, -40.0), Vector2(0.0, -76.0), Vector2(-36.0, -38.0), 10)
	draw_colored_polygon(back_hair_poly, HAIR_SH2)
	draw_polyline(_closed_outline(back_hair_poly), INK, 2.6, true)

	# Ears (2.5D yaw visibility)
	for ear_side in [-1, 1]:
		var ear_vis: float = clampf(1.0 - float(ear_side) * yaw * 0.85, 0.15, 1.15)
		var ear_xf := head_xf * _xform(
			Vector2(float(ear_side) * 31.0 - yaw * 6.0, -28.0 + face_shift_y * 0.4),
			float(ear_side) * 0.15,
			Vector2(ear_vis, 1.0)
		)
		draw_set_transform_matrix(ear_xf)
		var ear_pts := _ellipse_pts(Vector2.ZERO, 5.5, 9.0, 14)
		draw_colored_polygon(ear_pts, SKIN_SH1 if ear_side == -1 else SKIN_LIT)
		draw_polyline(_closed_outline(ear_pts), INK, 2.2, true)

	# Head contour (pointed anime chin shifting with 2.5D yaw & pitch)
	draw_set_transform_matrix(head_xf)
	var chin := Vector2(yaw * 6.0, 4.0 + pitch * 4.0)
	var head_poly := PackedVector2Array([Vector2(-31.0, -34.0)])
	_append_quad(head_poly, Vector2(-31.0, -34.0), Vector2(-32.0, -68.0), Vector2(0.0, -68.0), 7)
	_append_quad(head_poly, Vector2(0.0, -68.0), Vector2(32.0, -68.0), Vector2(31.0, -34.0), 7)
	_append_quad(head_poly, Vector2(31.0, -34.0), Vector2(30.0, -11.0), chin, 7)
	_append_quad(head_poly, chin, Vector2(-30.0, -11.0), Vector2(-31.0, -34.0), 7)
	draw_colored_polygon(head_poly, SKIN_LIT)

	# Hard step-1 cheek/jaw shadow inside head silhouette
	var head_sh1 := PackedVector2Array([Vector2(-31.0, -34.0)])
	_append_quad(head_sh1, Vector2(-31.0, -34.0), Vector2(-32.0, -68.0), Vector2(-10.0 + face_shift_x * 0.5, -67.0), 6)
	_append_quad(head_sh1, Vector2(-10.0 + face_shift_x * 0.5, -67.0), Vector2(-18.0 + face_shift_x * 0.4, -20.0), chin, 7)
	_append_quad(head_sh1, chin, Vector2(-30.0, -11.0), Vector2(-31.0, -34.0), 7)
	draw_colored_polygon(head_sh1, SKIN_SH1)

	# Warm rim highlight along right jawline
	var jaw_rim := _quad_pts(Vector2(27.0, -28.0), Vector2(25.0, -12.0), chin + Vector2(6.0, -2.0), 6)
	draw_polyline(jaw_rim, SKIN_RIM, 2.6, true)
	draw_polyline(_closed_outline(head_poly), INK, 2.8, true)

	# === EYES ANCHOR (2.5D foreshortening) ===
	var eye_y: float = -28.0 + face_shift_y
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.35, 0.62, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.35, 0.62, 1.0)
	_draw_anime_eye(head_xf, Vector2(-13.5 * left_fs + face_shift_x, eye_y), -1, left_fs, eyes)
	_draw_anime_eye(head_xf, Vector2(13.5 * right_fs + face_shift_x, eye_y), 1, right_fs, eyes)

	# Minimalist anime nose wedge
	draw_set_transform_matrix(head_xf)
	var nx: float = face_shift_x * 1.15
	var ny: float = -17.0 + face_shift_y * 1.1
	draw_colored_polygon(PackedVector2Array([
		Vector2(nx - 1.0, ny),
		Vector2(nx + 2.5, ny + 3.0),
		Vector2(nx - 0.5, ny + 3.5),
	]), SKIN_SH2)

	# === MOUTH ANCHOR ===
	var mouth_xf := head_xf * _xform(Vector2(face_shift_x * 1.05, -6.5 + face_shift_y * 1.15))
	draw_set_transform_matrix(mouth_xf)
	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			var ry: float = 4.0 + mouth.open * 4.5
			var rx: float = 3.5 + mouth.open * 2.5
			var m_pts := _ellipse_pts(Vector2(0.0, 1.0), rx, ry, 16)
			draw_colored_polygon(m_pts, Color(0.498, 0.114, 0.114))
			draw_polyline(_closed_outline(m_pts), INK, 2.1, true)
		MotionController.MouthShape.OPEN_HAPPY:
			var d_pts := PackedVector2Array([Vector2(-7.0, -1.0)])
			_append_quad(d_pts, Vector2(-7.0, -1.0), Vector2(0.0, 0.0), Vector2(7.0, -1.0), 5)
			var h_open: float = 9.0 * mouth.open + 2.0
			_append_quad(d_pts, Vector2(7.0, -1.0), Vector2(6.0, h_open), Vector2(0.0, h_open), 5)
			_append_quad(d_pts, Vector2(0.0, h_open), Vector2(-6.0, h_open), Vector2(-7.0, -1.0), 5)
			draw_colored_polygon(d_pts, Color(0.624, 0.071, 0.224))
			draw_colored_polygon(_ellipse_pts(Vector2(0.0, 5.5 * mouth.open + 0.5), 4.2, 2.2, 12), Color(0.984, 0.443, 0.522))
			draw_polyline(_closed_outline(d_pts), INK, 2.0, true)
		MotionController.MouthShape.SMILE:
			draw_polyline(_quad_pts(Vector2(-6.0, -1.0), Vector2(0.0, 4.5), Vector2(6.5, -1.0), 8), INK, 2.1, true)
		_:
			draw_polyline(_quad_pts(Vector2(-4.5, 0.0), Vector2(0.0, 1.4), Vector2(5.0, -0.4), 6), INK, 2.0, true)

	# Front swept anime bangs + ahoge (2.5D shift + secondary_lag)
	var bangs_xf := head_xf * _xform(Vector2(face_shift_x * 0.45 + lag.x * 0.08, lag.y * 0.08))
	draw_set_transform_matrix(bangs_xf)
	var bangs_poly := PackedVector2Array([Vector2(-34.0, -36.0)])
	_append_quad(bangs_poly, Vector2(-34.0, -36.0), Vector2(-32.0, -74.0), Vector2(2.0, -74.0), 8)
	_append_quad(bangs_poly, Vector2(2.0, -74.0), Vector2(35.0, -74.0), Vector2(34.0, -35.0), 8)
	bangs_poly.append_array(PackedVector2Array([
		Vector2(28.0, -16.0),
		Vector2(22.0, -32.0),
		Vector2(13.0, -19.0),
		Vector2(6.0, -37.0),
		Vector2(-2.0, -17.0),
		Vector2(-10.0, -36.0),
		Vector2(-21.0, -15.0),
		Vector2(-26.0, -31.0),
	]))
	draw_colored_polygon(bangs_poly, HAIR_LIT)

	# Step-1 hard shadow band on left side of bangs
	var bangs_sh1 := PackedVector2Array([Vector2(-34.0, -36.0)])
	_append_quad(bangs_sh1, Vector2(-34.0, -36.0), Vector2(-32.0, -74.0), Vector2(-4.0, -74.0), 7)
	bangs_sh1.append_array(PackedVector2Array([
		Vector2(-8.0, -36.0),
		Vector2(-21.0, -15.0),
		Vector2(-26.0, -31.0),
	]))
	draw_colored_polygon(bangs_sh1, HAIR_SH1)

	# Classic angular anime hair shine ribbon
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14.0, -52.0),
		Vector2(-3.0, -55.0),
		Vector2(3.0, -50.0),
		Vector2(14.0, -54.0),
		Vector2(22.0, -48.0),
		Vector2(13.0, -44.0),
		Vector2(3.0, -47.0),
		Vector2(-4.0, -43.0),
		Vector2(-15.0, -48.0),
	]), HAIR_SHINE)

	# Bright crown rim highlight
	draw_polyline(_quad_pts(Vector2(4.0, -71.0), Vector2(30.0, -69.0), Vector2(32.0, -40.0), 8), HAIR_RIM, 2.5, true)
	draw_polyline(_closed_outline(bangs_poly), INK, 2.6, true)

	# Ahoge sprout reacting to secondary_lag
	var ahoge_xf := bangs_xf * _xform(Vector2(2.0, -72.0), lag.rot * 0.9)
	draw_set_transform_matrix(ahoge_xf)
	var ahoge_tip := Vector2(22.0 + lag.x * 0.4, -10.0)
	var ahoge_poly := PackedVector2Array([Vector2(-2.0, 0.0)])
	_append_quad(ahoge_poly, Vector2(-2.0, 0.0), Vector2(8.0 + lag.x * 0.25, -18.0 + lag.y * 0.15), ahoge_tip, 7)
	_append_quad(ahoge_poly, ahoge_tip, Vector2(8.0, -8.0), Vector2(3.0, 1.0), 6)
	draw_colored_polygon(ahoge_poly, HAIR_LIT)
	draw_polyline(_closed_outline(ahoge_poly), INK, 2.2, true)

	# Front arm (drawn over torso)
	_draw_cel_arm(
		torso_xf,
		Vector2(25.0 + torso.twist * 5.0, -82.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_anime_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	side: int,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor
) -> void:
	var eye_xf := head_xf * _xform(eye_pos)
	draw_set_transform_matrix(eye_xf)

	var w: float = 13.5 * foreshorten_x
	var base_h: float = 16.5
	var h: float = base_h * (1.0 + eyes.wide * 0.24) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.94)

	# Tapered anime eyebrow
	var brow_y: float = -15.0 - eyes.brow_offset * 5.5 + eyes.squint * 2.0
	var brow_pts := _quad_pts(
		Vector2(-w * 0.72, brow_y + (1.5 if side == -1 else 0.0)),
		Vector2(0.0, brow_y - 3.2 - eyes.wide * 2.0),
		Vector2(w * 0.75, brow_y + (1.5 if side == 1 else 0.0)),
		7
	)
	draw_polyline(brow_pts, INK, 2.3, true)

	if eyes.blink > 0.78:
		draw_polyline(_quad_pts(Vector2(-w * 0.85, 2.0), Vector2(0.0, 6.5), Vector2(w * 0.85, 1.5), 7), INK, 3.0, true)
		return

	if eyes.squint > 0.45 and eyes.wide < 0.2:
		draw_polyline(_quad_pts(Vector2(-w * 0.85, 3.0), Vector2(0.0, -9.0), Vector2(w * 0.85, 3.0), 8), INK, 3.4, true)
		var blush_col := Color(0.984, 0.443, 0.522)
		draw_line(Vector2(-w * 0.5, 9.0), Vector2(-w * 0.75, 13.0), blush_col, 1.6, true)
		draw_line(Vector2(0.0, 9.0), Vector2(-w * 0.25, 13.0), blush_col, 1.6, true)
		return

	# Sclera polygon
	var sclera := PackedVector2Array([Vector2(-w * 0.9, -h * 0.1)])
	_append_quad(sclera, Vector2(-w * 0.9, -h * 0.1), Vector2(0.0, -h * 0.72), Vector2(w * 0.92, -h * 0.08), 7)
	_append_quad(sclera, Vector2(w * 0.92, -h * 0.08), Vector2(w * 0.78, h * 0.55), Vector2(0.0, h * 0.52), 5)
	_append_quad(sclera, Vector2(0.0, h * 0.52), Vector2(-w * 0.8, h * 0.52), Vector2(-w * 0.9, -h * 0.1), 5)
	draw_colored_polygon(sclera, Color.WHITE)

	# Hard cel-shaded upper sclera shadow band
	var scl_sh := PackedVector2Array([Vector2(-w * 0.88, -h * 0.08)])
	_append_quad(scl_sh, Vector2(-w * 0.88, -h * 0.08), Vector2(0.0, -h * 0.72), Vector2(w * 0.9, -h * 0.06), 7)
	scl_sh.append(Vector2(w * 0.84, -h * 0.02))
	_append_quad(scl_sh, Vector2(w * 0.84, -h * 0.02), Vector2(0.0, -h * 0.34), Vector2(-w * 0.84, -h * 0.02), 7)
	draw_colored_polygon(scl_sh, INNER_SH1)

	# Multi-layered anime iris & pupil
	var iris_scale: float = 1.0 - eyes.wide * 0.34 if eyes.wide > 0.2 else 1.0
	var gx: float = clampf(eyes.look_x * 4.2 * foreshorten_x, -w * 0.32, w * 0.32)
	var gy: float = clampf(eyes.look_y * 2.8, -h * 0.15, h * 0.18)
	var iris_w: float = minf(6.2 * foreshorten_x * iris_scale, w * 0.52)
	var iris_h: float = minf(8.4 * iris_scale, h * 0.52)
	var iris_center := Vector2(gx, gy + 0.8)

	draw_colored_polygon(_ellipse_pts(iris_center, iris_w, iris_h, 18), Color(0.031, 0.569, 0.698))
	draw_colored_polygon(_ellipse_pts(iris_center + Vector2(0.0, -iris_h * 0.22), iris_w * 0.94, iris_h * 0.56, 16), Color(0.086, 0.306, 0.388))
	draw_colored_polygon(_ellipse_pts(iris_center + Vector2(0.0, iris_h * 0.42), iris_w * 0.70, iris_h * 0.30, 14), Color(0.404, 0.910, 0.976))
	draw_colored_polygon(_ellipse_pts(iris_center + Vector2(0.0, -0.4), iris_w * 0.46, iris_h * 0.44, 14), INK)

	# Dual white specular catchlights
	draw_circle(iris_center + Vector2(-iris_w * 0.38, -iris_h * 0.34), maxf(1.5, 2.5 * iris_scale), Color.WHITE)
	draw_circle(iris_center + Vector2(iris_w * 0.34, iris_h * 0.35), maxf(0.9, 1.3 * iris_scale), Color.WHITE)

	# Thick upper eyelash wing + outer flick + lower lash + double eyelid crease
	draw_polyline(_quad_pts(Vector2(-w * 0.96, -h * 0.04), Vector2(0.0, -h * 0.78), Vector2(w * 1.05, -h * 0.14), 8), INK, 3.5, true)
	draw_line(Vector2(w * 0.88 * float(side), -h * 0.14), Vector2(w * 1.16 * float(side), -h * 0.32), INK, 2.1, true)
	draw_polyline(_quad_pts(Vector2(-w * 0.45, h * 0.52), Vector2(0.0, h * 0.58), Vector2(w * 0.48, h * 0.50), 5), INK, 1.4, true)
	draw_polyline(_quad_pts(Vector2(-w * 0.6, -h * 0.62), Vector2(0.0, -h * 0.88), Vector2(w * 0.65, -h * 0.60), 6), Color(0.42, 0.306, 0.361), 1.0, true)


func _draw_cel_arm(
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

	var sleeve_poly := PackedVector2Array([Vector2(-9.0, -6.0)])
	_append_quad(sleeve_poly, Vector2(-9.0, -6.0), Vector2(10.0, -8.0), Vector2(11.0, 8.0), 5)
	sleeve_poly.append(Vector2(8.0, upper_len))
	sleeve_poly.append(Vector2(-8.0, upper_len))
	draw_colored_polygon(sleeve_poly, JACKET_LIT if is_front else JACKET_SH1)

	var sleeve_sh := PackedVector2Array([
		Vector2(-9.0, -4.0),
		Vector2(-1.0, -4.0),
		Vector2(-2.0, upper_len),
		Vector2(-8.0, upper_len),
	])
	draw_colored_polygon(sleeve_sh, JACKET_SH1 if is_front else JACKET_SH2)

	if is_front:
		draw_polyline(PackedVector2Array([Vector2(8.0, -2.0), Vector2(10.5, 8.0), Vector2(7.5, upper_len - 3.0)]), JACKET_RIM, 2.2, true)

	draw_polyline(_closed_outline(sleeve_poly), INK, 2.7 if is_front else 2.3, true)

	var fore_xf := upper_xf * _xform(Vector2(0.0, upper_len - 2.0), elbow_angle)
	draw_set_transform_matrix(fore_xf)

	var fore_poly := PackedVector2Array([
		Vector2(-7.5, 0.0),
		Vector2(7.5, 0.0),
		Vector2(5.5, fore_len - 8.0),
		Vector2(-5.5, fore_len - 8.0),
	])
	draw_colored_polygon(fore_poly, SKIN_LIT if is_front else SKIN_SH1)

	var fore_sh := PackedVector2Array([
		Vector2(-7.5, 0.0),
		Vector2(-1.5, 0.0),
		Vector2(-2.0, fore_len - 8.0),
		Vector2(-5.5, fore_len - 8.0),
	])
	draw_colored_polygon(fore_sh, SKIN_SH2 if not is_front else SKIN_SH1)

	var cuff_rect := Rect2(-6.0, fore_len - 12.0, 12.0, 6.0)
	draw_rect(cuff_rect, Color(0.055, 0.647, 0.914) if is_front else Color(0.012, 0.412, 0.631), true)
	draw_rect(cuff_rect, INK, false, 2.0)

	var lw: float = 2.5 if is_front else 2.1
	draw_line(Vector2(-7.5, 0.0), Vector2(-5.5, fore_len - 12.0), INK, lw, true)
	draw_line(Vector2(7.5, 0.0), Vector2(5.5, fore_len - 12.0), INK, lw, true)

	var hand_rot: float = wave_phase * 0.22 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0
	var hand_xf := fore_xf * _xform(Vector2(0.0, fore_len - 4.0), hand_rot)
	draw_set_transform_matrix(hand_xf)

	var hand_col: Color = SKIN_LIT if is_front else SKIN_SH1
	if hand_pose == MotionController.HandPose.WAVE_OPEN:
		var h_poly := PackedVector2Array([
			Vector2(-6.0, -2.0), Vector2(-9.0, 9.0), Vector2(-4.0, 17.0),
			Vector2(0.0, 18.0), Vector2(5.0, 16.0), Vector2(8.0, 8.0), Vector2(6.0, -2.0),
		])
		draw_colored_polygon(h_poly, hand_col)
		draw_polyline(_closed_outline(h_poly), INK, 2.2, true)
		draw_line(Vector2(-3.0, 9.0), Vector2(-3.0, 15.0), INK, 1.3, true)
		draw_line(Vector2(1.5, 9.0), Vector2(1.5, 16.0), INK, 1.3, true)
		draw_line(Vector2(5.0, 8.0), Vector2(4.5, 14.0), INK, 1.3, true)
	elif hand_pose == MotionController.HandPose.TENSE_SPLAY:
		var h_poly := PackedVector2Array([
			Vector2(-6.0, -2.0), Vector2(-12.0, 8.0), Vector2(-7.0, 16.0),
			Vector2(-2.0, 10.0), Vector2(0.0, 18.0), Vector2(4.0, 10.0),
			Vector2(10.0, 15.0), Vector2(7.0, 4.0), Vector2(5.0, -2.0),
		])
		draw_colored_polygon(h_poly, hand_col)
		draw_polyline(_closed_outline(h_poly), INK, 2.2, true)
	else:
		var h_poly := PackedVector2Array([Vector2(-5.5, -2.0)])
		_append_quad(h_poly, Vector2(-5.5, -2.0), Vector2(-7.0, 8.0), Vector2(-3.0, 14.0), 5)
		h_poly.append(Vector2(3.0, 13.0))
		_append_quad(h_poly, Vector2(3.0, 13.0), Vector2(6.5, 7.0), Vector2(5.0, -2.0), 5)
		draw_colored_polygon(h_poly, hand_col)
		draw_polyline(_closed_outline(h_poly), INK, 2.2, true)
