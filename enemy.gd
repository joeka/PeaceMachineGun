extends Spatial

export (String, "Frau_1", "Frau_2", "Mann_1", "Mann_2", "Mann_3", "Mann_4", "Mann_5", "Kind_1", "Kind_2", "Kind_2", "Kind_3", "Kind_4", "Kind_5", "Kind_6", "Kind_7", "Kind_8", "Kind_9") var EnemyType

func _ready():
	set_fixed_process(true)

	var revive_timer = get_node("ReviveTimer")
	if revive_timer != null:
		revive_timer.connect("timeout", self, "_on_revive_start")
	var bullet_timer = get_node("BulletTimer")
	if bullet_timer != null:
		bullet_timer.connect("timeout", self, "_bullet_impact")
	
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

func _fixed_process(delta):
	var animation_pos = get_node("Model/AnimationPlayer").get_current_animation_pos()
	var animation_length = get_node("Model/AnimationPlayer").get_current_animation_length()
	var blood_scaling = max (0.0, (animation_pos - animation_length * 0.5) / (animation_length - animation_length * 0.5))
	get_node("Model/BloodSpot").set_scale(Vector3 (blood_scaling, blood_scaling, blood_scaling))

func start():
	var timer = get_node("ReviveTimer")
	if timer != null:
		timer.start()

func replay( animation ):
	get_node("Model/AnimationPlayer").play(animation, -1, 1, false)

func _on_revive_start():
	var global = get_node("/root/global")
	get_node("Model/SpatialSamplePlayer").play(EnemyType + "_r")
	global.register_sound(get_node("Model/SpatialSamplePlayer"), EnemyType + "_n")
	
	global.register_replay(self, "animation", "Death-cycle", \
			get_node("Model/AnimationPlayer").get_current_animation_length())
	get_node("Model/AnimationPlayer").play("Death-cycle", -1, -1, true)
	
	get_node("BulletTimer").start()

func _bullet_impact():
	get_node("Bullet").start()
