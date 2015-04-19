extends Node

var current_scene = null
var current_path = "levels/testlevel.scn"

var _replay_first = []
var _replay_events = []
var _replay = false

var _time = 0

func reset_replay():
	_replay_events = []
	_time = 0

func replay():
	_replay = true
	for entry in _replay_first:
		entry["node"].replay()

func register_replay( node, type ):
	if type == "player":
		_replay_first.push_back( {"node": node, "type": type})
	else:
		_replay_events.push_back( {"time": _time, "node": node, "type": type} )

func _fixed_process( delta ):
	if _replay:
		_time -= delta
		while _replay_events.size() > 0 and _replay_events[_replay_events.size() - 1]["time"] > _time:
			_replay_events[_replay_events.size() - 1]["node"].replay()
			_replay_events.remove(_replay_events.size() - 1)
		if _time <= 0:
			_replay = false
			print("replay finished") #TODO do something. End event?
	else:
		_time += delta

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child( root.get_child_count() - 1 )
	set_process_input(true)
	set_fixed_process(true)

func _input(event):
	if event.is_action("reload_scene"):
		#reload_scene()
		replay()

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
	reset_replay()
