extends Node

var bullet_prefab = null

func _ready():
	bullet_prefab = preload("res://bullet.scn")

func _on_Timer_timeout():
	var bullet = bullet_prefab.instance()
	bullet.set_name("Bullet")
	add_child(bullet)
	
	#var target = get_node("Target")
	#var dir = target.get_translation() - bullet.get_translation()
	
	bullet.rotate(Vector3(0,1,0), deg2rad(180))
	
