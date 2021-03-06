extends KinematicBody

export(float) var mouse_sensitivity = 0.2
var yaw = 0
#var pitch = 0

export(float) var g = -19.8
var vel = Vector3()
export(int) var MAX_SPEED = 8
export(int) var JUMP_SPEED = 7
export(int) var MAX_SLOPE_ANGLE = 30
export(int) var ACCEL= 6
export(int) var DEACCEL= 10
const TARGET_OUTER_RADIUS = 6.0
const TARGET_INNER_RADIUS = 4.0
const TRIGGER_DISTANCE = 0.8
const TARGET_ANGLE_DEG = 90

var is_running = false
var targeting_animation
var targeting_track_id = 0
var targeting_parent_matrices

var _time = 0
var _replay = false
var _animation_record = []
var _record = []
var closest_bullet_location = Vector3()

var _started = false
var allow_throw_gun = false
var gun_flying = false
var has_gun = true
var gun_position = Vector3()

var _start_trigger = null


var _replay_delay = 0

func pickup_gun():
	if not has_gun:
		# pick it up! do it!
		has_gun = true
		get_node("GunMesh").show()
		print ("Weapon picked up!")		

func throw_gun():
	if gun_flying:
		return

	print ("throwing gun")
	gun_flying = true
	has_gun = false

	var gun_world_transform = get_global_transform()
	gun_world_transform.origin += gun_world_transform.basis[2] * 2 - gun_world_transform.basis[0]
		
	var root = get_tree().get_root()
	var current_scene = root.get_child( root.get_child_count() -1 )
	current_scene.get_node("GunMesh").set_global_transform(gun_world_transform)
	current_scene.get_node("GunMesh").show()
	
	var credit_transform = gun_world_transform
	credit_transform.origin += credit_transform.basis[2] * 2 - credit_transform.basis[0]
	
	current_scene.get_node("Credit").set_global_transform(credit_transform)
	current_scene.get_node("Credit").show()
	
	credit_transform.origin += credit_transform.basis[2] * 1 + 4 *credit_transform.basis[0]

	current_scene.get_node("CreditThx").set_global_transform(credit_transform)
	current_scene.get_node("CreditThx").show()

			
	get_node("GunMesh").hide()
	
	pass

func _record_animation_state( animation, amount ):
	_animation_record.push_back({ "time": _time, "animation": animation, "amount": amount })

var _once = true
func _fixed_process(delta):
	if _replay:
		if _once:
			_time += _replay_delay
			_once = false
		_time -= delta
		
		# replay movement
		while _record.size() > 0 and _record[_record.size() - 1]["time"] > _time:
			set_transform(_record[_record.size() - 1]["transform"])
			_record.remove(_record.size() - 1)
		
		# replay animations
		while _animation_record.size() > 0 and _animation_record[_animation_record.size() - 1]["time"] > _time:
			var ani = _animation_record[_animation_record.size() - 1]
			get_node("AnimationTreePlayer").blend2_node_set_amount(ani["animation"], ani["amount"])
			_animation_record.remove(_animation_record.size() - 1)
		
		if _time <= 0:
			_replay = false
			_once = true
		
	else:
		_time += delta
		_keyboardInput(delta)
		_record.push_back({ "time": _time, "transform": get_transform() })

	updateTargetAnimation(Transform(), delta)
	
	if has_gun:
		updateGunPosition()
	
func poseUpperArm():
	var upper_arm_bone_id = get_node("Armature/Skeleton").find_bone("UpperArm_R")
	#get_node("Armature/Skeleton").set_bone_global_pose (upper_arm_bone_id, Transform (
	
func initTargetAnimation():
	# remove old animation of player
	assert (get_node("AnimationPlayer").has_animation("Targeting"))
	targeting_animation = get_node("AnimationPlayer").get_animation("Targeting")
	
	var track_count = targeting_animation.get_track_count()
	targeting_track_id = -1
	for i in range (track_count):
		if targeting_animation.track_get_path(i).get_property() == "UpperArm_R":
			targeting_track_id = i
			targeting_animation.track_set_interpolation_type (targeting_track_id, Animation.INTERPOLATION_NEAREST)
			break
			
	assert (targeting_track_id >= 0)

	# compute the parent matrices that are used when orienting the arm
	var skeleton = get_node("Armature/Skeleton")
	var right_shoulder_bone_id = skeleton.find_bone("UpperArm_R")
	var bone_id = right_shoulder_bone_id
	targeting_parent_matrices = Matrix3(Vector3(1.0, 0.0, 0.0), 0.0)
	while bone_id != 0:
		var rest_orientation = skeleton.get_bone_rest (bone_id).basis
		targeting_parent_matrices = rest_orientation * targeting_parent_matrices
		bone_id = skeleton.get_bone_parent(bone_id)

	pass

