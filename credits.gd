extends Control

var _level_images = [
		"res://title.png"
		]

var _res = Vector2(0,0)

func _ready():
	_resize()
	
	set_process_input(true)
	set_process(true)

func _process(delta):
	_resize()

func _resize():
	var win_size = OS.get_window_size()
	if win_size != _res:
		_res = win_size
		set_size(_res)
		get_node("TextureFrame").set_size(_res)

	

func _input(event):
	if event.is_action("ui_cancel"):
		OS.get_main_loop().quit()
	elif event.is_pressed():
		get_node("/root/global").next_scene()
