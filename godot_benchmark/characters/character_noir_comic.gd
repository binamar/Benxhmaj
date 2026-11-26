class_name CharacterNoirComic
extends Node2D

const STYLE_TITLE: String = "Bold Noir Comic Ink"
const STYLE_SUBTITLE: String = "Chiaroscuro Shadows · Thick Brush Strokes · 1 Accent"

# Strictly High-Contrast Noir Ink + Bone White + Slate Mid-Tone + 1 Crimson Accent
const INK_BLACK := Color(0.031, 0.031, 0.039, 1.0)    # #08080A pure graphic ink
const BONE_WHITE := Color(0.957, 0.953, 0.933, 1.0)   # #F4F3EE stark lit paper
const SLATE_MID := Color(0.322, 0.322, 0.357, 1.0)    # #52525B comic halftone/midtone
const ACCENT_RED := Color(0.882, 0.114, 0.282, 1.0)   # #E11D48 single vivid accent

var anchors: MotionController.RigAnchors = null


func set_anchors(a: MotionController.RigAnchors) -> void:
	anchors = a
	queue_redraw()


func get_hit_rect() -> Rect2:
	var s: float = scale.x
	var bx: float = anchors.body_root.x if anchors != null else 0.0
	var by: float = anchors.body_root.y if anchors != null else 0.0
	var w: float = 152.0 * s
	var h: float = 368.0 * s
	return Rect2(position.x + bx * s - w * 0.5, position.y + by * s - h, w, h)


static func _xform(pos: Vector2, rot: float = 0.0, scl: Vector2 = Vector2.ONE) -> Transform2D:
	return Transform2D(0.0, pos) * Transform2D(rot, Vector2.ZERO) * Transform2D.IDENTITY.scaled(scl)


