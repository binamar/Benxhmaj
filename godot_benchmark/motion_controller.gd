class_name MotionController
extends Node

enum Motion {
	IDLE,
	NOD_LOOK,
	WAVE,
	JUMP,
	SHOCK,
}

enum MouthShape {
	NEUTRAL,
	SMILE,
	OPEN_HAPPY,
	O_SHOCK,
}

enum HandPose {
	RELAXED,
	WAVE_OPEN,
	TENSE_SPLAY,
}

const MOTION_ORDER := [
	Motion.IDLE,
	Motion.NOD_LOOK,
	Motion.WAVE,
	Motion.JUMP,
	Motion.SHOCK,
]

const MOTION_LABELS: Dictionary = {
	Motion.IDLE: "Idle",
	Motion.NOD_LOOK: "Nod & Look",
	Motion.WAVE: "Wave",
	Motion.JUMP: "Jump",
	Motion.SHOCK: "Shock",
}


class BodyRootAnchor:
	var x: float = 0.0
	var y: float = 0.0
	var scale_x: float = 1.0
	var scale_y: float = 1.0
	var lean: float = 0.0
	var shake_x: float = 0.0
	var shake_y: float = 0.0


class TorsoAnchor:
	var offset_y: float = 0.0
	var breath_scale_x: float = 1.0
	var breath_scale_y: float = 1.0
	var tilt: float = 0.0
	var twist: float = 0.0


class HeadPivotAnchor:
	var offset_x: float = 0.0
	var offset_y: float = 0.0
	var tilt: float = 0.0
	var turn_25d: float = 0.0
	var pitch_25d: float = 0.0


class EyesAnchor:
	var blink: float = 0.0
	var look_x: float = 0.0
	var look_y: float = 0.0
	var wide: float = 0.0
	var brow_offset: float = 0.0
	var squint: float = 0.0


class MouthAnchor:
	var shape: int = MouthShape.NEUTRAL
	var open: float = 0.0


class ArmAnchor:
	var shoulder_angle: float = 0.0
	var elbow_angle: float = 0.0
	var hand_pose: int = HandPose.RELAXED
	var wave_phase: float = 0.0


class SecondaryLagAnchor:
	var x: float = 0.0
	var y: float = 0.0
	var rot: float = 0.0
	var flutter: float = 0.0


class RigAnchors:
	var body_root := BodyRootAnchor.new()
	var torso := TorsoAnchor.new()
	var head_pivot := HeadPivotAnchor.new()
	var eyes := EyesAnchor.new()
	var mouth := MouthAnchor.new()
	var front_arm := ArmAnchor.new()
	var back_arm := ArmAnchor.new()
	var secondary_lag := SecondaryLagAnchor.new()


var current_motion: int = Motion.IDLE
var motion_time: float = 0.0
var global_time: float = 0.0

var _target := RigAnchors.new()
var _current := RigAnchors.new()

# Spring-damper state for secondary_lag (hair / scarf / coat tails / cape)
var _prev_body_x: float = 0.0
var _prev_body_y: float = 0.0
var _prev_head_tilt: float = 0.0
var _lag_pos_x: float = 0.0
var _lag_pos_y: float = 0.0
var _lag_vel_x: float = 0.0
var _lag_vel_y: float = 0.0
var _lag_rot: float = 0.0
var _lag_rot_vel: float = 0.0


func _ready() -> void:
	_reset_defaults(_target)
	_reset_defaults(_current)


func get_motion() -> int:
	return current_motion


func set_motion(motion_id: int, reset_phase: bool = true) -> void:
	if current_motion != motion_id or reset_phase:
		current_motion = motion_id
		motion_time = 0.0


func next_motion() -> int:
	var idx: int = MOTION_ORDER.find(current_motion)
	var next_id: int = MOTION_ORDER[(idx + 1) % MOTION_ORDER.size()]
	set_motion(next_id, true)
	return next_id


func get_anchors() -> RigAnchors:
	return _current


func step(raw_delta: float) -> RigAnchors:
	var dt: float = clampf(raw_delta, 0.0005, 0.05)
	global_time += dt
	motion_time += dt

	_evaluate_target_pose()

	var blend_rate: float = 24.0 if current_motion == Motion.SHOCK else 14.0
	var alpha: float = 1.0 - exp(-blend_rate * dt)
	_lerp_anchors(_current, _target, alpha)
	_update_secondary_spring(dt)

	return _current


