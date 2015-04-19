extends Node

var _current_scene = null
var _current_scene_id = 0
var _current_path = null

var _replay_first = []
var _replay_events = []
var _replay = false

var _time = 0

var _scenes = [
		"res://title.scn",
		"res://levels/testlevel.scn"]

func reset_replay():
	_replay_events = []
	_time = 0

func replay():
	_replay = true
	for entry in _replay_first:
		entry["node"].replay()

func register_replay( node, type, opt1=null, opt2=null ):
	if type == "player":
		_replay_first.push_back( {"node": node, "type": type})
	elif type == "animation":
		_replay_events.push_back( {"time": _time + opt2, "node": node, "type": type, "opt1": opt1} )
	else:
		_replay_events.push_back( {"time": _time, "node": node, "type": type} )

func _fixed_process( delta ):
	if _replay:
		_time -= delta
		while _replay_events.size() > 0 and _replay_events[_replay_events.size() - 1]["time"] > _time:
			var entry = _replay_events[_replay_events.size() - 1]
			if entry.size() < 4:
				entry["node"].replay() 
			elif entry.size() < 5:
				entry["node"].replay(entry["opt1"])
			else:
				entry["node"].replay(entry["opt1"], entry["opt2"])
				
			_replay_events.remove(_replay_events.size() - 1)
		if _time <= 0:
			_replay = false
			print("replay finished") #TODO do something. End event?
	else:
		_time += delta

func _ready():
	var root = get_tree().get_root()
	_current_scene = root.get_child( root.get_child_count() - 1 )
	set_process_input(true)
	set_fixed_process(true)
	reset_replay()

func _input(event):
	if event.is_action("reload_scene"):
		#reload_scene()
		replay()

func reload_scene():
	if _current_path != null:
		goto_scene( _current_path )

func goto_scene( path ):
	reset_replay()
	_current_path = path
	call_deferred( "_deferred_goto_scene", path )

func next_scene():
	var id = _current_scene_id + 1
	if _scenes.size() > id:
		goto_scene(_scenes[id])

func _deferred_goto_scene( path ):
	_current_scene.free()
	var s = ResourceLoader.load( path )
	_current_scene = s.instance()
	get_tree().get_root().add_child(_current_scene)
