extends Spatial

func _ready():
	get_node("Player/Body").allow_throw_gun = true
	get_node("GunMesh").hide()
	get_node("Credit").hide()
	get_node("CreditThx").hide()
