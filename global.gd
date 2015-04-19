extends Node

var current_scene = null
var current_path = "levels/testlevel.scn"

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child( root.get_child_count() - 1 )
	set_process_input(true)

func _input(event):
	if event.is_action("reload_scene"):
		reload_scene()

func reload_scene():
	if current_path != null:
		goto_scene( current_path )

func goto_scene( path ):
	current_path = path
	call_deferred( "_deferred_goto_scene", path )

func _deferred_goto_scene( path ):
	current_scene.free()
	var s = ResourceLoader.load( path )
	current_scene = s.instance()
	get_tree().get_root().add_child(current_scene)
