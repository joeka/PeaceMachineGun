extends Spatial

var bullet_prefab = null

func _ready():
	bullet_prefab = preload("res://bullet.scn")

func _on_Timer_timeout():
	var bullet = bullet_prefab.instance()
	bullet.set_name("Bullet")
	add_child(bullet)
	
	var target = get_node("Target")
	
	var scale = bullet.get_scale()
	bullet.look_at(target.get_global_transform().origin, Vector3(0,1,0))
	bullet.rotate(Vector3(0,1,0), deg2rad(180))
	bullet.set_scale(scale)
