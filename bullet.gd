extends KinematicBody

export var precision = 0.01
var player = null
var global = null
var trajectory = null

var started = false
var _disabled = false
var _start_pos = null
var _replay = false

export(int) var speed = 100

func _fixed_process(delta):
	if not started:
		trajectory.set_rotation(get_rotation())
		trajectory.show()
		_start_pos = get_global_transform().origin
		started = true
	
	if _replay:
		var origin = get_global_transform().origin
		for mesh in trajectory.get_children():
			var d = mesh.get_global_transform().origin.distance_to(origin)
			if d < 0.1:
				mesh.show()
			elif d > 3:
				mesh.hide()
		if origin.distance_to(_start_pos) < 0.1:
			_destroy()
		
		move(get_global_transform().basis[2] * delta * speed * -1)
	else:
		var origin = get_global_transform().origin
		for mesh in trajectory.get_children():
			if mesh.get_global_transform().origin.distance_to(origin) < 0.1:
				mesh.hide()
			
		if is_colliding():
			var node = get_collider()
			if node == player:
				player_collision()
			else:
				print("bullet lost") #TODO: do something else
				disable()
		move(get_global_transform().basis[2] * delta * speed)

func player_collision():
	if not _disabled:
		var b1 = get_global_transform().basis[2]
		var b2 = player.get_global_transform().basis[2]
		var dot = b1.x*b2.x + b1.z*b2.z
		if dot > 0.1 - precision:
			print("bullet caught")  #TODO: do something else
		else:
			print("hit by bullet")  #TODO: do something else
		disable()

func replay():
	_replay = true
	trajectory.show()
	show()
	set_fixed_process(true)

func disable():
	if not _disabled:
		global.register_replay(self, "bullet")
		_disabled = true
		if trajectory != null:
			trajectory.hide()
		hide()
		set_fixed_process(false)
		set_collide_with_kinematic_bodies(false)
		set_layer_mask(0)

func _destroy():
	if trajectory != null:
		trajectory.queue_free()
	queue_free()

func _ready():
	global = get_node("/root/global")
	player = get_node("../Player")
	if player == null:
		player = get_node("../../Player")
	set_fixed_process(true)
	trajectory = get_node("Trajectory")
	trajectory.hide()
	remove_child(trajectory)
	trajectory.set_transform(get_transform())
	get_parent().add_child(trajectory)


func _on_FreeTimer_timeout():
	disable()
