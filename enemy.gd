extends Spatial

func _ready():
	var timer = get_node("Timer")
	if timer != null:
		timer.connect("timeout", self, "_on_revive_start")
	
	var ani = get_node("Model/AnimationPlayer")
	ani.play("Death-cycle", -1, 1, false)
	var l = ani.get_animation("Death-cycle").get_length()
	ani.seek(l, false)
	ani.get_animation("Death-cycle").set_loop(false)
	
	var bullet_prefab = preload("res://bullet.scn")
	var bullet = bullet_prefab.instance()
	bullet.set_name("Bullet")
	add_child(bullet)
	
	var target = get_node("Target")
	
	var scale = bullet.get_scale()
	bullet.look_at(target.get_global_transform().origin, Vector3(0,1,0))
	bullet.rotate(Vector3(0,1,0), deg2rad(180))
	bullet.set_scale(scale)
	get_node("/root/global").register_bullet( bullet )
	get_node("/root/global").register_enemy( self )

func start():
	var timer = get_node("Timer")
	if timer != null:
		timer.start()

func replay( animation ):
	get_node("Model/AnimationPlayer").play(animation, -1, 1, false)

func _on_revive_start():
	get_node("Model/SpatialSamplePlayer").play("schrei_1")
	get_node("Model/AnimationPlayer").play("Death-cycle", -1, -1, true)
	
	get_node("/root/global").register_replay(self, "animation", "Death-cycle", \
			get_node("Model/AnimationPlayer").get_current_animation_length())
	
	get_node("Bullet").start()
	
	