func _reset_defaults(r: RigAnchors) -> void:
	r.body_root.x = 0.0
	r.body_root.y = 0.0
	r.body_root.scale_x = 1.0
	r.body_root.scale_y = 1.0
	r.body_root.lean = 0.0
	r.body_root.shake_x = 0.0
	r.body_root.shake_y = 0.0

	r.torso.offset_y = 0.0
	r.torso.breath_scale_x = 1.0
	r.torso.breath_scale_y = 1.0
	r.torso.tilt = 0.0
	r.torso.twist = 0.0

	r.head_pivot.offset_x = 0.0
	r.head_pivot.offset_y = 0.0
	r.head_pivot.tilt = 0.0
	r.head_pivot.turn_25d = 0.0
	r.head_pivot.pitch_25d = 0.0

	r.eyes.blink = 0.0
	r.eyes.look_x = 0.0
	r.eyes.look_y = 0.0
	r.eyes.wide = 0.0
	r.eyes.brow_offset = 0.0
	r.eyes.squint = 0.0

	r.mouth.shape = MouthShape.NEUTRAL
	r.mouth.open = 0.0

	r.front_arm.shoulder_angle = 0.14
	r.front_arm.elbow_angle = -0.20
	r.front_arm.hand_pose = HandPose.RELAXED
	r.front_arm.wave_phase = 0.0

	r.back_arm.shoulder_angle = -0.10
	r.back_arm.elbow_angle = -0.16
	r.back_arm.hand_pose = HandPose.RELAXED
	r.back_arm.wave_phase = 0.0


func _ease_out_cubic(t: float) -> float:
	var x: float = clampf(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)


func _ease_in_out_sine(t: float) -> float:
	var x: float = clampf(t, 0.0, 1.0)
	return -(cos(PI * x) - 1.0) * 0.5


func _single_blink(local_t: float, start: float) -> float:
	var dur: float = 0.17
	if local_t < start or local_t > start + dur:
		return 0.0
	var p: float = (local_t - start) / dur
	if p < 0.4:
		return smoothstep(0.0, 0.4, p)
	return 1.0 - smoothstep(0.4, 1.0, p)


func _compute_natural_blink(t: float) -> float:
	var cycle_len: float = 3.4
	var cycle_idx: int = int(floor(t / cycle_len))
	var local_t: float = fmod(t, cycle_len)
	var b: float = _single_blink(local_t, 1.9)
	if cycle_idx % 2 == 1:
		b = maxf(b, _single_blink(local_t, 2.22))
	return b