func resetTargetingAnimation():
#	var orientation = targeting_parent_matrices.transposed() * player_orientation.transposed() * target_orientation * Matrix3 (Vector3(1.0, 0.0, 0.0), deg2rad(-90.0)) * targeting_parent_matrices
#	targeting_animation.clear()
#	targeting_track_id = targeting_animation.add_track (Animation.TYPE_TRANSFORM)
#	targeting_animation.track_set_path (targeting_track_id, "Armature/Skeleton:UpperArm_R")
#	targeting_animation.transform_track_insert_key (targeting_track_id, 0.0, Vector3(0.0, 0.0, 0.0), Quat(orientation), Vector3 (1.0, 1.0, 1.0))
#	
#	var root_track_id = targeting_animation.add_track (Animation.TYPE_TRANSFORM)
#	targeting_animation.track_set_path (root_track_id, "Armature/Skeleton:Root")
#	targeting_animation.transform_track_insert_key (targeting_track_id, 0.0, Vector3(0.0, 0.0, 0.0), Quat(), Vector3 (1.0, 1.0, 1.0))	


	pass

func updateTargetAnimation(transform, delta):
	var bullet_location = findClosestBulletLocation()
	
	if bullet_location == null:
		var targeting_weighting = get_node("AnimationTreePlayer").blend2_node_get_amount("targeting")
		if targeting_weighting > 0:
			_record_animation_state("targeting", targeting_weighting)
			get_node("AnimationTreePlayer").blend2_node_set_amount("targeting", max(0, targeting_weighting - delta))
		return
	
	# find the right shoulder
	var skeleton = get_node("Armature/Skeleton")
	var right_shoulder_bone_id = skeleton.find_bone("UpperArm_R")
	var right_shoulder_transform = skeleton.get_bone_global_pose (right_shoulder_bone_id)
	var right_shoulder_bone_transform = skeleton.get_bone_global_pose (right_shoulder_bone_id)

	var shoulder_location = right_shoulder_transform.origin + get_global_transform().origin
	var player_position = get_global_transform().origin
	var direction = (shoulder_location - bullet_location).normalized()
	
	
#	var target_orientation = Matrix3 (Vector3(0.0, 1.0, 0.0), angle)
#	print ("atan: ", target_orientation, " direction = ", direction.normalized())
	
	var up = Vector3 (0.0, 1.0, 0.0)
	var side = up.cross(-direction)
	var target_orientation = Matrix3(side, up, -direction)

	var player_orientation = get_global_transform().basis
	var rel_direction = player_orientation.transposed() * direction
	var angle = atan2 (rel_direction.x, -rel_direction.z)
	
#	var orientation = targeting_parent_matrices.transposed() * player_orientation.transposed() * target_orientation * Matrix3 (Vector3(1.0, 0.0, 0.0), deg2rad(-90.0)) * targeting_parent_matrices
#	resetTargetingAnimation()
#	targeting_track_id = targeting_animation.add_track (Animation.TYPE_TRANSFORM)
#	targeting_animation.track_set_path (targeting_track_id, "Armature/Skeleton:UpperArm_R")
#	targeting_animation.transform_track_insert_key (targeting_track_id, 0.0, Vector3(0.0, 0.0, 0.0), Quat(orientation), Vector3 (1.0, 1.0, 1.0))

	# compute weighting of the targeting
	var distance = (bullet_location - shoulder_location).length()
	var targeting_weighting = 0.0
	if distance < TARGET_OUTER_RADIUS:
		if distance < TARGET_INNER_RADIUS:
			targeting_weighting = 1.0
		else:
			targeting_weighting = (TARGET_OUTER_RADIUS - distance)/ (TARGET_OUTER_RADIUS - TARGET_INNER_RADIUS) 
		
		# angle targeting: depending on the angle we lift the arm
		var angle_targeting = max (0.0, (TARGET_ANGLE_DEG * 0.5 - rad2deg(abs(angle))) / TARGET_ANGLE_DEG) * 2.0
		targeting_weighting = targeting_weighting * angle_targeting

		_record_animation_state("targeting", get_node("AnimationTreePlayer").blend2_node_get_amount("targeting"))
		get_node("AnimationTreePlayer").blend2_node_set_amount("targeting", targeting_weighting)

func findClosestBulletLocation():
	var bullets = get_node("/root/global").get_bullets()
	if bullets.size() > 0:
		var min_dist = 9999
		var min_origin = null
		for bullet in bullets:
			if bullet != null and (not bullet._disabled or bullet._replay) and bullet.started:
				var d = get_global_transform().origin.distance_to(bullet.get_global_transform().origin)
				if d < min_dist:
					min_dist = d
					min_origin = bullet.get_global_transform().origin
		return min_origin
	else:
		return null

func replay( delay = 0 ):
	_replay_delay = delay
	_replay = true

