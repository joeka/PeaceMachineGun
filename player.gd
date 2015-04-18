extends KinematicBody

var max_vel = 10

var mouse_sensitivity = 0.2
var yaw = 0


func _process(delta):
	_keyboardInput(delta)

func _ready():
	set_process(true)
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
	if dir.length() != 0:
		translate(dir * delta * max_vel)

func _input(event):
	_mouseLook(event)

func _mouseLook(event):
	if event.type == InputEvent.MOUSE_MOTION or event.type == InputEvent.SCREEN_DRAG:
		yaw = fmod(yaw - event.relative_x * mouse_sensitivity, 360)
		set_rotation(Vector3(0, deg2rad(yaw), 0))

func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