static func _closed_outline(poly: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = poly.duplicate()
	if poly.size() > 0:
		out.append(poly[0])
	return out


static func _ellipse_pts(center: Vector2, rx: float, ry: float, segments: int = 16) -> PackedVector2Array:
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

	# Hard-edged noir cast shadow pool
	var air_factor: float = clampf(-body_root.y / 120.0, 0.0, 1.0)
	var sh_xf := _xform(
		Vector2(body_root.x * 0.7 - 6.0, 2.0),
		0.0,
		Vector2(1.0 - air_factor * 0.44, 1.0 - air_factor * 0.35)
	)
	draw_set_transform_matrix(sh_xf)
	draw_colored_polygon(_ellipse_pts(Vector2.ZERO, 60.0, 11.0, 20), INK_BLACK)

	# Body root
	var root_xf := _xform(
		Vector2(body_root.x + body_root.shake_x, body_root.y + body_root.shake_y),
		body_root.lean,
		Vector2(body_root.scale_x, body_root.scale_y)
	)
	draw_set_transform_matrix(root_xf)

	# === DRAMATIC GRAPHIC LEGS & ANGULAR BOOTS ===
	var knee_bend: float = clampf((1.0 - body_root.scale_y) * 28.0, -8.0, 16.0)
	for side in [-1, 1]:
		var is_back: bool = side == -1
		var hip_x: float = float(side) * 12.0
		var hip_y: float = -148.0
		var foot_x: float = float(side) * 18.0
		var kb: float = knee_bend * 0.28 * float(side)

		var leg_poly := PackedVector2Array([
			Vector2(hip_x - 13.0, hip_y),
			Vector2(hip_x + 13.0, hip_y),
			Vector2(foot_x + 9.0 + kb, -76.0),
			Vector2(foot_x + 7.5, -22.0),
			Vector2(foot_x - 7.5, -22.0),
			Vector2(foot_x - 9.0 + kb, -76.0),
		])
		draw_colored_polygon(leg_poly, INK_BLACK)

		# Stark white graphic rim wedge on front leg
		if not is_back:
			draw_colored_polygon(PackedVector2Array([
				Vector2(hip_x + 4.0, hip_y + 8.0),
				Vector2(hip_x + 11.5, hip_y + 8.0),
				Vector2(foot_x + 7.5 + kb, -76.0),
				Vector2(foot_x + 6.0, -26.0),
				Vector2(foot_x + 2.5, -26.0),
			]), BONE_WHITE)
		else:
			draw_colored_polygon(PackedVector2Array([
				Vector2(hip_x + 2.0, hip_y + 12.0),
				Vector2(hip_x + 8.0, hip_y + 12.0),
				Vector2(foot_x + 4.0, -40.0),
				Vector2(foot_x + 1.0, -40.0),
			]), SLATE_MID)

		# Sharp angular comic boot
		var boot_poly := PackedVector2Array([
			Vector2(foot_x - 9.0, -24.0),
			Vector2(foot_x + 9.0, -24.0),
			Vector2(foot_x + 21.0 * float(side) + 4.0, -5.0),
			Vector2(foot_x + 21.0 * float(side) + 4.0, 0.0),
			Vector2(foot_x - 12.0, 0.0),
		])
		draw_colored_polygon(boot_poly, INK_BLACK)
		if not is_back:
			draw_line(
				Vector2(foot_x + 5.0, -18.0),
				Vector2(foot_x + 19.0 * float(side) + 2.0, -4.0),
				BONE_WHITE,
				2.6,
				true
			)

	# === TORSO ANCHOR ===
	var torso_xf := root_xf * _xform(
		Vector2(0.0, -146.0 + torso.offset_y),
		torso.tilt,
		Vector2(torso.breath_scale_x * (1.0 - absf(torso.twist) * 0.06), torso.breath_scale_y)
	)

	# Sweeping Noir Cape-Flap (secondary_lag behind body: dramatic silhouette!)
	var cape_xf := torso_xf * _xform(Vector2(-10.0, -104.0), lag.rot * 0.95 - 0.08)
	draw_set_transform_matrix(cape_xf)
	var cape_tip_l := Vector2(-62.0 + lag.x * 1.35 + lag.flutter * 1.1, 168.0 + lag.y * 1.1)
	var cape_tip_m := Vector2(-18.0 + lag.x * 1.1 + lag.flutter * 0.7, 152.0 + lag.y * 0.95)
	var cape_tip_r := Vector2(36.0 + lag.x * 0.9 + lag.flutter * 0.5, 160.0 + lag.y * 0.9)
	var cape_poly := PackedVector2Array([
		Vector2(-28.0, 0.0),
		Vector2(30.0, 4.0),
		cape_tip_r,
		cape_tip_m,
		cape_tip_l,
		Vector2(-46.0 + lag.x * 0.65, 86.0 + lag.y * 0.45),
	])
	draw_colored_polygon(cape_poly, INK_BLACK)

	# Dramatic crimson accent flash inside trailing cape edge
	var cape_accent := PackedVector2Array([
		Vector2(-24.0, 18.0),
		Vector2(-42.0 + lag.x * 0.65, 86.0 + lag.y * 0.45),
		cape_tip_l + Vector2(6.0, -4.0),
		cape_tip_l + Vector2(18.0, -8.0),
		Vector2(-32.0 + lag.x * 0.5, 80.0 + lag.y * 0.4),
	])
	draw_colored_polygon(cape_accent, ACCENT_RED)
	draw_polyline(_closed_outline(cape_poly), INK_BLACK, 4.0, true)

	# Back Arm
	_draw_noir_arm(
		torso_xf,
		Vector2(-34.0 + torso.twist * 5.0, -96.0),
		back_arm.shoulder_angle,
		back_arm.elbow_angle,
		back_arm.hand_pose,
		0.0,
		false
	)

	# Broad Geometric V-Tapered Noir Torso
	draw_set_transform_matrix(torso_xf)
	var sh_w: float = 40.0
	var waist_w: float = 18.0
	var torso_h: float = 108.0

	# Solid black silhouette base
	var coat_poly := PackedVector2Array([
		Vector2(-sh_w, -torso_h + 10.0),
		Vector2(0.0, -torso_h - 4.0),
		Vector2(sh_w, -torso_h + 10.0),
		Vector2(waist_w + 4.0, 8.0),
		Vector2(-waist_w - 4.0, 8.0),
	])
	draw_colored_polygon(coat_poly, INK_BLACK)

	# Stark bone-white chiaroscuro lit right chest & shoulder plane
	var lit_chest := PackedVector2Array([
		Vector2(6.0 + torso.twist * 8.0, -torso_h + 2.0),
		Vector2(sh_w - 3.0, -torso_h + 12.0),
		Vector2(waist_w + 2.0, 5.0),
		Vector2(2.0 + torso.twist * 8.0, 5.0),
		Vector2(10.0 + torso.twist * 8.0, -44.0),
	])
	draw_colored_polygon(lit_chest, BONE_WHITE)

	# Crisp mid-gray graphic hatch block on right rib
	draw_colored_polygon(PackedVector2Array([
		Vector2(14.0, -52.0),
		Vector2(26.0, -54.0),
		Vector2(waist_w + 1.0, 4.0),
		Vector2(8.0, 4.0),
	]), SLATE_MID)

	# Center crisp white shirt V & Crimson Tie (single accent color!)
	var shirt_v := PackedVector2Array([
		Vector2(-10.0 + torso.twist * 8.0, -torso_h),
		Vector2(11.0 + torso.twist * 8.0, -torso_h),
		Vector2(1.0 + torso.twist * 9.0, -34.0),
	])
	draw_colored_polygon(shirt_v, BONE_WHITE)

	var tie_poly := PackedVector2Array([
		Vector2(-3.5 + torso.twist * 8.0, -torso_h + 4.0),
		Vector2(4.5 + torso.twist * 8.0, -torso_h + 4.0),
		Vector2(5.5 + torso.twist * 9.0, -48.0),
		Vector2(1.0 + torso.twist * 9.0, -34.0),
		Vector2(-3.5 + torso.twist * 9.0, -48.0),
	])
	draw_colored_polygon(tie_poly, ACCENT_RED)
	draw_polyline(_closed_outline(tie_poly), INK_BLACK, 2.4, true)

	# Thick bold graphic brush-ink torso outline
	draw_polyline(_closed_outline(coat_poly), INK_BLACK, 4.5, true)

	# Dramatic upturned High Noir Collar (framing jaw)
	var collar_back := PackedVector2Array([
		Vector2(-24.0, -torso_h + 4.0),
		Vector2(-29.0, -torso_h - 24.0),
		Vector2(29.0, -torso_h - 24.0),
		Vector2(24.0, -torso_h + 4.0),
	])
	draw_colored_polygon(collar_back, INK_BLACK)
	# Crimson collar interior slash
	draw_colored_polygon(PackedVector2Array([
		Vector2(10.0, -torso_h - 20.0),
		Vector2(25.0, -torso_h - 21.0),
		Vector2(20.0, -torso_h + 2.0),
		Vector2(6.0, -torso_h + 2.0),
	]), ACCENT_RED)
	draw_polyline(_closed_outline(collar_back), INK_BLACK, 3.8, true)

	# Neck (carved half in solid black ink)
	draw_rect(Rect2(-8.0, -torso_h - 18.0, 16.0, 20.0), BONE_WHITE, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0, -torso_h - 18.0),
		Vector2(3.0, -torso_h - 18.0),
		Vector2(-2.0, -torso_h + 2.0),
		Vector2(-8.0, -torso_h + 2.0),
	]), INK_BLACK)
	draw_rect(Rect2(-8.0, -torso_h - 18.0, 16.0, 20.0), INK_BLACK, false, 3.4)

	# === HEAD PIVOT ANCHOR ===
	var head_xf := torso_xf * _xform(
		Vector2(head_pivot.offset_x, -torso_h - 16.0 + head_pivot.offset_y),
		head_pivot.tilt
	)
	var yaw: float = head_pivot.turn_25d
	var pitch: float = head_pivot.pitch_25d
	var face_shift_x: float = yaw * 11.0
	var face_shift_y: float = pitch * 6.0

	# Back slick angular noir hair silhouette
	var back_h_xf := head_xf * _xform(Vector2(lag.x * 0.12, lag.y * 0.12), lag.rot * 0.2)
	draw_set_transform_matrix(back_h_xf)
	var back_hair := PackedVector2Array([
		Vector2(-26.0, -34.0),
		Vector2(-12.0, -64.0),
		Vector2(18.0, -62.0),
		Vector2(28.0, -34.0),
		Vector2(23.0, -10.0),
		Vector2(-23.0, -10.0),
	])
	draw_colored_polygon(back_hair, INK_BLACK)

	# Sharp angular comic ears
	for ear_side in [-1, 1]:
		var ear_vis: float = clampf(1.0 - float(ear_side) * yaw * 0.85, 0.1, 1.15)
		var ear_xf := head_xf * _xform(
			Vector2(float(ear_side) * 23.0 - yaw * 5.0, -25.0 + face_shift_y * 0.35),
			0.0,
			Vector2(ear_vis, 1.0)
		)
		draw_set_transform_matrix(ear_xf)
		var ear_poly := PackedVector2Array([
			Vector2(-4.0, -8.0), Vector2(4.0, -6.0), Vector2(3.0, 7.0), Vector2(-3.0, 6.0),
		])
		draw_colored_polygon(ear_poly, INK_BLACK if ear_side == -1 else BONE_WHITE)
		draw_polyline(_closed_outline(ear_poly), INK_BLACK, 3.2, true)

	# Chiseled Angular Comic Head Contour
	draw_set_transform_matrix(head_xf)
	var chin := Vector2(yaw * 6.0, 4.0 + pitch * 3.5)
	var head_poly := PackedVector2Array([
		Vector2(-23.0, -34.0),
		Vector2(-14.0, -58.0),
		Vector2(16.0, -58.0),
		Vector2(23.0, -34.0),
		Vector2(19.0 + yaw * 3.0, -11.0 + pitch * 2.0),
		chin + Vector2(5.0, 0.0),
		chin + Vector2(-5.0, 0.0),
		Vector2(-19.0 + yaw * 3.0, -11.0 + pitch * 2.0),
	])
	draw_colored_polygon(head_poly, BONE_WHITE)

	# STARK CHIAROSCURO SPLIT-LIGHT BLACK SHADOW BLOCK carving left half of face!
	var split_x: float = -2.0 + face_shift_x * 0.65
	var shadow_face := PackedVector2Array([
		Vector2(-23.0, -34.0),
		Vector2(-14.0, -58.0),
		Vector2(split_x + 3.0, -58.0),
		Vector2(split_x, -31.0 + face_shift_y * 0.5),
		Vector2(split_x - 4.0, -20.0 + face_shift_y * 0.7),
		Vector2(split_x + 2.0, -13.0 + face_shift_y * 0.7),
		chin + Vector2(-1.0, 0.0),
		chin + Vector2(-5.0, 0.0),
		Vector2(-19.0 + yaw * 3.0, -11.0 + pitch * 2.0),
	])
	draw_colored_polygon(shadow_face, INK_BLACK)

	# Heavy comic brow shadow bar across upper face
	var brow_bar := PackedVector2Array([
		Vector2(-23.0, -37.0),
		Vector2(23.0, -37.0),
		Vector2(22.0, -26.0 + face_shift_y * 0.7),
		Vector2(-22.0, -26.0 + face_shift_y * 0.7),
	])
	draw_colored_polygon(brow_bar, INK_BLACK)

	# Thick graphic brush outline on head
	draw_polyline(_closed_outline(head_poly), INK_BLACK, 4.2, true)

	# === EYES ANCHOR (Sharp Angular Noir Comic Eyes) ===
	var eye_y: float = -25.5 + face_shift_y
	var left_fs: float = clampf(1.0 - maxf(0.0, -yaw) * 0.35, 0.58, 1.0)
	var right_fs: float = clampf(1.0 - maxf(0.0, yaw) * 0.35, 0.58, 1.0)
	_draw_noir_eye(head_xf, Vector2(-9.5 * left_fs + face_shift_x, eye_y), -1, left_fs, eyes)
	_draw_noir_eye(head_xf, Vector2(9.5 * right_fs + face_shift_x, eye_y), 1, right_fs, eyes)

	# Angular ink nose wedge
	draw_set_transform_matrix(head_xf)
	var nx: float = face_shift_x * 1.15
	var ny: float = -23.0 + face_shift_y
	draw_colored_polygon(PackedVector2Array([
		Vector2(nx, ny),
		Vector2(nx + 4.5, ny + 9.5),
		Vector2(nx - 2.0, ny + 10.5),
	]), INK_BLACK)

	# === MOUTH ANCHOR (Bold Graphic Comic Mouth) ===
	var mouth_xf := head_xf * _xform(Vector2(face_shift_x * 1.05, -6.5 + face_shift_y * 1.1))
	draw_set_transform_matrix(mouth_xf)
	match mouth.shape:
		MotionController.MouthShape.O_SHOCK:
			var w: float = 5.0 + mouth.open * 3.0
			var h: float = 5.5 + mouth.open * 5.0
			var gasp := PackedVector2Array([
				Vector2(-w, -h * 0.5), Vector2(0.0, -h), Vector2(w, -h * 0.5),
				Vector2(w * 0.85, h * 0.7), Vector2(0.0, h), Vector2(-w * 0.85, h * 0.7),
			])
			draw_colored_polygon(gasp, INK_BLACK)
			draw_line(Vector2(-w * 0.5, -h * 0.45), Vector2(w * 0.5, -h * 0.45), BONE_WHITE, 2.0, true)
		MotionController.MouthShape.OPEN_HAPPY:
			var grin := PackedVector2Array([
				Vector2(-8.0, -1.5), Vector2(8.5, -2.5),
				Vector2(6.5, 6.5 * mouth.open + 1.5), Vector2(-5.5, 5.5 * mouth.open + 1.5),
			])
			draw_colored_polygon(grin, INK_BLACK)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-5.5, -0.5), Vector2(6.0, -1.2), Vector2(4.5, 2.2), Vector2(-4.0, 2.0),
			]), BONE_WHITE)
		MotionController.MouthShape.SMILE:
			draw_polyline(PackedVector2Array([
				Vector2(-6.5, 0.5), Vector2(1.0, 3.0), Vector2(8.0, -1.5),
			]), INK_BLACK, 3.0, true)
		_:
			draw_line(Vector2(-5.5, 1.0), Vector2(6.5, -0.5), INK_BLACK, 3.0, true)

	# Sharp Graphic Slick Noir Hair + Rogue Forehead Lock (secondary_lag)
	var hair_xf := head_xf * _xform(Vector2(face_shift_x * 0.35 + lag.x * 0.06, lag.y * 0.06))
	draw_set_transform_matrix(hair_xf)
	var top_hair := PackedVector2Array([
		Vector2(-25.0, -34.0),
		Vector2(-18.0, -61.0),
		Vector2(18.0, -61.0),
		Vector2(26.0, -34.0),
		Vector2(18.0, -42.0),
		Vector2(4.0, -36.0),
		Vector2(-8.0, -45.0),
		Vector2(-19.0, -36.0),
	])
	draw_colored_polygon(top_hair, INK_BLACK)

	# Stark white comic graphic shine slash on hair crown
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2.0, -57.0),
		Vector2(14.0, -57.0),
		Vector2(18.0, -48.0),
		Vector2(3.0, -50.0),
	]), BONE_WHITE)

	# Rogue sweeping forehead ink lock reacting to secondary_lag
	var lock_xf := hair_xf * _xform(Vector2(2.0, -40.0), lag.rot * 0.75)
	draw_set_transform_matrix(lock_xf)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3.0, 0.0),
		Vector2(6.0, -2.0),
		Vector2(12.0 + lag.x * 0.28, 17.0 + lag.y * 0.14),
		Vector2(2.0 + lag.x * 0.18, 12.0),
	]), INK_BLACK)

	# Front Arm (drawn over torso)
	_draw_noir_arm(
		torso_xf,
		Vector2(36.0 + torso.twist * 5.0, -96.0),
		front_arm.shoulder_angle,
		front_arm.elbow_angle,
		front_arm.hand_pose,
		front_arm.wave_phase,
		true
	)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_noir_eye(
	head_xf: Transform2D,
	eye_pos: Vector2,
	side: int,
	foreshorten_x: float,
	eyes: MotionController.EyesAnchor
) -> void:
	var eye_xf := head_xf * _xform(eye_pos)
	draw_set_transform_matrix(eye_xf)

	var w: float = 8.2 * foreshorten_x
	var h: float = 4.6 * (1.0 + eyes.wide * 0.55) * (1.0 - clampf(eyes.blink, 0.0, 1.0) * 0.94)

	# Heavy angular comic brow wedge
	var brow_y: float = -7.5 - eyes.brow_offset * 4.2 + eyes.squint * 1.5
	draw_line(
		Vector2(-w * 1.15, brow_y + (2.0 if side == 1 else -1.5)),
		Vector2(w * 1.15, brow_y + (-1.5 if side == 1 else 2.0)),
		BONE_WHITE if side == 1 else SLATE_MID,
		2.0,
		true
	)

	if eyes.blink > 0.78:
		draw_line(Vector2(-w, 1.0), Vector2(w, 1.0), BONE_WHITE, 2.2, true)
		return

	if eyes.squint > 0.45 and eyes.wide < 0.2:
		draw_polyline(PackedVector2Array([
			Vector2(-w * 0.9, 1.5), Vector2(0.0, -4.5), Vector2(w * 0.9, 1.5),
		]), BONE_WHITE, 2.8, true)
		return

	# Sharp angular stark-white comic eye polygon
	var eye_poly := PackedVector2Array([
		Vector2(-w, 0.5),
		Vector2(-w * 0.35, -h),
		Vector2(w * 0.85, -h * 0.75),
		Vector2(w, 0.8),
		Vector2(0.0, h * 0.85),
	])
	draw_colored_polygon(eye_poly, BONE_WHITE)

	# Razor pupil + crimson glint (single accent color!)
	var gx: float = clampf(eyes.look_x * 3.0 * foreshorten_x, -w * 0.4, w * 0.4)
	var gy: float = clampf(eyes.look_y * 1.6, -h * 0.25, h * 0.25)
	var pr: float = minf(2.7 * (1.0 - eyes.wide * 0.35 if eyes.wide > 0.2 else 1.0), h * 0.72)
	var pc := Vector2(gx, gy)
	draw_circle(pc, pr, INK_BLACK)
	draw_circle(pc + Vector2(-pr * 0.3, -pr * 0.25), maxf(0.9, pr * 0.42), ACCENT_RED)

	draw_polyline(_closed_outline(eye_poly), INK_BLACK, 2.8, true)