func _ready():
	var b = get_global_transform().basis[2]
	
	yaw = 90 - rad2deg(atan2(b.z, b.x))
	
	set_process_input(true)
	set_fixed_process(true)
	
#	get_node("AnimationTreePlayer").set_active(false)
	
	initTargetAnimation()
	
	_start_trigger = get_node("../StartTrigger")
	if _start_trigger == null:
		_start_trigger = get_node("../../StartTrigger")

func start():
	if not _started:
		_started = true
		# Order of start and register_replay is important
		get_node("/root/global").start()
		get_node("/root/global").register_replay(self, "player")

func _keyboardInput(delta):
	var dir = Vector3(0,0,0)
	var player_xform = get_global_transform()
	if Input.is_action_pressed("forward"):
		dir += player_xform.basis[2]
	elif Input.is_action_pressed("backward"):
		dir += -player_xform.basis[2]
	
	if Input.is_action_pressed("strafe_left"):
		dir += player_xform.basis[0] 
	elif Input.is_action_pressed("strafe_right"):
		dir += -player_xform.basis[0]
		
	if Input.is_action_pressed("throw_weapon") and allow_throw_gun:
		throw_gun()

	dir.y = 0
	dir = dir.normalized()
	
	if not _started:
		if _start_trigger == null and dir.length() != 0:
			start()
		elif _start_trigger != null:
			var origin = get_global_transform().origin
			var trigger = _start_trigger.get_global_transform().origin
			if origin.distance_to( trigger ) < TRIGGER_DISTANCE:
				pickup_gun()
				start()
	
	vel.y+=delta*g
	
	var hvel = vel
	hvel.y=0	
	
	var target = dir*MAX_SPEED
	var accel
	if (dir.dot(hvel) >0):
		accel=ACCEL
		get_node("AnimationTreePlayer").timescale_node_set_scale("scale",1.0)			
	else:
		accel=DEACCEL
		get_node("AnimationTreePlayer").timescale_node_set_scale("scale",-1.0)					
		
	hvel = hvel.linear_interpolate(target,accel*delta)
	
	vel.x=hvel.x
	vel.z=hvel.z
	
	if (not is_running and (vel.x * vel.x + vel.z * vel.z) > 0.1):
		is_running = true
	
	if (is_running and (vel.x * vel.x + vel.z * vel.z) < 0.1):
		is_running = false
	
	_record_animation_state("run", get_node("AnimationTreePlayer").blend2_node_get_amount("run"))
	if (is_running):
		
		get_node("AnimationTreePlayer").blend2_node_set_amount("run",max(vel.length()/MAX_SPEED,1.0))
	else:
		get_node("AnimationTreePlayer").blend2_node_set_amount("run",0.0)
	
	#get_node("AnimationPlayer").stop_all()
	#get_node("AnimationPlayer").play("Targeting")
		
	var motion = vel*delta
	motion=move(vel*delta)

	var on_floor = false
	var original_vel = vel

	var floor_velocity=Vector3()

	var attempts=4

	if is_colliding():
		var node = get_collider()
		if node.get_name() == "Bullet":
			node.player_collision()
		else:
			while(is_colliding() and attempts):
				var n=get_collision_normal()
		
				if ( rad2deg(acos(n.dot( Vector3(0,1,0)))) < MAX_SLOPE_ANGLE ):
						#if angle to the "up" vectors is < angle tolerance
						#char is on floor
						floor_velocity=get_collider_velocity()
						on_floor=true
					
				motion = n.slide(motion)
				vel = n.slide(vel)
				if (original_vel.dot(vel) > 0):
					#do not allow to slide towads the opposite direction we were coming from
					motion=move(motion)
					if (motion.length()<0.001):
						break
				attempts-=1
	
	if (on_floor and floor_velocity!=Vector3()):
		move(floor_velocity*delta)
	
	if (on_floor and Input.is_action_pressed("jump")):
		vel.y=JUMP_SPEED

func updateGunPosition ():
	var skeleton = get_node("Armature/Skeleton")
	var right_hand_bone_id = skeleton.find_bone("Hand_R")
	var right_hand_transform = skeleton.get_bone_global_pose (right_hand_bone_id)
	gun_position = right_hand_transform.basis
	get_node("GunMesh").set_transform(right_hand_transform.rotated(Vector3(0.0, 0.0, 0.0), 180))

func _input(event):
	_mouseLook(event)

func _mouseLook(event):
	if not _replay and (event.type == InputEvent.MOUSE_MOTION or event.type == InputEvent.SCREEN_DRAG):
		yaw = fmod(yaw - event.relative_x * mouse_sensitivity, 360)
		#pitch = fmod(pitch - event.relative_y * mouse_sensitivity, 360)
		set_rotation(Vector3(0, deg2rad(yaw) , 0))
		#get_node("CameraConnector").set_rotation(Vector3(deg2rad(pitch), 0, 0))

func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
