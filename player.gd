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
var is_running = false
var targeting_animation
var targeting_track_id = 0

var _time = 0
var _replay = false
var _record = []

func _fixed_process(delta):
	if _replay:
		_time -= delta
		while _record.size() > 0 and _record[_record.size() - 1]["time"] > _time:
			set_transform(_record[_record.size() - 1]["transform"])
			_record.remove(_record.size() - 1)
		if _time <= 0:
			_replay = false
			print("player replay finished") #TODO do something. End event?
	else:
		_time += delta
		_keyboardInput(delta)
		_record.push_back({ "time": _time, "transform": get_transform() })

	updateTargetAnimation(Transform())
	updateGunPosition()
	
func poseUpperArm():
	var upper_arm_bone_id = get_node("Armature/Skeleton").find_bone("UpperArm_R")
	#get_node("Armature/Skeleton").set_bone_global_pose (upper_arm_bone_id, Transform (
	
func initTargetAnimation():
	# remove old animation of player
	assert (get_node("AnimationPlayer").has_animation("Targeting"))
	targeting_animation = get_node("AnimationPlayer").get_animation("Targeting")
	var track_count = targeting_animation.get_track_count()
	print (targeting_animation.get_track_count())
	
	
	#assert (targeting_animation.get_track_count() == 1)
	print (targeting_animation.track_get_path(1))

	pass

func updateTargetAnimation(transform):
	#var res = target_animation.transform_track_insert_key (target_track_id, 0.0, Vector3(1.0, 0.0, 0.0), Quat(transform.basis), Vector3 (1.0, 1.0, 1.0))
	
	#print ("insert result = ", res, " ")
	pass

func findClosestBullet():
	pass

func replay():
	_replay = true

func _ready():
	get_node("/root/global").register_replay(self, "player")
	var b = get_global_transform().basis[2]
	
	yaw = 90 - rad2deg(atan2(b.z, b.x))
	
	set_process_input(true)
	set_fixed_process(true)
	
	initTargetAnimation()

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

	dir.y = 0
	dir = dir.normalized()

	vel.y+=delta*g
	
	var hvel = vel
	hvel.y=0	
	
	var target = dir*MAX_SPEED
	var accel
	if (dir.dot(hvel) >0):
		accel=ACCEL
	else:
		accel=DEACCEL
		
	hvel = hvel.linear_interpolate(target,accel*delta)
	
	vel.x=hvel.x
	vel.z=hvel.z
	
	if (not is_running and (vel.x * vel.x + vel.z * vel.z) > 0.1):
		is_running = true
	
	if (is_running and (vel.x * vel.x + vel.z * vel.z) < 0.1):
		is_running = false
		
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
