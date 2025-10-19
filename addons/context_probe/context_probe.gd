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
	if animated_params.size() > 0 and animated_params[0]:
		params = animated_params[0].params
	
func _process(delta: float) -> void:
	time += delta

	if animated_params.size() > _cur_key_params_idx + 1:
		var cur = animated_params[_cur_key_params_idx]
		var next = animated_params[_cur_key_params_idx+1]
		
		if cur and next:
			if next.key <= time:
				_cur_key_params_idx += 1

			var weight = 1.0 - (next.key - time) / (next.key - cur.key)
			var next_params = next.params
			params = cur.params.interpolate(next_params, weight)
			print(params.moisture)
			# Not showing yet
