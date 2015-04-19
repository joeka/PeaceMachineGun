extends KinematicBody

var precision = 0.01
var player = null

var speed = 16

func _fixed_process(delta):

	if is_colliding():
		var node = get_collider()
		if node == player:
			player_collision()
		else:
			print("bullet lost") #TODO: do something else
			queue_free()
	else:
		move(get_global_transform().basis[2] * delta * speed)

func player_collision():
	var b1 = get_global_transform().basis[2]
	var b2 = player.get_global_transform().basis[2]
	var dot = b1.x*b2.x + b1.z*b2.z
	if dot > 0.1 - precision:
		print("bullet caught")  #TODO: do something else
		queue_free()

func _ready():
	player = get_node("../Player")
	if player == null:
		player = get_node("../../Player")

	set_fixed_process(true)


func _on_FreeTimer_timeout():
	queue_free()
