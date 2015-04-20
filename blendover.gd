extends Quad

var _fade_time = 3
var _fade_mode = 0

var _mat = null

func set_fade_time( time ):
	_fade_time = time

func fade_in( time = null ):
	if time != null:
		_fade_time = time
	_fade_mode = -1
	
func fade_out( time = null ):
	if time != null:
		_fade_time = time
	_fade_mode = 1
	

func _ready():
	set_fixed_process(true)
	_mat = get_material_override ()
	if _fade_mode == 1:
		_mat.set_parameter(0, Color(1,1,1, 0))
	else:
		_mat.set_parameter(0, Color(1,1,1, 1))

func _fixed_process(delta):
	if _fade_mode == 1:
		var current = _mat.get_parameter(0)
		current.a += delta / _fade_time
		_mat.set_parameter( 0, current)
		if current.a == 0:
			_fade_mode = 0
		