func _evaluate_target_pose() -> void:
	var t: float = motion_time
	var g: float = global_time
	var base_blink: float = _compute_natural_blink(g)

	var r: RigAnchors = _target
	_reset_defaults(r)
	r.eyes.blink = base_blink

	match current_motion:
		Motion.IDLE:
			var breath: float = sin(t * 2.25)
			var breath_cos: float = cos(t * 2.25)
			r.torso.offset_y = -breath * 2.6
			r.torso.breath_scale_x = 1.0 + breath * 0.016
			r.torso.breath_scale_y = 1.0 + breath * 0.018
			r.body_root.scale_y = 1.0 + breath * 0.008
			r.body_root.scale_x = 1.0 - breath * 0.006

			r.head_pivot.offset_y = -breath * 1.8
			r.head_pivot.tilt = sin(t * 1.15) * 0.042
			r.head_pivot.turn_25d = sin(t * 0.72) * 0.10

			# Saccadic left / center / right eye glances
			var g_cycle: float = fmod(t, 6.4)
			var glance_target: float = 0.0
			if g_cycle > 1.1 and g_cycle < 2.3:
				glance_target = -0.65 * smoothstep(1.1, 1.24, g_cycle) * (1.0 - smoothstep(2.14, 2.3, g_cycle))
			elif g_cycle > 3.6 and g_cycle < 4.9:
				glance_target = 0.68 * smoothstep(3.6, 3.74, g_cycle) * (1.0 - smoothstep(4.74, 4.9, g_cycle))
			r.eyes.look_x = glance_target
			r.eyes.look_y = sin(t * 0.9) * 0.08

			r.front_arm.shoulder_angle = 0.13 + breath_cos * 0.03
			r.front_arm.elbow_angle = -0.22 - breath * 0.03
			r.back_arm.shoulder_angle = -0.11 - breath_cos * 0.025
			r.back_arm.elbow_angle = -0.16 + breath * 0.02

		Motion.NOD_LOOK:
			var loop: float = fmod(t, 3.8) / 3.8
			var turn: float = 0.0
			var tilt: float = 0.0
			var pitch: float = 0.0
			var nod_offset: float = 0.0
			var look_x: float = 0.0
			var torso_twist: float = 0.0
			var blink: float = base_blink

			if loop < 0.28:
				var p: float = _ease_in_out_sine(loop / 0.28)
				turn = lerpf(0.0, 0.78, p)
				look_x = lerpf(0.0, 0.62, p)
				tilt = lerpf(0.0, 0.075, p)
				torso_twist = lerpf(0.0, 0.26, p)
			elif loop < 0.52:
				var p: float = (loop - 0.28) / 0.24
				var dip: float = maxf(0.0, sin(p * TAU))
				turn = 0.78
				look_x = 0.55
				tilt = 0.075 - dip * 0.04
				pitch = dip * 0.65
				nod_offset = dip * 5.5
				torso_twist = 0.26
				if p > 0.15 and p < 0.45:
					blink = maxf(blink, 0.85)
			elif loop < 0.78:
				var p: float = _ease_in_out_sine((loop - 0.52) / 0.26)
				turn = lerpf(0.78, -0.74, p)
				look_x = lerpf(0.55, -0.66, p)
				tilt = lerpf(0.075, -0.095, p)
				torso_twist = lerpf(0.26, -0.24, p)
				pitch = sin(p * PI) * 0.15
			else:
				var p: float = _ease_in_out_sine((loop - 0.78) / 0.22)
				var settle_dip: float = sin(p * PI) * 0.35
				turn = lerpf(-0.74, 0.0, p)
				look_x = lerpf(-0.66, 0.0, p)
				tilt = lerpf(-0.095, 0.0, p)
				torso_twist = lerpf(-0.24, 0.0, p)
				pitch = settle_dip
				nod_offset = settle_dip * 4.0

			var breath: float = sin(t * 2.2)
			r.torso.offset_y = -breath * 1.8 + nod_offset * 0.25
			r.torso.twist = torso_twist
			r.torso.tilt = torso_twist * 0.08
			r.head_pivot.turn_25d = turn
			r.head_pivot.tilt = tilt
			r.head_pivot.pitch_25d = pitch
			r.head_pivot.offset_y = nod_offset
			r.head_pivot.offset_x = turn * 3.5

			r.eyes.blink = blink
			r.eyes.look_x = look_x
			r.eyes.look_y = pitch * 0.35
			r.eyes.brow_offset = 0.18
			r.mouth.shape = MouthShape.SMILE
			r.mouth.open = 0.10

			r.front_arm.shoulder_angle = 0.16 - torso_twist * 0.18
			r.front_arm.elbow_angle = -0.32
			r.back_arm.shoulder_angle = -0.14 + torso_twist * 0.15
			r.back_arm.elbow_angle = -0.22

		Motion.WAVE:
			var bounce: float = absf(sin(t * 5.6))
			var sway: float = sin(t * 2.8)

			r.body_root.y = -bounce * 10.0
			r.body_root.scale_y = 1.0 + (bounce - 0.4) * 0.045
			r.body_root.scale_x = 1.0 - (bounce - 0.4) * 0.035

			r.torso.tilt = sway * 0.055
			r.torso.offset_y = -bounce * 2.0
			r.torso.twist = -0.12 + sway * 0.06

			r.head_pivot.tilt = 0.09 + sway * 0.045
			r.head_pivot.turn_25d = 0.12
			r.head_pivot.offset_y = -bounce * 1.5

			r.eyes.squint = 0.72
			r.eyes.brow_offset = 0.38
			r.eyes.look_x = 0.08
			r.eyes.look_y = -0.05
			r.mouth.shape = MouthShape.OPEN_HAPPY
			r.mouth.open = 0.55 + bounce * 0.20

			var wave_osc: float = sin(t * 11.5)
			r.front_arm.shoulder_angle = -2.22 + wave_osc * 0.14
			r.front_arm.elbow_angle = -0.95 + wave_osc * 0.52
			r.front_arm.hand_pose = HandPose.WAVE_OPEN
			r.front_arm.wave_phase = wave_osc

			r.back_arm.shoulder_angle = -0.28 + bounce * 0.12
			r.back_arm.elbow_angle = -0.45
			r.back_arm.hand_pose = HandPose.RELAXED

		Motion.JUMP:
			var cycle: float = fmod(t, 1.9) / 1.9

			if cycle < 0.22:
				var p: float = smoothstep(0.0, 0.22, cycle)
				r.body_root.y = lerpf(0.0, 12.0, p)
				r.body_root.scale_x = lerpf(1.0, 1.15, p)
				r.body_root.scale_y = lerpf(1.0, 0.84, p)
				r.body_root.lean = lerpf(0.0, 0.13, p)
				r.torso.tilt = lerpf(0.0, 0.10, p)
				r.head_pivot.pitch_25d = lerpf(0.0, 0.28, p)
				r.front_arm.shoulder_angle = lerpf(0.14, 0.72, p)
				r.front_arm.elbow_angle = lerpf(-0.20, -0.55, p)
				r.back_arm.shoulder_angle = lerpf(-0.10, 0.65, p)
				r.back_arm.elbow_angle = lerpf(-0.16, -0.50, p)
				r.eyes.squint = p * 0.30
				r.mouth.shape = MouthShape.NEUTRAL
			elif cycle < 0.64:
				var p: float = (cycle - 0.22) / 0.42
				var arc: float = 4.0 * p * (1.0 - p)
				var vel: float = 1.0 - 2.0 * p

				r.body_root.y = -arc * 118.0
				var stretch: float = absf(vel) * 0.14
				r.body_root.scale_y = 1.0 + stretch
				r.body_root.scale_x = 1.0 - stretch * 0.72
				r.body_root.lean = -vel * 0.08

				r.head_pivot.pitch_25d = -vel * 0.26
				r.head_pivot.tilt = -0.04
				r.eyes.brow_offset = 0.45
				r.eyes.wide = 0.25
				r.eyes.look_y = -vel * 0.35
				r.mouth.shape = MouthShape.OPEN_HAPPY
				r.mouth.open = 0.45

				var arm_lift: float = _ease_out_cubic(minf(1.0, p * 1.6))
				r.front_arm.shoulder_angle = lerpf(0.72, -2.35, arm_lift) + (1.0 - arc) * 0.40
				r.front_arm.elbow_angle = -0.45
				r.front_arm.hand_pose = HandPose.WAVE_OPEN
				r.back_arm.shoulder_angle = lerpf(0.65, -2.15, arm_lift) + (1.0 - arc) * 0.35
				r.back_arm.elbow_angle = -0.35
				r.back_arm.hand_pose = HandPose.WAVE_OPEN
			elif cycle < 0.82:
				var p: float = (cycle - 0.64) / 0.18
				var impact: float = sin(p * PI)
				r.body_root.y = impact * 15.0
				r.body_root.scale_x = 1.0 + impact * 0.17
				r.body_root.scale_y = 1.0 - impact * 0.18
				r.body_root.lean = impact * 0.14
				r.head_pivot.pitch_25d = impact * 0.35
				r.head_pivot.offset_y = impact * 5.0
				r.eyes.blink = 0.9 if impact > 0.35 else base_blink
				r.front_arm.shoulder_angle = -0.55 + impact * 0.90
				r.front_arm.elbow_angle = -0.70
				r.back_arm.shoulder_angle = -0.45 + impact * 0.80
				r.back_arm.elbow_angle = -0.65
				r.mouth.shape = MouthShape.SMILE
			else:
				var p: float = _ease_out_cubic((cycle - 0.82) / 0.18)
				r.body_root.y = lerpf(3.0, 0.0, p)
				r.body_root.scale_x = lerpf(1.03, 1.0, p)
				r.body_root.scale_y = lerpf(0.97, 1.0, p)
				r.front_arm.shoulder_angle = lerpf(0.30, 0.14, p)
				r.back_arm.shoulder_angle = lerpf(0.25, -0.10, p)
				r.mouth.shape = MouthShape.SMILE

		Motion.SHOCK:
			var cycle: float = fmod(t, 2.2) / 2.2
			var recoil_env: float = 0.0
			if cycle < 0.08:
				recoil_env = _ease_out_cubic(cycle / 0.08)
			elif cycle < 0.68:
				recoil_env = 1.0 - smoothstep(0.32, 0.68, cycle) * 0.35
			else:
				recoil_env = 1.0 - smoothstep(0.68, 1.0, cycle)

			var shake_env: float = exp(-cycle * 5.2) if cycle < 0.55 else 0.0
			r.body_root.shake_x = sin(t * 58.0) * 7.5 * shake_env
			r.body_root.shake_y = cos(t * 47.0) * 3.5 * shake_env

			r.body_root.x = -26.0 * recoil_env
			r.body_root.y = 5.0 * recoil_env
			r.body_root.scale_x = 1.0 + 0.07 * recoil_env
			r.body_root.scale_y = 1.0 - 0.08 * recoil_env
			r.body_root.lean = -0.20 * recoil_env

			r.torso.tilt = -0.14 * recoil_env
			r.torso.twist = -0.22 * recoil_env

			r.head_pivot.tilt = -0.11 * recoil_env
			r.head_pivot.pitch_25d = -0.24 * recoil_env
			r.head_pivot.turn_25d = -0.18 * recoil_env
			r.head_pivot.offset_x = -5.0 * recoil_env

			r.eyes.blink = 0.0 if cycle < 0.72 else base_blink
			r.eyes.wide = recoil_env
			r.eyes.brow_offset = 1.0 * recoil_env
			r.eyes.look_x = 0.16 * recoil_env
			r.eyes.look_y = -0.10 * recoil_env

			r.mouth.shape = MouthShape.O_SHOCK if recoil_env > 0.25 else MouthShape.NEUTRAL
			r.mouth.open = recoil_env

			r.front_arm.shoulder_angle = lerpf(0.14, -1.55, recoil_env)
			r.front_arm.elbow_angle = lerpf(-0.20, -1.25, recoil_env)
			r.front_arm.hand_pose = HandPose.TENSE_SPLAY if recoil_env > 0.2 else HandPose.RELAXED

			r.back_arm.shoulder_angle = lerpf(-0.10, -1.35, recoil_env)
			r.back_arm.elbow_angle = lerpf(-0.16, -1.10, recoil_env)
			r.back_arm.hand_pose = HandPose.TENSE_SPLAY if recoil_env > 0.2 else HandPose.RELAXED


