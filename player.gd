extends KinematicBody

var max_vel = 10

var mouse_sensitivity = 0.2
var yaw = 0

var g = -19.8
var vel = Vector3()
const MAX_SPEED = 8
const JUMP_SPEED = 7
#var pitch = 0
const MAX_SLOPE_ANGLE = 30
const ACCEL= 6
const DEACCEL= 10

func _fixed_process(delta):
	_keyboardInput(delta)

func _ready():
	set_process_input(true)
	set_fixed_process(true)

func _keyboardInput(delta):
	var dir = Vector3(0,0,0)
	var player_xform = get_global_transform()
	if Input.is_action_pressed("forward"):
		dir += -player_xform.basis[2]
	elif Input.is_action_pressed("backward"):
		dir += player_xform.basis[2]
	
	if Input.is_action_pressed("strafe_left"):
		dir += -player_xform.basis[0] 
	elif Input.is_action_pressed("strafe_right"):
		dir += player_xform.basis[0]

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
	
	vel.x=hvel.x;
	vel.z=hvel.z	
		
	var motion = vel*delta
	motion=move(vel*delta)

	var on_floor = false
	var original_vel = vel


	var floor_velocity=Vector3()

	var attempts=4

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

func _input(event):
	_mouseLook(event)

func _mouseLook(event):
	if event.type == InputEvent.MOUSE_MOTION or event.type == InputEvent.SCREEN_DRAG:
		yaw = fmod(yaw - event.relative_x * mouse_sensitivity, 360)
		#pitch = fmod(pitch - event.relative_y * mouse_sensitivity, 360)
		set_rotation(Vector3(0, deg2rad(yaw), 0))
		#get_node("CameraConnector").set_rotation(Vector3(deg2rad(pitch), 0, 0))

func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
