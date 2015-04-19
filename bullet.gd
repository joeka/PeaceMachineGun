extends KinematicBody

export var precision = 0.01
var player = null
var trajectory = null

var started = false

export(int) var speed = 100

func _fixed_process(delta):
	if not started:
		trajectory.set_rotation(get_rotation())
		trajectory.show()
		started = true
	else:
		var origin = get_global_transform().origin
		for mesh in trajectory.get_children():
			if mesh.get_global_transform().origin.distance_to(origin) < 0.1:
				mesh.queue_free()
		
	if is_colliding():
		var node = get_collider()
		if node == player:
			player_collision()
		else:
			print("bullet lost") #TODO: do something else
			_destroy()
	move(get_global_transform().basis[2] * delta * speed)

func player_collision():
	var b1 = get_global_transform().basis[2]
	var b2 = player.get_global_transform().basis[2]
	var dot = b1.x*b2.x + b1.z*b2.z
	if dot > 0.1 - precision:
		print("bullet caught")  #TODO: do something else
	else:
		print("hit by bullet")  #TODO: do something else
	_destroy()
func _destroy():
	if trajectory != null:
		trajectory.queue_free()
	queue_free()

func _ready():
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
	_destroy()