func _lerp_anchors(dst: RigAnchors, src: RigAnchors, alpha: float) -> void:
	dst.body_root.x = lerpf(dst.body_root.x, src.body_root.x, alpha)
	dst.body_root.y = lerpf(dst.body_root.y, src.body_root.y, alpha)
	dst.body_root.scale_x = lerpf(dst.body_root.scale_x, src.body_root.scale_x, alpha)
	dst.body_root.scale_y = lerpf(dst.body_root.scale_y, src.body_root.scale_y, alpha)
	dst.body_root.lean = lerpf(dst.body_root.lean, src.body_root.lean, alpha)
	dst.body_root.shake_x = src.body_root.shake_x
	dst.body_root.shake_y = src.body_root.shake_y

	dst.torso.offset_y = lerpf(dst.torso.offset_y, src.torso.offset_y, alpha)
	dst.torso.breath_scale_x = lerpf(dst.torso.breath_scale_x, src.torso.breath_scale_x, alpha)
	dst.torso.breath_scale_y = lerpf(dst.torso.breath_scale_y, src.torso.breath_scale_y, alpha)
	dst.torso.tilt = lerpf(dst.torso.tilt, src.torso.tilt, alpha)
	dst.torso.twist = lerpf(dst.torso.twist, src.torso.twist, alpha)

	dst.head_pivot.offset_x = lerpf(dst.head_pivot.offset_x, src.head_pivot.offset_x, alpha)
	dst.head_pivot.offset_y = lerpf(dst.head_pivot.offset_y, src.head_pivot.offset_y, alpha)
	dst.head_pivot.tilt = lerpf(dst.head_pivot.tilt, src.head_pivot.tilt, alpha)
	dst.head_pivot.turn_25d = lerpf(dst.head_pivot.turn_25d, src.head_pivot.turn_25d, alpha)
	dst.head_pivot.pitch_25d = lerpf(dst.head_pivot.pitch_25d, src.head_pivot.pitch_25d, alpha)

	var eye_a: float = minf(1.0, alpha * 2.2)
	var gaze_a: float = minf(1.0, alpha * 1.6)
	dst.eyes.blink = lerpf(dst.eyes.blink, src.eyes.blink, eye_a)
	dst.eyes.look_x = lerpf(dst.eyes.look_x, src.eyes.look_x, gaze_a)
	dst.eyes.look_y = lerpf(dst.eyes.look_y, src.eyes.look_y, gaze_a)
	dst.eyes.wide = lerpf(dst.eyes.wide, src.eyes.wide, minf(1.0, alpha * 1.8))
	dst.eyes.brow_offset = lerpf(dst.eyes.brow_offset, src.eyes.brow_offset, alpha)
	dst.eyes.squint = lerpf(dst.eyes.squint, src.eyes.squint, alpha)

	dst.mouth.shape = src.mouth.shape
	dst.mouth.open = lerpf(dst.mouth.open, src.mouth.open, minf(1.0, alpha * 1.7))

	dst.front_arm.shoulder_angle = lerpf(dst.front_arm.shoulder_angle, src.front_arm.shoulder_angle, alpha)
	dst.front_arm.elbow_angle = lerpf(dst.front_arm.elbow_angle, src.front_arm.elbow_angle, alpha)
	dst.front_arm.hand_pose = src.front_arm.hand_pose
	dst.front_arm.wave_phase = src.front_arm.wave_phase

	dst.back_arm.shoulder_angle = lerpf(dst.back_arm.shoulder_angle, src.back_arm.shoulder_angle, alpha)
	dst.back_arm.elbow_angle = lerpf(dst.back_arm.elbow_angle, src.back_arm.elbow_angle, alpha)
	dst.back_arm.hand_pose = src.back_arm.hand_pose


