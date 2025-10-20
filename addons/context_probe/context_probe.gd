# Probe with a collision shape and ContextParams.
# ContextSamplers can sample the parameters of probes that they are colliding
# with.

@icon("res://addons/context_probe/probe_icon.svg")
extends Area3D
class_name ContextProbe

@export var params := ContextParams.new()
	
@export var animated_params : Array[KeyParams]
var _cur_key_params_idx: int = 0

# Used to animate between different param values over time
var time = 0.0

func _ready() -> void:
	add_to_group("context_probes")
	monitoring = true
	monitorable = true
	
func _process(delta: float) -> void:
	time += delta

	if animated_params.size() > _cur_key_params_idx + 1:
		var cur = animated_params[_cur_key_params_idx]
		var next = animated_params[_cur_key_params_idx+1]
		test()
		
		if cur and next:
			if next.key <= time:
				_cur_key_params_idx += 1

			var weight = (time - cur.key) / (next.key - cur.key)
			var next_params = next.params
			cur.params.interpolate(next_params, weight, params)

func test() -> void:
	var intervals = [0, 	10, 	20, 	30, 	40, 	45]
	var targets = 	[0.5, 	1.0, 	0.5, 	0.5, 	1.0, 	1.0]
	var expected = 	[0.0, 	5.0, 	15.0, 	20.0, 	25.0, 	30.0]
	
	var t = 44.0
	var v = 0.0

	
	var last_i = 0
	for i in len(intervals):
		var interv = intervals[i]
		if t > intervals[i] and i >= 1:
			v += (intervals[i]-intervals[i-1]) * targets[i-1]
			last_i = i
	v += (t - intervals[last_i]) * targets[last_i]
	
	
	print(v)
