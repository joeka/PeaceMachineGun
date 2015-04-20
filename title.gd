extends Spatial

func _ready():
	get_node("Player/Body").has_gun = false
	get_node("Player/Body/GunMesh").hide()
	
	set_fixed_process(true)
	
func _fixed_process(delta):
	if get_node("Player/Body").has_gun:
		get_node("StartTrigger/GunMesh").hide()
	