func _update_secondary_spring(dt: float) -> void:
	var body_x: float = _current.body_root.x + _current.body_root.shake_x * 0.4
	var body_y: float = _current.body_root.y + _current.torso.offset_y
	var head_tilt: float = _current.head_pivot.tilt + _current.body_root.lean

	var vel_body_x: float = (body_x - _prev_body_x) / dt
	var vel_body_y: float = (body_y - _prev_body_y) / dt
	var vel_rot: float = (head_tilt - _prev_head_tilt) / dt

	_prev_body_x = body_x
	_prev_body_y = body_y
	_prev_head_tilt = head_tilt

	var stiffness: float = 95.0
	var damping: float = 10.5

	var target_lag_x: float = clampf(-vel_body_x * 0.045, -36.0, 36.0)
	var target_lag_y: float = clampf(-vel_body_y * 0.055, -42.0, 42.0)
	var target_rot: float = clampf(-vel_body_x * 0.0014 - vel_rot * 0.08 - _current.body_root.lean * 0.65, -0.55, 0.55)

	var ax: float = (target_lag_x - _lag_pos_x) * stiffness - _lag_vel_x * damping
	var ay: float = (target_lag_y - _lag_pos_y) * stiffness - _lag_vel_y * damping
	var a_rot: float = (target_rot - _lag_rot) * stiffness - _lag_rot_vel * damping

	_lag_vel_x += ax * dt
	_lag_vel_y += ay * dt
	_lag_rot_vel += a_rot * dt

	_lag_pos_x += _lag_vel_x * dt
	_lag_pos_y += _lag_vel_y * dt
	_lag_rot += _lag_rot_vel * dt

	_current.secondary_lag.x = clampf(_lag_pos_x, -42.0, 42.0)
	_current.secondary_lag.y = clampf(_lag_pos_y, -46.0, 46.0)
	_current.secondary_lag.rot = clampf(_lag_rot, -0.65, 0.65)
	_current.secondary_lag.flutter = sin(global_time * 3.4) * 3.5