func _draw_noir_arm(
	torso_xf: Transform2D,
	shoulder_pos: Vector2,
	shoulder_angle: float,
	elbow_angle: float,
	hand_pose: int,
	wave_phase: float,
	is_front: bool
) -> void:
	var upper_len: float = 54.0
	var fore_len: float = 50.0

	var upper_xf := torso_xf * _xform(shoulder_pos, shoulder_angle)
	draw_set_transform_matrix(upper_xf)

	var u_poly := PackedVector2Array([
		Vector2(-11.0, -7.0), Vector2(11.0, -7.0),
		Vector2(9.0, upper_len), Vector2(-9.0, upper_len),
	])
	draw_colored_polygon(u_poly, INK_BLACK)
	if is_front:
		draw_colored_polygon(PackedVector2Array([
			Vector2(2.0, -4.0), Vector2(9.5, -4.0),
			Vector2(7.5, upper_len - 2.0), Vector2(2.0, upper_len - 2.0),
		]), BONE_WHITE)
	draw_polyline(_closed_outline(u_poly), INK_BLACK, 3.8 if is_front else 3.2, true)

	var fore_xf := upper_xf * _xform(Vector2(0.0, upper_len - 2.0), elbow_angle)
	draw_set_transform_matrix(fore_xf)

	var f_poly := PackedVector2Array([
		Vector2(-9.0, 0.0), Vector2(9.0, 0.0),
		Vector2(6.5, fore_len - 6.0), Vector2(-6.5, fore_len - 6.0),
	])
	draw_colored_polygon(f_poly, INK_BLACK)
	if is_front:
		draw_colored_polygon(PackedVector2Array([
			Vector2(1.5, 2.0), Vector2(7.5, 2.0),
			Vector2(5.2, fore_len - 8.0), Vector2(1.5, fore_len - 8.0),
		]), BONE_WHITE)
		# Crisp white shirt cuff edge
		draw_rect(Rect2(-6.5, fore_len - 9.0, 13.0, 4.0), BONE_WHITE, true)
	draw_polyline(_closed_outline(f_poly), INK_BLACK, 3.6 if is_front else 3.0, true)

	var hand_rot: float = wave_phase * 0.24 if hand_pose == MotionController.HandPose.WAVE_OPEN else 0.0
	var hand_xf := fore_xf * _xform(Vector2(0.0, fore_len - 2.0), hand_rot)
	draw_set_transform_matrix(hand_xf)

	var h_col: Color = BONE_WHITE if is_front else SLATE_MID
	if hand_pose == MotionController.HandPose.WAVE_OPEN:
		var h_poly := PackedVector2Array([
			Vector2(-6.0, -2.0), Vector2(-10.0, 10.0), Vector2(-4.0, 18.0),
			Vector2(0.0, 20.0), Vector2(5.0, 17.0), Vector2(9.0, 8.0), Vector2(6.0, -2.0),
		])
		draw_colored_polygon(h_poly, h_col)
		draw_polyline(_closed_outline(h_poly), INK_BLACK, 3.2, true)
	elif hand_pose == MotionController.HandPose.TENSE_SPLAY:
		var h_poly := PackedVector2Array([
			Vector2(-6.0, -2.0), Vector2(-13.0, 9.0), Vector2(-7.0, 17.0),
			Vector2(-2.0, 10.0), Vector2(0.0, 20.0), Vector2(4.0, 10.0),
			Vector2(11.0, 16.0), Vector2(8.0, 4.0), Vector2(6.0, -2.0),
		])
		draw_colored_polygon(h_poly, h_col)
		draw_polyline(_closed_outline(h_poly), INK_BLACK, 3.2, true)
	else:
		var h_poly := PackedVector2Array([
			Vector2(-6.0, -2.0), Vector2(-7.0, 10.0), Vector2(-2.0, 16.0),
			Vector2(4.0, 14.0), Vector2(6.5, 6.0), Vector2(5.5, -2.0),
		])
		draw_colored_polygon(h_poly, h_col)
		draw_polyline(_closed_outline(h_poly), INK_BLACK, 3.2, true)
